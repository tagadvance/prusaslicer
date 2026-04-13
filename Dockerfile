FROM debian:trixie

ARG CREATED
ARG DEBIAN_FRONTEND=noninteractive
ARG HOST_UID
ARG HOST_GID
ARG JOBS
ARG VERSION
ARG SUDO_FORCE_REMOVE=yes

LABEL org.opencontainers.image.title="PrusaSlicer"
LABEL org.opencontainers.image.description="Unofficial build of PrusaSlicer from source."
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.source="https://github.com/tagadvance/prusaslicer"
LABEL org.opencontainers.image.revision="version_${VERSION}"
LABEL org.opencontainers.image.vendor="https://github.com/tagadvance"
LABEL org.opencontainers.image.licenses="GNU Affero General Public License v3.0"

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

RUN groupadd --gid ${HOST_GID} prusa \
    && useradd --uid ${HOST_UID} --gid ${HOST_GID} --create-home prusa

RUN apt update \
    && apt install -y sudo git build-essential autoconf cmake libglu1-mesa-dev libgtk-3-dev \
                      libdbus-1-dev libtool libwebkit2gtk-4.1-dev locales texinfo \
    # Install locales and set the locale to en_US.UTF-8
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && cd /home/prusa \
    && sudo -u prusa git clone --depth 1 --branch version_${VERSION} https://github.com/prusa3d/PrusaSlicer.git \
    && sudo -u prusa mkdir --parents /home/prusa/PrusaSlicer/deps/build /home/prusa/PrusaSlicer/build \
    # Building dependencies
    && cd /home/prusa/PrusaSlicer/deps/build \
    && sudo -u prusa cmake .. -DDEP_WX_GTK3=ON \
    # This is a little flaky. It usually takes 2-3 passes.
    && until sudo -u prusa make -j ${JOBS}; do sleep 0; done \
    # Building PrusaSlicer
    && cd /home/prusa/PrusaSlicer/build \
    && sudo -u prusa cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DSLIC3R_FHS=1 -DSLIC3R_DESKTOP_INTEGRATION=0 \
      -DSLIC3R_STATIC=1 -DSLIC3R_GTK=3 -DSLIC3R_PCH=OFF \
      -DCMAKE_PREFIX_PATH=$(pwd)/../deps/build/destdir/usr/local \
    # WARNING: This gobbles up ~1.25G RAM per job.
    && make -j ${JOBS} install \
    && rm -rf /home/prusa/PrusaSlicer \
    # Replace dev dependencies with runtime dependencies
    && apt autoremove --purge -y sudo git build-essential autoconf cmake libglu1-mesa-dev libgtk-3-dev \
                                 libdbus-1-dev libtool libwebkit2gtk-4.1-dev texinfo \
    && apt install --no-install-recommends --yes libpng16-16 libgl1 libxkbcommon-x11-0 libgtk-3-0 libwebkit2gtk-4.1-0 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/prusa

ENTRYPOINT ["/usr/local/bin/prusa-slicer"]
