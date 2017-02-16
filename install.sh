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

#
# install apt-fast
#   - need to automate install and config of apt-fast
printf "\nInstalling base apps\n"
sudo apt update
sudo apt install -y di axel aria2 git build-essential

# quickest way to add and configure apt-fast
if [ ! -x /usr/bin/apt-fast ]; then 
   git clone https://github.com/ilikenwf/apt-fast /tmp/apt-fast
   sudo cp /tmp/apt-fast/apt-fast /usr/bin
   sudo chmod +x /usr/bin/apt-fast
   if [ -f apt-fast.conf ]; then
       sudo cp apt-fast.conf /etc
   else
       sudo cp /tmp/apt-fast/apt-fast.conf /etc
   fi
fi

sudo apt-fast dist-upgrade -y

printf "\nConfiguring apt-fast\n"
sudo cp -pv /usr/share/bash-completion/completions/apt-fast /etc/bash_completion.d


#
# determine vbox version
#   - place holder

#
# install extra software, ppas should be installed above.  see PPAS
#   - chrome
#   - tor
#   - desktop recorders
#   - tmux
#   - terminix
printf "\nInstalling user apps\n"
sudo apt-fast install -y google-chrome-stable tmux tor-browser terminix \
                         gtk-recordmydesktop simplescreenrecorder kazam shutter



#
# Setup chrome to run android apps


