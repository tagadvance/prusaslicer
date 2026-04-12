FROM debian:trixie

ARG DEBIAN_FRONTEND=noninteractive
ARG HOST_UID
ARG HOST_GID
ARG JOBS
ARG VERSION

RUN groupadd --gid ${HOST_GID:-1000} prusa \
    && useradd --uid ${HOST_UID:-1000} --gid ${HOST_GID:-1000} --create-home prusa \
    && apt update \
    && apt install -y git build-essential autoconf cmake libglu1-mesa-dev libgtk-3-dev libdbus-1-dev libtool libwebkit2gtk-4.1-dev locales texinfo \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    # Install locales and set the locale to en_US.UTF-8
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8

USER prusa

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

WORKDIR /home/prusa/

RUN git clone https://github.com/prusa3d/PrusaSlicer.git \
    && cd PrusaSlicer \
    && git checkout tags/version_${VERSION}

WORKDIR /home/prusa/PrusaSlicer/deps

# Building dependencies
RUN mkdir build; \
    cd build; \
    cmake .. -DDEP_WX_GTK3=ON; \
    # This is a little flaky. It usually takes 2-3 passes.
    # WARNING: This eats up 10G+ RAM on a 16-core, 32-thread CPU.
    until make -j ${JOBS:-4}; do sleep 0; done

WORKDIR /home/prusa/PrusaSlicer

# Building PrusaSlicer
RUN mkdir build; \
    cd build; \
    cmake .. -DSLIC3R_STATIC=1 -DSLIC3R_GTK=3 -DSLIC3R_PCH=OFF -DCMAKE_PREFIX_PATH=$(pwd)/../deps/build/destdir/usr/local; \
    # WARNING: This eats up 40G+ RAM on a 16-core, 32-thread CPU.
    make -j ${JOBS:-4}


ENTRYPOINT ["/home/prusa/PrusaSlicer/build/src/prusa-slicer"]
