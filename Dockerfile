FROM rust:1.38 as compile

#-----------------------------------------------------------------------------
# Enable musl
#-----------------------------------------------------------------------------
# Upgrade container to latest and greatest security fixes
# Install musl
RUN \
  apt-get -y update && \
  apt-get -y upgrade && \
  apt-get -y install musl-tools &&\
  rustup target add x86_64-unknown-linux-musl && \
  apt-get clean

ENV \
  CC=musl-gcc \
  PREFIX=/usr/local

#-----------------------------------------------------------------------------
# OpenSSL static library
#-----------------------------------------------------------------------------
#ARG SSL_VER=1.0.2j
ARG SSL_VER=1.1.1d
ENV SSL_VER=${SSL_VER}
RUN echo " Building OpenSSL ${SSL_VER}" &&\
  cd /usr/local &&\
  curl -sL http://www.openssl.org/source/openssl-$SSL_VER.tar.gz | tar xz

#-----------------------------
# BEGIN_FIX: OpenSSL1.1.1 issue
#
# https://github.com/openssl/openssl/issues/7207
# 
# Linked missing kernel headers to musl directory. I'm sure this is bad, would be
# better to use musl kernel headers but I barely understand musl.
#
RUN \
  echo "Fixing musl build issues with OpenSSL 1.1" &&\
  ln -s /usr/include/linux /usr/include/x86_64-linux-musl/linux &&\
  ln -s /usr/include/x86_64-linux-gnu/asm /usr/include/x86_64-linux-musl/asm &&\
  ln -s /usr/include/asm-generic /usr/include/x86_64-linux-musl/asm-generic
#
# END_FIX: OpenSSL1.1.1 issue
#-----------------------------
RUN \
  cd "/usr/local/openssl-$SSL_VER" &&\
  ./Configure no-shared --prefix=$PREFIX --openssldir=$PREFIX/ssl no-zlib linux-x86_64 -fPIC &&\
  make -j$(nproc) &&\
  make install_sw
ENV \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  OPENSSL_DIR=$PREFIX \
  OPENSSL_STATIC=1 \
  PKG_CONFIG_ALLOW_CROSS=1

#-----------------------------------------------------------------------------
# zlib static library
#-----------------------------------------------------------------------------
ARG ZLIB_VERSION=1.2.11
ENV ZLIB_VERSION=${ZLIB_VERSION}
RUN echo " Building zlib" &&\
  cd /usr/local &&\
  curl -sL http://zlib.net/zlib-$ZLIB_VERSION.tar.gz | tar xz
RUN \
  cd "/usr/local/zlib-$ZLIB_VERSION" &&\
  ./configure --static --prefix=$PREFIX &&\
  make && make install

#-----------------------------------------------------------------------------
# libpg static library for postgres
#-----------------------------------------------------------------------------
#ARG POSTGRESQL_VERSION=11.5
ARG POSTGRESQL_VERSION=12.0
ENV POSTGRESQL_VERSION=${POSTGRESQL_VERSION}
RUN echo " Building libpq ${POSTGRESQL_VERSION}" &&\
  cd /usr/local &&\
  curl -sL https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/postgresql-$POSTGRESQL_VERSION.tar.gz | tar xz
RUN \
  cd "/usr/local/postgresql-$POSTGRESQL_VERSION" &&\
  CPPFLAGS=-I/usr/local/include LDFLAGS=-L/usr/local/lib ./configure --with-openssl --without-readline --prefix=$PREFIX &&\
  cd src/interfaces/libpq && make all-static-lib && make install-lib-static &&\
  cd ../../bin/pg_config && make && make install


#-----------------------------------------------------------------------------
# libpg static library for postgres
#-----------------------------------------------------------------------------
#ARG SQLITE_VERSION=3.30.1
#ENV SQLITE_VERSION=${SQLITE_VERSION}
#RUN apt-get install -y libsqlite-dev
RUN apt-get install -y libsqlite3-dev

#
# Getting a build error when I try to make this from source
#
# RUN echo " Building sqlite ${SQLITE_VERSION}" &&\
#   cd /usr/local &&\
#   apt-get install -y tcl-dev libreadline-dev &&\
#   curl -sL https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=version-$SQLITE_VERSION | tar xz &&\
#   mv sqlite sqlite-${SQLITE_VERSION}
# RUN \
#   cd "/usr/local/sqlite-${SQLITE_VERSION}" &&\
#   ./configure --prefix=$PREFIX
# RUN \
#   cd "/usr/local/sqlite-${SQLITE_VERSION}" &&\
#   make

#-----------------------------------------------------------------------------
# Rust user, and update system
#-----------------------------------------------------------------------------
RUN useradd rust --user-group --create-home --shell /bin/bash
# Build arguments
ARG BUILD_VERSION=Unknown
ARG BUILD_REF=Unknown
ARG BUILD_DATE=Unknown
RUN \
  apt-get update &&\ 
  apt-get upgrade &&\
  apt-get clean
USER rust
WORKDIR /home/rust

# Base Image update
LABEL \
  org.opencontainers.image.authors="jsonxr <jsonxr@gmail.com>" \
  org.opencontainers.image.vendor="jsonxr <jsonxr@gmail.com>" \
  org.opencontainers.image.title="jsonxr/rust-onbuild" \
  org.opencontainers.image.description="Image built on Rust 1.38 with static OpenSSL and x86_64-unknown-linux-musl target" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/jsonxr/docker-rust-onbuild" \
  org.opencontainers.image.documentation="https://github.com/jsonxr/docker-rust-onbuild" \
  org.opencontainers.image.source="https://github.com/jsonxr/docker-rust-onbuild" \
  org.opencontainers.image.version=$BUILD_VERSION \
  org.opencontainers.image.revision=$BUILD_REF \
  org.opencontainers.image.licenses="MIT"

#-----------------------------------------------------------------------------
# ONBUILD instructions
#-----------------------------------------------------------------------------

# Cache dependencies
#-----------------------------
ONBUILD COPY --chown=rust:rust Cargo.lock Cargo.toml ./
ONBUILD RUN \
  mkdir src &&\
  echo "fn main() {print!(\"Error in build\n\");}" > src/main.rs &&\
  cargo build --target x86_64-unknown-linux-musl --release

# Build source
#-----------------------------
ONBUILD COPY --chown=rust:rust ./src ./src
ONBUILD RUN \
  touch src/main.rs &&\
  cargo build --target x86_64-unknown-linux-musl --release
