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


FB_VERSION=5.3.0

ARIA_FLAGS="--conditional-get=true --allow-overwrite=false"
ARIA_FLAGS="--conditional-get=true --auto-file-renaming=false"


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


# get yaml config
eval parse_yaml2 config "CONFIG_"
eval $(parse_yaml2 config "CONFIG_")

sudo -p "Please enter the admin passwd: "  echo ""


if [ -f /var/lib/dpkg/lock ]; then
    sudo rm /var/lib/dpkg/lock
fi

#
# install apt-fast
#   - need to automate install and config of apt-fast
printf "\nUpdating repositories\n"
sudo apt-get update -qq 2> /dev/null 

#sudo apt-fast dist-upgrade -y


dpkg -s filebeat > /dev/null 2>&1
rval=$?


if [ "$rval" -eq 0 ]; then

   iversion=$(dpkg -s filebeat | grep -i version | awk '{print $2}')
   printf "\n\nFilebeat $iversion is installed"

   if [ $iversion = $FB_VERSION ]; then
      printf ", exiting\n\n"
      exit
   fi

   printf ", upgrading\n\n"

else
   printf "filebeat not installed, continuing\n\n"

fi




# download and install filebeat
aria2c $ARIA_FLAGS -x 8 https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FB_VERSION}-amd64.deb

sudo dpkg -i filebeat-${FB_VERSION}-amd64.deb


#config logstash
sudo curl -XPUT "http://$CONFIG_logstash__server:9200/_template/filebeat?pretty" -d@/etc/filebeat/filebeat.template.json

sudo mkdir -p /etc/pki/tls/certs
sudo cp -v files/filebeat.yml /etc/filebeat/filebeat.yml
sudo cp -v files/logstash-beats.crt /etc/pki/tls/certs/logstash-beats.crt
sudo sed -i -e "s/LOGSTASH/$CONFIG_logstash__server/" /etc/filebeat/filebeat.yml

sudo systemctl restart filebeat
sudo systemctl enable filebeat

