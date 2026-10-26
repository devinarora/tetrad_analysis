build_container_image() {
    echo "# ${FUNCNAME[0]} ..."
    echo "FULL_IMAGE_NAME=$FULL_IMAGE_NAME"
    # Prepare build area.
    DIR="../tmp.build"
    if [[ -d $DIR ]]; then
        rm -rf $DIR
    fi;
    cp -Lr . $DIR || true
    # Build container.
    echo "DOCKER_BUILDKIT=$DOCKER_BUILDKIT"
    echo "DOCKER_BUILD_MULTI_ARCH=$DOCKER_BUILD_MULTI_ARCH"
    if [[ $DOCKER_BUILD_MULTI_ARCH != 1 ]]; then
        # Build for a single architecture.
        echo "Building for current architecture..."
        OPTS="--progress plain $@"
        (cd $DIR; docker build $OPTS -t $FULL_IMAGE_NAME . 2>&1 | tee ../docker_build.log; exit ${PIPESTATUS[0]})
    else
        # Build for multiple architectures.
        echo "Building for multiple architectures..."
        OPTS="$@"
        export DOCKER_CLI_EXPERIMENTAL=enabled
        # Use the default builder.
        docker buildx use multiarch
        docker buildx inspect --bootstrap
        # Note that one needs to push to the repo since otherwise it is not possible to keep multiple 
        (cd $DIR; docker buildx build --push --platform linux/arm64,linux/amd64 $OPTS --tag $FULL_IMAGE_NAME . 2>&1 | tee ../docker_build.log; exit ${PIPESTATUS[0]})
        # Report the status.
        docker buildx imagetools inspect $FULL_IMAGE_NAME
    fi;
    # Report build version.
    rm -f docker_build.version.log
    (cd $DIR; docker run --rm -i -v $(pwd):/data $FULL_IMAGE_NAME bash -c "/data/version.sh") 2>&1 | tee docker_build.version.log
    #
    docker image ls $FULL_IMAGE_NAME
    echo "*****************************"
    echo "SUCCESS"
    echo "*****************************"
}


get_docker_vars_script() {
    local local_dir="$1"
    local script_dir
    # Find the name of the container.
    script_dir="$(cd -- "$(dirname -- "$local_dir")" &> /dev/null && pwd -P)"
    DOCKER_NAME="$script_dir/docker_name.sh"
    if [[ ! -e $DOCKER_NAME ]]; then
        echo "Can't find $DOCKER_NAME"
        exit -1
    fi;
    source "$DOCKER_NAME"
}


print_docker_vars() {
    echo "IMAGE_NAME=$IMAGE_NAME"
    echo "FULL_IMAGE_NAME=$FULL_IMAGE_NAME"
}


run() {
    cmd="$*"
    echo "> $cmd"
    eval "$cmd"
}
