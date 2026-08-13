FROM ghcr.io/containerpak/mesa-sdk:main AS builder

WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

ARG ASSETS_URL=$ASSETS_URL

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends git build-essential autoconf automake \
    libtool pkg-config curl cmake ninja-build clang clang-tools libgtk-3-dev \
    libsdl2-dev libtheora-dev libvorbis-dev libogg-dev \
    libasound2-dev libpulse-dev libpipewire-0.3-dev && \
    rm -rf /var/lib/apt/lists/*

# Assets
ADD ${ASSETS_URL}/default.xex /tmp/private/default.xex
ADD ${ASSETS_URL}/default.xexp /tmp/private/default.xexp
ADD ${ASSETS_URL}/shader.ar /tmp/private/shader.ar

RUN git clone https://github.com/hedge-dev/UnleashedRecomp.git . && \
    mv /tmp/private/* ./UnleashedRecompLib/private && \
    git submodule update --init --recursive && \
    cmake . --preset linux-release && \
    cmake --build ./out/build/linux-release --target UnleashedRecomp

FROM ghcr.io/containerpak/mesa:main

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends libasound2t64 libtheora1 \
    libtheoradec2 libvorbis0a libvorbisfile3 libpipewire-0.3-0t64 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/out/build/linux-release/UnleashedRecomp /usr/bin/UnleashedRecomp
COPY ./io.github.hedge_dev.unleashedrecomp.png /usr/share/icons/hicolor/128x128/apps

RUN ldd /usr/bin/UnleashedRecomp | tee /tmp/ur-ldd && \
    ! grep -q 'not found' /tmp/ur-ldd && \
    cpak-clean-junk
