FROM debian:bookworm-slim as builder

ARG VERSION=18.1.3
ARG BUILD_TYPE=Release

RUN apt-get clean && apt-get update && apt-get install -y \
    git cmake ninja-build g++ gcc python3 lld zlib1g-dev

WORKDIR /build

RUN git clone -b llvmorg-${VERSION} --single-branch --depth 1 https://github.com/llvm/llvm-project.git

RUN cd llvm-project && cmake -S llvm -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lldb;lld;polly" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_USE_LINKER=lld

RUN cd llvm-project && cmake --build build --target install

FROM debian:bookworm-slim

RUN apt-get clean && apt-get update && apt-get install -y \
    git cmake ninja-build

COPY --from=builder /usr/local /usr/local
