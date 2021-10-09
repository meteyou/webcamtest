#!/bin/bash

set -e
set -x
export DEBIAN_FRONTEND=noninteractive


if [ "${UID}" == "0" ]; then
    echo -e "\nDO NOT RUN THIS SCRIPT AS 'root' !!!\n"
    exit 1
fi
echo -e "Some Commands have to run as 'root' via sudo."
echo -e "You will be asked for password if needed.\n"
# Remove existing webcamd.
echo -e "Backup existing files...\n"
mkdir -p ${HOME}/webcamd-backup
if [ -e "/etc/systemd/system/webcamd.service" ]; then
    cp -p /etc/systemd/system/webcamd.service ${HOME}/webcamd-backup
fi
if [ -e "/usr/local/bin/webcamd" ]; then
    cp -p /usr/local/bin/webcamd ${HOME}/webcamd-backup/
fi
if [ -e "/etc/logrotate.d/webcamd" ]; then
    cp -p /etc/logrotate.d/webcamd ${HOME}/webcamd-backup/webcamd.logrotate
fi

# Remove existing.
echo -e "Removing existing webcamd...\n"
sudo rm -rf /etc/logrotate.d/webcamd
sudo rm -rf /usr/local/bin/webcamd
sudo rm -rf /etc/systemd/system/webcamd.service

# Install Dependency
sudo apt install crudini -y

# Install Project "crowsnest"
echo -e "Installing webcamd and enable Service"
sudo ln -s $PWD/webcamd /usr/local/bin/webcamd
sudo cp -r $PWD/webcamd.service /etc/systemd/system/
cp -r $PWD/sample_configs/minimal.conf ${HOME}/klipper_config/webcam.conf
sudo systemctl daemon-reload
sudo systemctl enable webcamd


# Install ustreamer
# Make sure its clean
if [ -d "${HOME}/ustreamer" ]; then
    rm -rf ${HOME}/ustreamer/
fi

echo -e "Compiling ustreamer..."
cd ~
git clone https://github.com/pikvm/ustreamer.git
cd ustreamer
sudo apt install build-essential libevent-dev libjpeg-dev libbsd-dev \
libraspberrypi-dev libgpiod-dev -y
export WITH_OMX=1
make -j 4 # push limit
echo -e "Create symlink..."
sudo ln -sf ${HOME}/ustreamer /usr/local/bin/

# Install v4l2rtspserver
# Make sure its clean
if [ -d "${HOME}/v4l2rtspserver" ]; then
    rm -rf ${HOME}/v4l2rtspserver/
fi
echo -e "Compiling v4l2rtspserver..."
cd ~
git clone https://github.com/mpromonet/v4l2rtspserver.git
cd v4l2rtspserver
sudo apt install cmake liblivemedia-dev liblog4cpp5-dev -y
cmake . && make -j 4 # push limit
echo -e "Create symlink..."
sudo ln -sf ${HOME}/v4l2rtspserver/ /usr/local/bin/

# create mjpg_streamer symlink
echo -e "Create mjpg_streamer symlink..."
sudo ln -sf ${HOME}/mjpg-streamer/mjpg_streamer /usr/local/bin/

# Start webcamd
sudo sh -c "echo bcm2835-v4l2 >> /etc/modules"
sudo systemctl start webcamd

echo -e "Finished Installation..."
echo -e "Please reboot the PI."
exit 0
