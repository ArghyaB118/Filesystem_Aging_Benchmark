#!/bin/sh

# Need this to add universe
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo apt-get update
sudo apt-get dist-upgrade
# Need this to add emacs23-nox
sudo add-apt-repository "deb http://us.archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
sudo apt-get update
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update
sudo apt-get install -y build-essential zlib1g-dev gcc-4.7 g++-4.7 cmake emacs23-nox vim
sudo apt-get install -y git git-core python
sudo apt-get upgrade
exit
