FROM rust:1.38 as compile

LABEL Author="jsonxr <jsonxr@gmail.com>"

RUN apt-get -y update &&\
  apt-get -y install \
  curl \
  g++ \
  libssl-dev \
  pkg-config \
  musl-tools \
  ca-certificates \
  libssl-dev
RUN rustup target add x86_64-unknown-linux-musl
#RUN mkdir source && mkdir .cargo && echo "[target.x86_64-unknown-linux-musl]\n" > .cargo/config

#-----------------------------------------------------------
# OpenSSL static library
#-----------------------------------------------------------
ENV SSL_VER 1.0.2j
ENV CC musl-gcc
ENV PREFIX /usr/local
ENV PATH /usr/local/bin:$PATH
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
RUN echo "Building OpenSSL ${SSL_VER}" && curl -sL http://www.openssl.org/source/openssl-$SSL_VER.tar.gz | tar xz \
  &&  cd openssl-$SSL_VER \
  &&  ./Configure no-shared --prefix=$PREFIX --openssldir=$PREFIX/ssl no-zlib linux-x86_64 -fPIC \
  &&  make -j$(nproc) && make install && cd .. && rm -rf openssl-$SSL_VER
ENV SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_DIR /etc/ssl/certs
ENV OPENSSL_LIB_DIR $PREFIX/lib
ENV OPENSSL_INCLUDE_DIR $PREFIX/include
ENV OPENSSL_DIR $PREFIX
ENV OPENSSL_STATIC 1
ENV PKG_CONFIG_ALLOW_CROSS 1

WORKDIR /usr/src/myapp
RUN mkdir src
RUN echo "fn main() {print!(\"Error in build\");} // base file" > src/main.rs
COPY Cargo.lock Cargo.toml ./
RUN cargo build --target x86_64-unknown-linux-musl --release


#-----------------------------------------------------------
# Create our minimal RUST image
#-----------------------------------------------------------
COPY src ./src
RUN touch src/main.rs
RUN cargo build --target x86_64-unknown-linux-musl --release

#-----------------------------------------------------------
# Create our minimal RUST image
#-----------------------------------------------------------
FROM scratch
WORKDIR /usr/src/myapp
COPY --from=compile /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=compile /usr/src/myapp/target/x86_64-unknown-linux-musl/release/myapp /usr/src/myapp/myapp
#USER 1000
CMD ["./myapp"]

