#!/bin/bash

XSOCK=/tmp/.X11-unix

here=$(dirname "$(realpath $0)")
image_name=prusaslicer
version=${1:-"2.9.4"}

#sudo usermod -aG video,render $USER

if [ -n "$(docker images -q $image_name:$version)" ]; then
    docker buildx build --platform linux/amd64 \
                        --build-arg HOST_UID=$(id -u) \
                        --build-arg HOST_GID=$(id -g) \
                        --build-arg JOBS=$(( $(nproc) / 2 )) \
                        --build-arg VERSION=$version \
                        --tag "$image_name:$version" \
                        --tag "$image_name:latest" \
                        $here
fi

# preserve settings between runs
mkdir -p "$HOME/cad" \
         "$HOME/.config/PrusaSlicer"

docker run --rm -it \
           --user $UID:$UID \
           --network host \
           --env DISPLAY=$DISPLAY \
           --env QT_X11_NO_MITSHM=1 \
           --device=/dev/dri:/dev/dri \
           --group-add=$(getent group render | cut -d: -f3) \
           --group-add=$(getent group video | cut -d: -f3) \
           --volume $XSOCK:$XSOCK:ro \
           --volume $HOME/cad:/home/prusa/host \
           --volume $HOME/.config/PrusaSlicer:/home/prusa/.config/PrusaSlicer \
           "$image_name:latest"
