#!/bin/bash

XSOCK=/tmp/.X11-unix

registry='ghcr.io/tagadvance'
image_name='prusaslicer'

#sudo usermod -aG video,render $USER

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
           "$registry/$image_name:latest"
