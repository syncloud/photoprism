#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=${DIR}/usr/local/lib
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*)
export LIBHEIF_PLUGIN_PATH=$DIR/usr/local/lib/libheif
exec ${DIR}/lib*/*-linux*/ld-*.so* --library-path $LIBS ${DIR}/usr/local/bin/heif-convert "$@"
