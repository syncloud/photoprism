#!/bin/bash -xe
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib)
LIBS=$LIBS:$(echo ${DIR}/lib/*-linux-gnu*)
${DIR}/ld.so --library-path $LIBS ${DIR}/bin/darktable-cli "$@"
