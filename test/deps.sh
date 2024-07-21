#!/bin/bash -e
DIR=$( cd "$( dirname "$0" )" && pwd )
cd $DIR
while ! apt-get update; do
  sleep 1
  echo "retry"
done
apt-get install -y sshpass openssh-client wget
pip install -r requirements.txt
wget https://dl.photoprism.app/samples/Formats/Image/HEIC/20220831_001704_66A1ECB0.heic
