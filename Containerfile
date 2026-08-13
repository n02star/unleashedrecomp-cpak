FROM ghcr.io/containerpak/mesa-sdk:main AS build

ARG ASSETS_URL=$ASSETS_URL
ARG UR_COMMIT=cf829a9eca8fb680fba4b0409ddeb6ca92f22e3c

# Assets
ADD ${ASSETS_URL}/default.xex /tmp/default.xex
ADD ${ASSETS_URL}/default.xexp /tmp/default.xexp
ADD ${ASSETS_URL}/shader.ar /tmp/shader.ar

RUN apt update && \
    apt install -y --no-install-recommends autoconf automake libtool pkg-config \
    curl cmake ninja-build clang clang-tools libgtk-3-dev git llvm-18-dev libasound2-dev libpulse-dev libpipewire-0.3-dev && \
    git clone https://github.com/hedge-dev/UnleashedRecomp.git /src/unleashedrecomp && \
    cd /src/unleashedrecomp && \
    git checkout "$UR_COMMIT" && \
    test "$(git rev-parse HEAD)" = "$UR_COMMIT" && \
    mv /tmp/{default.xex,default.xexp,shader.ar} ./UnleashedRecompLib/private && \
    git submodule update --init --recursive && \
    cmake . --preset linux-release \
          -DSDL2MIXER_VORBIS=VORBISFILE \
          -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
          -DCMAKE_C_COMPILER_LAUNCHER=ccache && \
    cmake --build ./out/build/linux-release --target UnleashedRecomp && \
    cp ./out/build/linux-release/UnleashedRecomp /usr/bin/UnleashedRecomp

FROM ghcr.io/containerpak/mesa:main

COPY --from=build /usr/bin/UnleashedRecomp /usr/bin/UnleashedRecomp

RUN cpak-clean-junk
