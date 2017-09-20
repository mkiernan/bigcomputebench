#!/bin/bash -x
###############################################################################
# Azure Extension Script:
# Install essential tools for Azure Big Compute / Azure Batch
#
# Tested On: Ubuntu 17.04 Only
#
###############################################################################
if [[ $(id -u) -ne 0 ]] ; then
    echo "Must be run as root"
    exit 1
fi

ADMIN=$1

export DEBIAN_FRONTEND=noninteractive
echo "* hard memlock unlimited" >> /etc/security/limits.conf
echo "* soft memlock unlimited" >> /etc/security/limits.conf
apt-get -y update
#apt-get -y upgrade

# Install dev & sysadmin tools
sudo apt-get install -y build-essential g++ git gcc make cmake htop autotools-dev libicu-dev libbz2-dev libboost-all-dev libssl-dev libffi-dev libpython-dev python-dev python-pip pip python3-pip zip
pip3 install --upgrade pip
pip3 install wheel
apt-get install -y redis-tools
echo "##############################################################################"

# Install azure-cli
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
apt-get -y install -y apt-transport-https
apt-get -y update && apt-get install -y azure-cli
# Configure azure cli
# https://docs.microsoft.com/en-us/cli/azure/format-output-azure-cli?view=azure-cli-latest
mkdir /home/$ADMIN/.azure
cat <<'EOF' >> /home/$ADMIN/.azure/config
[cloud]
name = AzureCloud

[core]
first_run = yes
output = table
collect_telemetry = yes

[logging]
enable_log_file = yes
EOF
chown $ADMIN /home/$ADMIN/.azure
echo "# azurecli ###################################################################"
#
# Install azure batch cli extensions
# https://github.com/Azure/azure-batch-cli-extensions
/opt/az/bin/python3 -m pip install azure-cli-batch-extensions
echo "#cli extensions###############################################################"

# Install DOTNET & azcopy
# https://www.microsoft.com/net/core#linuxubuntu
# https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-linux
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-zesty-prod zesty main" > /etc/apt/sources.list.d/dotnetdev.list
apt-get install -y dotnet-sdk-2.0.0
echo "# dotnet ######################################################################"
#echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-zesty-prod zesty main" > /etc/apt/sources.list.d/microsoft-prod.list
#sudo apt-get install azcopy
wget -O azcopy.tar.gz https://aka.ms/downloadazcopyprlinux
tar -xvf azcopy.tar.gz
./install.sh
echo "# azcopy #####################################################################"

# Install Docker
# https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-using-the-repository
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get install -y apt-transport-https ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get install -y docker-ce
echo "# docker #####################################################################"

# Install Batch Shipyard - Ensure you are NOT root for this section
# https://github.com/Azure/batch-shipyard/blob/master/docs/01-batch-shipyard-installation.md
# credit to Karl Podesta for this little hack:
su - $ADMIN -c 'SYVERSION="2.9.4";\
wget https://github.com/Azure/batch-shipyard/archive/$SYVERSION.tar.gz;\
tar -xvf $SYVERSION.tar.gz; \
cd batch-shipyard-$SYVERSION;\
SHIPYARD=`pwd`;\
./install.sh -3;\
echo "export PATH=$PATH:$HOME/.local/bin:$SHIPYARD" >> ~/.bashrc
'
echo "# shipyard ###################################################################"
