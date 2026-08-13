FROM ghcr.io/containerpak/mesa-sdk:main AS build

ENV DEBIAN_FRONTEND=noninteractive

ARG ASSETS_URL=$ASSETS_URL

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential autoconf automake libtool pkg-config \
    curl cmake make ninja-build clang clang-tools libgtk-3-dev git tar unzip \
    zip libasound2-dev libpulse-dev libpipewire-0.3-dev && \
    rm -rf /var/lib/apt/lists/*

# Assets
ADD ${ASSETS_URL}/default.xex /tmp/private/default.xex
ADD ${ASSETS_URL}/default.xexp /tmp/private/default.xexp
ADD ${ASSETS_URL}/shader.ar /tmp/private/shader.ar

RUN git clone https://github.com/hedge-dev/UnleashedRecomp.git /src/UnleashedRecomp && \
    cd /src/UnleashedRecomp && \
    mv /tmp/private/* ./UnleashedRecompLib/private && \
    git submodule update --init --recursive && \
    cmake . --preset linux-release -DSDL2MIXER_VORBIS=VORBISFILE -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache && \
    cmake --build ./out/build/linux-release --target UnleashedRecomp && \
    cp ./out/build/linux-release/UnleashedRecomp /usr/bin/UnleashedRecomp

FROM ghcr.io/containerpak/mesa:main

COPY --from=build /usr/bin/UnleashedRecomp /usr/bin/UnleashedRecomp

RUN ldd /usr/bin/UnleashedRecomp | tee /tmp/ur-ldd && \
    ! grep -q 'not found' /tmp/ur-ldd && \
    cpak-clean-junk
