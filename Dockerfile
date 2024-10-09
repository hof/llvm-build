FROM debian:bookworm-slim as builder

ARG VERSION=19.1.1
ARG BUILD_TYPE=Release

RUN apt-get clean && apt-get update && apt-get install -y \
    git cmake ninja-build clang-16 clang++-16 libc++-16-dev python3 lld zlib1g-dev

WORKDIR /build

RUN git clone -b llvmorg-${VERSION} --single-branch --depth 1 https://github.com/llvm/llvm-project.git

RUN cd llvm-project && cmake -S llvm -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lldb;lld;polly" \
    -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;compiler-rt" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_ENABLE_LIBCXX=ON \
    -DLLVM_ENABLE_LLVM_LIBC=ON

RUN cd llvm-project && cmake --build build --target install

FROM debian:bookworm-slim

ARG CMAKE_VERSION=3.30.5

RUN apt-get clean && apt-get update && apt-get install -y \
    git ninja-build

COPY --from=builder /usr/local /usr/local

RUN wget -q -O cmake-linux.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh
RUN chmod +x cmake-linux.sh && ./cmake-linux.sh -- --skip-license --prefix=/usr/local && rm cmake-linux.sh
