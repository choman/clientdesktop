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


KEYSFILE=keys
TOKENFILE=token

function setup_vault() {
    vers=0.7.0

    if [ ! -f /usr/local/bin/vault ]; then
        wget -nc -O /tmp/vault.zip https://releases.hashicorp.com/vault/${vers}/vault_${vers}_linux_amd64.zip
        sudo unzip /tmp/vault.zip -d /usr/local/bin
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

echo ${a/Unseal Key [1-5]: /}

vault unseal ${keys[0]/Unseal Key [1-5]: /} > /dev/null
vault unseal ${keys[1]/Unseal Key [1-5]: /} > /dev/null
vault unseal ${keys[2]/Unseal Key [1-5]: /} > /dev/null

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

# install freeipa client stuff
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y freeipa-client freeipa-admintools

#
# configure freeipa
sudo cp -v files/krb5.conf /etc
echo "$CONFIG_freeipa__ip     $CONFIG_freeipa__fqdn $CONFIG_freeipa__hostname" | sudo tee -a /etc/hosts
domain=${CONFIG_freeipa__fqdn#.}
yes | sudo ipa-client-install -N --hostname $CONFIG_freeipa__fqdn  --mkhomedir --domain=$domain --server=$CONFIG_freeipa__fqdn -p admin -w $freeipa  --force-join


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

