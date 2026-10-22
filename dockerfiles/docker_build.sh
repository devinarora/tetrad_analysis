#!/bin/bash -e

source ./utils.sh

REPO_NAME=umd_msml610
IMAGE_NAME=TetradAnalysis

# Build container.
export DOCKER_BUILDKIT=1
#export DOCKER_BUILDKIT=0
build_container_image
