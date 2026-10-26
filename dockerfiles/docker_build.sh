#!/bin/bash -e

source ./utils.sh
source ./docker_name.sh

# Build container.
export DOCKER_BUILDKIT=1
#export DOCKER_BUILDKIT=0
build_container_image
