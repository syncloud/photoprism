#!/bin/bash -e
DIR=$( cd "$( dirname "$0" )" && pwd )
cd $DIR
while ! apt-get update; do
  sleep 1
  echo "retry"
done
apt-get install -y sshpass openssh-client wget imagemagick curl
pip install -r requirements.txt
wget https://dl.photoprism.app/samples/Formats/Image/HEIC/20220831_001704_66A1ECB0.heic
mx=1000;my=1000;head -c "$((3*mx*my))" /dev/urandom | convert -depth 8 -size "${mx}x${my}" RGB:- $DIR/images/generated-big.png
