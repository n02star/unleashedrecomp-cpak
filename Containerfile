FROM ghcr.io/containerpak/mesa-sdk:main AS builder

WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

ARG ASSETS_URL

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends build-essential git autoconf \
    automake libtool zip unzip tar ca-certificates lld libc++abi-dev llvm-dev \
    pkg-config curl cmake ninja-build clang clang-tools libgtk-3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --recurse-submodules https://github.com/hedge-dev/UnleashedRecomp.git .

# Assets
ADD ${ASSETS_URL}/default.xex ./UnleashedRecompLib/private/default.xex
ADD ${ASSETS_URL}/default.xexp ./UnleashedRecompLib/private/default.xexp
ADD ${ASSETS_URL}/shader.ar ./UnleashedRecompLib/private/shader.ar

RUN cmake . --preset linux-release -DSDL2MIXER_VORBIS=VORBISFILE \
        -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache \
        -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache && \
    cmake --build ./out/build/linux-release --target UnleashedRecomp

FROM ghcr.io/containerpak/mesa:main

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends

COPY --from=builder /src/out/build/linux-release/UnleashedRecomp/* /usr/bin/UnleashedRecomp
COPY ./io.github.hedge_dev.unleashedrecomp.desktop /usr/share/applications/io.github.hedge_dev.unleashedrecomp.desktop
COPY ./io.github.hedge_dev.unleashedrecomp.png /usr/share/icons/hicolor/128x128/io.github.hedge_dev.unleashedrecomp.png

RUN cpak-clean-junk
