FROM ghcr.io/containerpak/gtk-sdk:main AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG ASSETS_URL
WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends build-essential git autoconf \
    automake libtool zip unzip tar ca-certificates lld libc++abi-dev llvm-dev \
    pkg-config curl cmake ccache ninja-build clang clang-tools libasound2-dev \
    libpulse-dev libpipewire-0.3-dev libsdl2-dev libtheora-dev libvorbis-dev \
    libxrender-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --recurse-submodules https://github.com/hedge-dev/UnleashedRecomp.git .

# Assets
ADD ${ASSETS_URL}/default.xex ./UnleashedRecompLib/private/default.xex
ADD ${ASSETS_URL}/default.xexp ./UnleashedRecompLib/private/default.xexp
ADD ${ASSETS_URL}/shader.ar ./UnleashedRecompLib/private/shader.ar

RUN cmake --preset linux-release -DSDL2MIXER_VORBIS=VORBISFILE \
        -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache \
        -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache && \
    cmake --build out/build/linux-release --target UnleashedRecomp

FROM ghcr.io/containerpak/gtk:main

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

COPY --from=builder /app/out/build/linux-release/UnleashedRecomp/UnleashedRecomp .
COPY --from=builder /app/flatpak/io.github.hedge_dev.unleashedrecomp.desktop /usr/share/applications
COPY --from=builder /app/UnleashedRecompResources/images/game_icon.png /usr/share/icons/hicolor/128x128/apps/io.github.hedge_dev.unleashedrecomp.png
COPY ./unleashedrecomp /usr/bin

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends libasound2t64 libsdl2-2.0-0 \
    libsndio7.0 libtheora1 libtheoradec2 libvorbis0a libvorbisfile3 libpipewire-0.3-0 \
    libpulse0 libsm6 xdg-utils xdg-desktop-portal && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's|^Exec=/app/bin/UnleashedRecomp|Exec=/usr/bin/unleashedrecomp|' / && \
    ldd ./UnleashedRecomp | tee /tmp/UnleashedRecomp-ldd && \
    ! grep -q 'not found' /tmp/UnleashedRecomp-ldd && \
    cpak-clean-junk
