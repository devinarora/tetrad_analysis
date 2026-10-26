#!/bin/bash
#
# Execute run_jupyter.sh in the container.
#
# Usage:
# > docker_jupyter.sh -d /path/to/dir -p 8889
#

set -e
#set -x

# Git Bash rewrites container paths like /curr_dir into
# C:/Program Files/Git/curr_dir before Docker sees them.
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) export MSYS_NO_PATHCONV=1 ;;
esac

# Parse params.
export JUPYTER_HOST_PORT=${JUPYTER_HOST_PORT:-8888}
export JUPYTER_USE_VIM=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
export VERBOSE=0

while getopts p:d:uv flag
do
    case "${flag}" in
        p) JUPYTER_HOST_PORT=${OPTARG};;
        u) JUPYTER_USE_VIM=1;;
        d) TARGET_DIR=${OPTARG};;
        # /Users/saggese/src/git_gp1/code/
        v) VERBOSE=1;;
    esac
done

if [[ $VERBOSE == 1 ]]; then
    set -x
fi;

# Import the utility functions.
source "$SCRIPT_DIR/utils.sh"

# Execute the script setting the vars for this tutorial.
get_docker_vars_script "${BASH_SOURCE[0]}"
source "$DOCKER_NAME"
print_docker_vars

# Resolve paths physically. `realpath` follows Docker Desktop bind mounts
# under /mnt/wsl/docker-desktop-bind-mounts/..., which makes /data point at
# the mount root instead of this project.
TARGET_DIR="$(cd "$TARGET_DIR" && pwd -P)"
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd -P)"

if [[ $SCRIPT_DIR == /mnt/wsl/docker-desktop-bind-mounts/* || $TARGET_DIR == /mnt/wsl/docker-desktop-bind-mounts/* ]]; then
    echo "ERROR: Docker Desktop bind-mount paths detected. Run this script from Git Bash, not WSL." >&2
    exit 1
fi

# Docker Desktop accepts /mnt/c/... paths from WSL directly. Git Bash needs
# a Windows path because its Docker CLI does not understand /c/... paths.
docker_path() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            if command -v cygpath >/dev/null 2>&1; then
                cygpath -w "$1"
            else
                printf '%s' "$1"
            fi
            ;;
        *)
            printf '%s' "$1"
            ;;
    esac
}

CONTAINER_NAME=${CONTAINER_NAME:-$IMAGE_NAME}
DOCKER_RUN_OPTS=(
    -p "$JUPYTER_HOST_PORT:8888"
    -v "$(docker_path "$TARGET_DIR"):/data"
    -v "$(docker_path "$SCRIPT_DIR"):/curr_dir"
)

# From docker_cmd.sh passing DOCKER_OPTS.
docker image ls "$FULL_IMAGE_NAME"

exec docker run \
    --rm -i \
    --name "$CONTAINER_NAME" \
    "${DOCKER_RUN_OPTS[@]}" \
    "$FULL_IMAGE_NAME" \
    /curr_dir/run_jupyter.sh
