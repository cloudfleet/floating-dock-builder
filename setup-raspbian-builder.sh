#!/bin/bash

BUILDER_ADDRESS=$1
FLOATING_DOCK_ADDRESS=$2
BUILDER_PREFIX=$3
BUILDER_NUMBER=$4

LOGIN_USER=pi

SCRIPT_FILE=/tmp/floating-dock-${FLOATING_DOCK_ADDRESS}-${BUILDER_ADDRESS}-script

cat > ${SCRIPT_FILE} <<SCRIPT

sudo su -

echo "Installing dependencies"
curl -s https://packagecloud.io/install/repositories/Hypriot/Schatzkiste/script.deb.sh | sudo bash
apt-get -y install docker-hypriot autossh

echo "Setting Hostname to ${BUILDER_PREFIX}${BUILDER_NUMBER}"

sed -i s/\$(hostname)/${BUILDER_PREFIX}${BUILDER_NUMBER}/g /etc/hosts
sed -i s/\$(hostname)/${BUILDER_PREFIX}${BUILDER_NUMBER}/g /etc/hostname

hostname ${BUILDER_PREFIX}${BUILDER_NUMBER}

echo "establishing SSH link to FloatingDock server"
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "  Creating ssh key"
    ssh-keygen -f ~/.ssh/id_rsa -N ""
fi

echo "  Adding floating dock server to known hosts"
ssh-keyscan  ${FLOATING_DOCK_ADDRESS} >> ~/.ssh/known_hosts 2> /dev/null

echo "  Copying local ssh key to server"
cp ~/.ssh/id_rsa.pub /tmp/id_rsa_root.pub
cp ~/.ssh/id_rsa /tmp/id_rsa_root
chmod 644 /tmp/id_rsa_root.pub
chmod 644 /tmp/id_rsa_root
exit

mkdir -p .ssh
ssh-keyscan  ${FLOATING_DOCK_ADDRESS} >> ~/.ssh/known_hosts 2> /dev/null
ssh-copy-id -i /tmp/id_rsa_root.pub root@${FLOATING_DOCK_ADDRESS}


sudo su -

rm -f /tmp/id_rsa_root.pub /tmp/id_rsa_root

echo "  Setting up autossh - this builder will be reachable under port 100${BUILDER_NUMBER}"
echo "#!/bin/bash" > /etc/rc.local
echo "autossh -M 200${BUILDER_NUMBER}:300${BUILDER_NUMBER} -f -N -T -R 100${BUILDER_NUMBER}:localhost:22 ${FLOATING_DOCK_ADDRESS}" >> /etc/rc.local
chmod +x /etc/rc.local
/etc/rc.local

echo "  copying server public key"
ssh ${FLOATING_DOCK_ADDRESS} cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

SCRIPT

ssh -o ForwardAgent=yes $LOGIN_USER@$BUILDER_ADDRESS < ${SCRIPT_FILE}
