#!/bin/bash

BUILDER_ADDRESS=$1
FLOATING_DOCK_ADDRESS=$2
BUILDER_PREFIX=$3
BUILDER_NUMBER=$4

LOGIN_USER=pi

NEW_HOSTNAME=${BUILDER_PREFIX}${BUILDER_NUMBER}
SCRIPTS_DIR=/opt/floating-dock/builder

SCRIPT_FILE=/tmp/floating-dock-${FLOATING_DOCK_ADDRESS}-${BUILDER_ADDRESS}-script

cat > ${SCRIPT_FILE} <<SCRIPT

sudo su -

echo "Installing dependencies"
curl -s https://packagecloud.io/install/repositories/Hypriot/Schatzkiste/script.deb.sh | sudo bash
apt-get -y install docker-hypriot

echo "Setting Hostname to ${BUILDER_PREFIX}${BUILDER_NUMBER}"

sed -i s/\$(hostname)/${BUILDER_PREFIX}${BUILDER_NUMBER}/g /etc/hosts
sed -i s/\$(hostname)/${BUILDER_PREFIX}${BUILDER_NUMBER}/g /etc/hostname
hostname ${BUILDER_PREFIX}${BUILDER_NUMBER}


mkdir -p ${SCRIPTS_DIR}
cd ${SCRIPTS_DIR}

wget https://${FLOATING_DOCK_ADDRESS}/builders/scripts.tar.gz
tar -xzf scripts.tar.gz


echo "#!/bin/bash" > /etc/rc.local
echo "nohup python ${SCRIPTS_DIR}/build_runner.py ${FLOATING_DOCK_ADDRESS} >> /var/log/floating_dock_runner.log &" >> /etc/rc.local
chmod +x /etc/rc.local
/etc/rc.local

SCRIPT

ssh -o ForwardAgent=yes $LOGIN_USER@$BUILDER_ADDRESS < ${SCRIPT_FILE}
