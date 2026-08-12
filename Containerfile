FROM ghcr.io/containerpak/mesa-sdk:main AS build

ARG ASSETS_URL=$ASSETS_URL
ARG UR_COMMIT=cf829a9eca8fb680fba4b0409ddeb6ca92f22e3c

RUN apt update && \
    apt install -y --no-install-recommends build-essential autoconf automake libtool pkg-config \
    curl cmake ccache ninja-build clang clang-tools libgtk-3-dev && \
    git clone https://github.com/hedge-dev/UnleashedRecomp.git /src/unleashedrecomp && \
    cd /src/unleashedrecomp && \
    git checkout "$UR_COMMIT" && \
    test "$(git rev-parse HEAD)" = "$UR_COMMIT" && \
    git submodule update --init --recursive

# Assets
ADD ${ASSETS_URL}/default.xex /src/unleashedrecomp/UnleashedRecompLib/private/default.xex
ADD ${ASSETS_URL}/default.xexp /src/unleashedrecomp/UnleashedRecompLib/private/default.xexp
ADD ${ASSETS_URL}/shader.ar /src/unleashedrecomp/UnleashedRecompLib/private/shader.ar

RUN cmake /src/unleashedrecomp --preset linux-release && \
    cmake --build /src/unleashedrecomp/out/build/linux-release --target UnleashedRecomp

COPY /src/unleashedrecomp/out/build/linux-release/UnleashedRecomp /usr/bin/UnleashedRecomp

FROM ghcr.io/containerpak/mesa:main

COPY --from=build /usr/bin/UnleashedRecomp /usr/bin/UnleashedRecomp

RUN cpak-clean-junk
