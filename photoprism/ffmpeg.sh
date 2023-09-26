#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*/pulseaudio)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*/samba)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*/lapack)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*/blas)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/usr/local/lib)
exec ${DIR}/lib*/*-linux*/ld-*.so* --library-path $LIBS ${DIR}/usr/bin/ffmpeg "$@"
