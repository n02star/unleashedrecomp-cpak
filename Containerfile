FROM ghcr.io/containerpak/mesa-sdk:main AS builder

WORKDIR /src

ENV DEBIAN_FRONTEND=noninteractive

ARG ASSETS_URL=$ASSETS_URL

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends build-essential git autoconf \
    automake libtool zip unzip tar ca-certificates \
    pkg-config curl cmake ninja-build clang clang-tools libgtk-3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --recurse-submodules https://github.com/hedge-dev/UnleashedRecomp.git .

# Assets
ADD ${ASSETS_URL}/default.xex /src/UnleashedRecompLib/private/default.xex
ADD ${ASSETS_URL}/default.xexp /src/UnleashedRecompLib/private/default.xexp
ADD ${ASSETS_URL}/shader.ar /src/UnleashedRecompLib/private/shader.ar

RUN cmake --preset linux-release && \
    cmake --build ./out/build/linux-release --target UnleashedRecomp

FROM ghcr.io/containerpak/mesa:main

COPY --from=builder /src/out/build/linux-release/UnleashedRecomp /usr/bin/UnleashedRecomp
COPY ./io.github.hedge_dev.unleashedrecomp.png /usr/share/icons/hicolor/128x128/apps

RUN ldd /usr/bin/UnleashedRecomp | tee /tmp/ur-ldd && \
    ! grep -q 'not found' /tmp/ur-ldd && \
    cpak-clean-junk
