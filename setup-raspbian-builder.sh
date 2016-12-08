#!/bin/bash

BUILDER_ADDRESS=$1
FLOATING_DOCK_ADDRESS=$2
FLOATING_DOCK_NEW_BUILDER_KEY=$3
BUILDER_PREFIX=$4
BUILDER_NUMBER=$5

LOGIN_USER=pi

NEW_HOSTNAME=${BUILDER_PREFIX}${BUILDER_NUMBER}
SCRIPTS_DIR=/opt/floating-dock/builder
CONFIG_DIR=/etc/floating-dock/builder

SCRIPT_FILE=/tmp/floating-dock-${NEW_HOSTNAME}-script


cat > ${SCRIPT_FILE} <<SCRIPT

sudo su -

echo "Installing dependencies"
curl -s https://packagecloud.io/install/repositories/Hypriot/Schatzkiste/script.deb.sh | sudo bash
apt-get -y install docker-hypriot

echo "Setting Hostname to ${NEW_HOSTNAME}"

sed -i s/\$(hostname)/${NEW_HOSTNAME}/g /etc/hosts
sed -i s/\$(hostname)/${NEW_HOSTNAME}/g /etc/hostname
hostname ${NEW_HOSTNAME}


mkdir -p ${CONFIG_DIR}

mkdir -p ${SCRIPTS_DIR}
cd ${SCRIPTS_DIR}

wget ${FLOATING_DOCK_ADDRESS}/api/v1/builders/scripts.tar.gz
tar -xzf scripts.tar.gz


echo "#!/bin/bash" > /etc/rc.local
echo "nohup python -u ${SCRIPTS_DIR}/build_runner.py ${FLOATING_DOCK_ADDRESS} ${FLOATING_DOCK_NEW_BUILDER_KEY} ${NEW_HOSTNAME} >> /var/log/floating_dock_runner.log 2> &1 &" >> /etc/rc.local
chmod +x /etc/rc.local
/etc/rc.local

SCRIPT

ssh -o ForwardAgent=yes $LOGIN_USER@$BUILDER_ADDRESS < ${SCRIPT_FILE}
