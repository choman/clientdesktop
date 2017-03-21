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


FB_VERSION=5.2.1
KEYSFILE=keys
TOKENFILE=token

function setup_vault() {
    if [ ! -f /usr/local/bin/vault ]; then 
        wget -nc -O /tmp/vault.zip https://releases.hashicorp.com/vault/0.6.5/vault_0.6.5_linux_amd64.zip
        unzip /tmp/vault.zip -d /tmp
        sudo cp /tmp/vault /usr/local/bin
    fi
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

setup_vault

if [ ! -s "$KEYSFILE" ]; then
   echo "please populate keys: $KEYSFILE"
   exit
fi

if [ ! -s "$TOKENFILE" ]; then
   echo "please populate token: $TOKENFILE"
   exit
fi

# get yaml config
eval parse_yaml2 config "CONFIG_"
eval $(parse_yaml2 config "CONFIG_")

# get vault config
declare -a keys
readarray -t keys < $KEYSFILE

token=$(cat $TOKENFILE)


export VAULT_ADDR=http://${CONFIG_freeipa__ip}:8200
export VAULT_TOKEN=$token

vault unseal ${keys[0]} > /dev/null
vault unseal ${keys[1]} > /dev/null
vault unseal ${keys[2]} > /dev/null

freeipa=$(vault read -field=value secret/admin)

#vault seal

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

IFS=""
printf "\nInstalling PPA(s):\n"
for i in ${CONFIG_ppas[@]}; do
    if [[ $i == ppa* ]]; then
        printf  "  - Adding ppa: $i...  "
        sudo apt-add-repository -y $i 2> /dev/null
    else
        appname=$(echo $i | sed -e 's/://' -e 's/[[:space:]]*$//')

        # get app info
        # make debug statement
        #printf  "  - Parsing ppa: $appname...  \n"

        eval myvar=( \${CONFIG_ppas_$appname[@]} )
        url=""
        sfile=""
        item=""
        var=""
        key=""

        for z in ${myvar[@]}; do
           eval var=$(echo $z | awk -F: '{print $1}')
           len=$(expr ${#var} + 1)
           item=$(echo ${z:$len} | sed -e 's/^[[:space:]]//')
           if [[ $var == key ]]; then
              key=$item
           else
              if [[ $var == url ]]; then
                 url=$item
              else
                 sfile=$item
              fi
           fi
        done

        printf  "  - Adding ppa: $appname...  "
        sudo sh -c "echo '$url' > $sfile"
        wget -q -O - $key | sudo apt-key add -
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
   sudo cp -v apt-fast/apt-fast /usr/bin
   sudo chmod +x /usr/bin/apt-fast

   if [ -f files/apt-fast.conf ]; then
       echo "installing: files/apt-fast.conf --> /etc"
       sudo cp -v files/apt-fast.conf /etc
   else
       echo "installing: apt-fast/apt-fast.conf --> /etc"
       sudo cp -v apt-fast/apt-fast.conf /etc
   fi


   # install apt-fast completions (bash)
   sudo cp -v apt-fast/completions/bash/apt-fast /etc/bash_completion.d/
   sudo cp -v apt-fast/completions/bash/apt-fast /usr/share/bash-completion/completions/apt-fast
   sudo chown root:root /etc/bash_completion.d/apt-fast
   . /etc/bash_completion

   # install apt-fast completions (zsh)
   sudo cp -v apt-fast/completions/zsh/_apt-fast /usr/share/zsh/functions/Completion/Debian/
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


sudo apt-fast install -y google-chrome-stable meld tmux tor-browser terminix \
                         gtk-recordmydesktop simplescreenrecorder kazam \
                         shutter vlock scrot ssh autofs green-recorder

# install lynis
git clone https://github.com/CISOfy/lynis $HOME/lynis
   

# download and install filebeat
aria2c -x 8 https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FB_VERSION}-amd64.deb

sudo dpkg -i filebeat*deb

# install freeipa client stuff
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y freeipa-client freeipa-admintools

#config logstash
sudo curl -XPUT "http://$CONFIG_logstash__server:9200/_template/filebeat?pretty" -d@/etc/filebeat/filebeat.template.json

sudo mkdir -p /etc/pki/tls/certs
sudo cp -v files/filebeat.yml /etc/filebeat/filebeat.yml
sudo cp -v files/logstash-beats.crt /etc/pki/tls/certs/logstash-beats.crt
sudo sed -i -e "s/LOGSTASH/$CONFIG_logstash__server/" /etc/filebeat/filebeat.yml

sudo systemctl restart filebeat
sudo systemctl enable filebeat

#
# configure freeipa
sudo cp -v files/krb5.conf /etc
echo "$CONFIG_freeipa__ip     $CONFIG_freeipa__fqdn $CONFIG_freeipa__hostname" | sudo tee -a /etc/hosts
domain=${CONFIG_freeipa__fqdn#.}
sudo ipa-client-install -N --hostname $CONFIG_freeipa__fqdn  --mkhomedir --domain=$domain --server=$CONFIG_freeipa__fqdn -p admin -w $freeipa  --force-join


#
# setup pam 

pam_session="/var/lib/pam/session"
common_session="/etc/pam.d/common-session"

grep mkhomedir $pam_session > /dev/null 2>&1
rval=$?

if [ $rval -ne 0 ]; then
   echo "updating: $pam_session"
   echo "Module: mkhomedir" | sudo tee -a $pam_session
   echo "optional			pam_mkhomedir.so" | sudo tee -a $pam_session

fi

grep mkhomedir $common_session > /dev/null 2>&1
rval=$?

if [ $rval -ne 0 ]; then
    line="session optional			pam_mkhomedir.so"
    sudo sed -i "/systemd/a$line" $common_session
fi

sudo pam-auth-update --package


#setup automounts
sudo cp -v files/auto.* /etc
sudo cp -v files/50* /etc/lightdm/lightdm.conf.d

# Update skel diretory
sudo mkdir -v /etc/skel/Desktop
sudo ln -s /transfer /etc/skel/Desktop/transfer
echo "dconf write /org/mate/screensaver/lock-enabled false" | sudo tee -a /etc/skel/.profile


# enable ufw
sudo ufw enable

#
# Setup chrome to run android apps


