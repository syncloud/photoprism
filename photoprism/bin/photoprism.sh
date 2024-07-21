#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/opt/photoprism/lib)
export PATH=${DIR}/bin:$PATH
export PERL5LIB=${DIR}/usr/share/perl5
exec ${DIR}/lib/ld.so --library-path $LIBS ${DIR}/opt/photoprism/bin/photoprism "$@"
