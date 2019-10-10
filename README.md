# rust-docker-skeleton

Minimalist docker image based on the empty image scratch

* Cache dependencies
* Based on scratch
* OpenSSL static library

To build:

    bin/build
    docker run --rm hello-rust

# Resources
* https://www.fpcomplete.com/blog/2018/07/deploying-rust-with-docker-and-kubernetes
* https://www.musl-libc.org/doc/1.0.0/manual.html
* https://hub.docker.com/r/ekidd/rust-musl-builder/dockerfile
* https://github.com/emk/rust-musl-builder
