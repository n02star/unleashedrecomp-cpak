FROM ghcr.io/containerpak/mesa-sdk:main AS build

ARG ASSETS_URL=$ASSETS_URL
ARG UR_COMMIT=cf829a9eca8fb680fba4b0409ddeb6ca92f22e3c

# Assets
ADD ${ASSETS_URL}/default.xex /tmp/private/default.xex
ADD ${ASSETS_URL}/default.xexp /tmp/private/default.xexp
ADD ${ASSETS_URL}/shader.ar /tmp/private/shader.ar

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends autoconf automake libtool pkg-config \
    curl cmake ninja-build clang clang-tools libgtk-3-dev git llvm-18-dev libasound2-dev libpulse-dev libpipewire-0.3-dev && \
    git clone https://github.com/hedge-dev/UnleashedRecomp.git /src/unleashedrecomp && \
    cd /src/unleashedrecomp && \
    git checkout "$UR_COMMIT" && \
    test "$(git rev-parse HEAD)" = "$UR_COMMIT" && \
    mv /tmp/private/* ./UnleashedRecompLib/private && \
    git submodule update --init --recursive && \
    cmake . --preset linux-release && \
    cmake --build ./out/build/linux-release --target UnleashedRecomp && \
    cp ./out/build/linux-release/UnleashedRecomp /usr/bin/UnleashedRecomp

FROM ghcr.io/containerpak/mesa:main

COPY --from=build /usr/bin/UnleashedRecomp /usr/bin/UnleashedRecomp

RUN ldd /usr/bin/UnleashedRecomp | tee /tmp/ur-ldd && \
    ! grep -q 'not found' /tmp/ur-ldd && \
    cpak-clean-junk
