#!/bin/bash

set -e

function error {
    echo error: "$@"
    exit 1
}

function itime {
    /usr/bin/time "$@"
}

BUILD_GO=y
INTEGRATION=y
FAST=n
SHOW_HELP=n

TEMP=`getopt -o h --long help,no-go,no-integration,fast -n test.bash -- "$@"`
eval set -- "$TEMP"
while true; do
    case "$1" in
        -h|--help)      SHOW_HELP=y         ; shift   ;;
        --no-go)        BUILD_GO=n          ; shift   ;;
        --no-integration) INTEGRATION=n     ; shift   ;;
        --fast)         FAST=y              ; shift   ;;
        --)             shift               ; break   ;;
    esac
done

if [ "$SHOW_HELP" = y ]; then
    echo "usage: test.bash -h|--help"
    echo "       test.bash [--no-go] [--no-integration] [--fast]"
    exit 0
fi

function do_cmd {
    echo "[+] $@"
    eval "$@"
}

# Build Go
if [ "$BUILD_GO" = y ]; then
    pushd go/src
    export GOROOT_BOOTSTRAP
    [ -z "$GOROOT_BOOTSTRAP" ] && error "GOROOT_BOOTSTRAP not set"
    [ "$FAST" = y ] && fast_opt=--no-clean || fast_opt=
    do_cmd GOOS=unigornel GOARCH=amd64 ./make.bash $fast_opt
    popd
fi

# Build unigornel
do_cmd go get -v
do_cmd go build -o unigornel
cat > .unigornel.yaml <<EOF
goroot: $PWD/go
minios: $PWD/minios
EOF
eval $(./unigornel env -c .unigornel.yaml)

# Run integration tests
if [ "$INTEGRATION" = y ]; then
    unigornel_root="$PWD"
    pushd integration_tests
    [ "$FAST" = y ] && fast_opt=--fast || fast_opt=
    UNIGORNEL_ROOT="$unigornel_root" do_cmd itime -p python3 test.py --junit "integration_tests.xml" $fast_opt
    popd
fi
