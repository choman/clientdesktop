#!/bin/bash


#
# Add ppas
PPAS=(
   "ppa:libreoffice/ppa"
   "ppa:saiarcot895/myppa"
   "ppa:git-core/ppa"
  )


for i in ${PPAS[@]}; do
    sudo apt-add-repository -y $i
done

# setup chrome ppa
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

#
# install apt-fast
sudo apt update
sudo apt install -y apt-fast di axel build-essential
sudo apt-fast dist-upgrade -y

#
# determine vbox version
#   - place holder

#
# install extra software, ppas should be installed above.  see PPAS
#   - chrome
#   - tor
#   - desktop recorders
sudo apt-fast install -y google-chrome-stable


#
# Setup chrome to run android apps


