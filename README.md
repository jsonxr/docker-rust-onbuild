# jsonxr/rust-onbuild

Minimalist Rust Docker image based on the empty image scratch.  It does this by statically compiling the rust binaries with all the dependencies required to run.

* Creates a release based on scratch
* Open Container Initiative Labels
* Cache dependencies for faster src compiles
* Static libraries included
  * OpenSSL (v1.1.1d) - https://www.openssl.org/
  * zlib (v1.2.11) - https://www.zlib.net/
  * libpg (v12.0) - https://www.postgresql.org/
  * sqlite (v3.30.1) - https://sqlite.org

If you want to use different versions of these libraries, you are probably better off to simply take the Dockerfile and modify it with the exact versions of libaries you want and tag it as your own.  You can use docker build args to specify exact versions, but I have not testd this feature.

To build:

    bin/build
    docker build -f Example.Dockerfile -t hello-rust .

To release:

    bin/build --release

# Warning

* In order to use other libraries that require a static library, you will need to compile these yourself in the Docker image.
* https://github.com/openssl/openssl/issues/7207 - Open issue as of 2019-10-11 that prevents OpenSSL1.1 from compiling. Workaround implemented and documented in Dockerfile

# Resources

This image is based on https://github.com/emk/rust-musl-builder.

Improvements:
* Cache the compiled dependencies
* ONBUILD instructions for simpler Dockerfiles
* Allows the creation of an actual docker image for deployment

* https://github.com/opencontainers/image-spec/blob/master/annotations.md
* https://www.musl-libc.org/
* https://www.fpcomplete.com/blog/2018/07/deploying-rust-with-docker-and-kubernetes
* http://whitfin.io/speeding-up-rust-docker-builds/