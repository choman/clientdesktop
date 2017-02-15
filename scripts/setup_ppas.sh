#!/bin/bash
#######################################################################
#
#
#
#
#
#
#
#
#
#######################################################################

#
# Add ppas
PPAS=(
   "ppa:libreoffice/ppa"
   "ppa:saiarcot895/myppa"
   "ppa:git-core/ppa"
   "ppa:webupd8team/tor-browser"
   "ppa:webupd8team/terminix"
   "ppa:maarten-baert/simplescreenrecorder"
   "ppa:shutter/ppa"
  )


printf "Please enter the admin passwd: \n"
sudo echo ""


printf "\nInstalling PPA(s):\n"
for i in ${PPAS[@]}; do
    printf  "  - Adding ppa: $i...  "
    sudo apt-add-repository -y $i 2> /dev/null
done


# setup chrome ppa
printf "\nInstalling manual PPA(s):\n"
printf  "  - Adding ppa: chrome-browser...  "
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

