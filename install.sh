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

function parse_yaml2() {
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
      if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
              vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
              printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
      }
    }' | sed 's/_=/+=/g'
}

eval parse_yaml2 config "CONFIG_"
eval $(parse_yaml2 config "CONFIG_")


##if $DEBUG; then
##    for i in ${CONFIG_ppas[@]}; do
##        if [[ $i == ppa* ]]; then
##            echo "PPA = $i"
##        else
##            echo "Setting up: $i"
##            echo "  - $CONFIG_ppas___url"
##            echo "  - $CONFIG_ppas___sfile"
##            echo "  - $CONFIG_ppas___key"
##        fi
##    done
##    exit
##fi

printf "Please enter the admin passwd: \n"
sudo echo ""


if [ -f /var/lib/dpkg/lock ]; then
    sudo rm /var/lib/dpkg/lock
fi

printf "\nInstalling PPA(s):\n"
for i in ${CONFIG_ppas[@]}; do
    if [[ $i == ppa* ]]; then
        printf  "  - Adding ppa: $i...  "
        sudo apt-add-repository -y $i 2> /dev/null
    else
        printf  "  - Adding ppa: $i...  "
        sudo sh -c "echo '$CONFIG_ppas___url' > $CONFIG_ppas___sfile"
        echo "  - getting key $CONFIG_ppas___key"
        wget -q -O - $CONFIG_ppas___key | sudo apt-key add -
    fi
done

#
# install apt-fast
#   - need to automate install and config of apt-fast
printf "\nInstalling base apps\n"
sudo apt-get update
sudo apt-get install -y di axel aria2 git build-essential

# quickest way to add and configure apt-fast
if [ ! -x /usr/bin/apt-fast ]; then 
   git submodule update --init
   sudo cp apt-fast/apt-fast /usr/bin
   sudo chmod +x /usr/bin/apt-fast

   if [ -f files/apt-fast.conf ]; then
       echo "installing: files/apt-fast.conf --> /etc"
       sudo cp files/apt-fast.conf /etc
   else
       echo "installing: apt-fast/apt-fast.conf --> /etc"
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
                         gtk-recordmydesktop simplescreenrecorder kazam \
                         shutter filebeat scrot

#config logstash
sudo cp files/filebeat.yml /etc/filebeat/filebeat.yml
sudo sed -i -e "s/LOGSTASH/$CONFIG_logstash__server/" /etc/filebeat/filebeat.yml



#
# Setup chrome to run android apps


