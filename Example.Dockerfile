#-----------------------------
# Compiling image
#-----------------------------
FROM jsonxr/rust-onbuild as compile

#-----------------------------
# Create deployment image
#-----------------------------
FROM scratch
# Required by OpenSSL
COPY --from=compile /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# Copy App binaries
COPY --from=compile /home/rust/target/x86_64-unknown-linux-musl/release/myapp /myapp
# Run as the rust user 1000
USER 1000
CMD ["/myapp"]

# Label the image last so we can change metadata easily
LABEL \
  org.opencontainers.image.authors="jsonxr <jsonxr@gmail.com>" \
  org.opencontainers.image.vendor="jsonxr <jsonxr@gmail.com>" \
  org.opencontainers.image.title="docker-hello-rust" \
  org.opencontainers.image.description="Example Dockerfile for building minimal rust binary on scratch" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/jsonxr/docker-rust-onbuild" \
  org.opencontainers.image.documentation="https://github.com/jsonxr/docker-rust-onbuild" \
  org.opencontainers.image.source="https://github.com/jsonxr/docker-rust-onbuild" \
  org.opencontainers.image.version=$BUILD_VERSION \
  org.opencontainers.image.revision=$BUILD_REF \
  org.opencontainers.image.licenses="MIT"
