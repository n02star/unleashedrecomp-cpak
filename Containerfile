FROM ghcr.io/containerpak/gtk-sdk:main AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG ASSETS_URL
WORKDIR /src

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends build-essential git autoconf \
    automake libtool zip unzip tar ca-certificates lld libc++abi-dev llvm-dev \
    pkg-config curl cmake ccache ninja-build clang clang-tools libasound2-dev \
    libpulse-dev libpipewire-0.3-dev libsdl2-dev libtheora-dev libvorbis-dev \
    libxrender-dev && \
    cpak-clean-junk

RUN git clone --recurse-submodules https://github.com/hedge-dev/UnleashedRecomp.git .

# Assets
ADD ${ASSETS_URL}/default.xex ./UnleashedRecompLib/private/default.xex
ADD ${ASSETS_URL}/default.xexp ./UnleashedRecompLib/private/default.xexp
ADD ${ASSETS_URL}/shader.ar ./UnleashedRecompLib/private/shader.ar

RUN cmake --preset linux-release -DSDL2MIXER_VORBIS=VORBISFILE \
        -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache \
        -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache \
        -DGAME_INSTALL_DIRECTORY="${HOME}/.local/share/UnleashedRecomp" && \
    cmake --build out/build/linux-release --target UnleashedRecomp

FROM ghcr.io/containerpak/gtk:main

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /src/out/build/linux-release/UnleashedRecomp/UnleashedRecomp /usr/bin/
COPY io.github.hedge_dev.unleashedrecomp.desktop /usr/share/applications/
COPY --from=builder /src/UnleashedRecompResources/images/game_icon.png /usr/share/icons/hicolor/128x128/apps/io.github.hedge_dev.unleashedrecomp.png

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends libsdl2-2.0-0 \
    libsndio7.0 libtheora1 libtheoradec2 libvorbis0a libvorbisfile3 libpipewire-0.3-0t64 libsm6 && \
    ldd /usr/bin/UnleashedRecomp | tee /tmp/UnleashedRecomp-ldd && \
    ! grep -q 'not found' /tmp/UnleashedRecomp-ldd && \
    cpak-clean-junk
