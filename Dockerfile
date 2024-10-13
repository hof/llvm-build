FROM debian:bookworm-slim as builder

ARG VERSION=19.1.1
ARG BUILD_TYPE=Release

RUN apt-get clean && apt-get update && apt-get install -y \
    git cmake ninja-build clang-16 clang++-16 libc++-16-dev python3 lld zlib1g-dev

WORKDIR /build

RUN git clone -b llvmorg-${VERSION} --single-branch --depth 1 https://github.com/llvm/llvm-project.git

RUN cd llvm-project && cmake -S llvm -B build -G Ninja \
    -DCMAKE_C_COMPILER=clang-16 \
    -DCMAKE_CXX_COMPILER=clang++-16 \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lldb;lld;polly" \
    -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;compiler-rt" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_ENABLE_LLVM_LIBC=ON

RUN cd llvm-project && cmake --build build --target install

FROM debian:bookworm-slim

RUN apt-get clean && apt-get update && apt-get install -y \
    git ninja-build wget cmake libncurses6

COPY --from=builder /usr/local /usr/local

ENV CC=clang
ENV CXX=clang++
ENV LDFLAGS="-fuse-ld=lld"
ENV CMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld"
ENV CMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld"
ENV CMAKE_MODULE_LINKER_FLAGS="-fuse-ld=lld"