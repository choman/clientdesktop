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

function parse_yaml() {
    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
       indent = length($1)/2;
       vname[indent] = $2;
       for (i in vname) {if (i > indent) {delete vname[i]}}
           if (length($3) > 0) {
               vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
               printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
           }
    }' | sed 's/_=/+=/g'
}

eval $(parse_yaml config "CONFIG_")


printf "Please enter the admin passwd: \n"
sudo echo ""


printf "\nInstalling PPA(s):\n"
for i in ${CONFIG_ppas[@]}; do
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
   git submodule update --init
   sudo cp apt-fast/apt-fast /usr/bin
   sudo chmod +x /usr/bin/apt-fast
   if [ -f files/apt-fast.conf ]; then
       sudo cp files/apt-fast.conf /etc
   else
       sudo cp apt-fast/apt-fast.conf /etc
   fi

   # install apt-fast completions (bash)
   sudo cp apt-fast/completions/bash/apt-fast /etc/bash_completion.d/
   sudo cp apt-fast/completions/bash/apt-fast /usr/share/bash-completion/completions/apt-fast
   sudo chown root:root /etc/bash_completion.d/apt-fast
   . /etc/bash_completion

   # install apt-fast completions (zsh)
   sudo cp apt-fast/completions/zsh/_apt-fast /usr/share/zsh/functions/Completion/Debian/
   sudo chown root:root /usr/share/zsh/functions/Completion/Debian/_apt-fast
   # source /usr/share/zsh/functions/Completion/Debian/_apt-fast
fi

sudo apt-fast dist-upgrade -y

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


