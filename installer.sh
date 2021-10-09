#!/bin/bash

set -e
set -x


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

# Install Project "crowsnest"
echo -e "Installing webcamd and enable Service"
ln -s ./webcamd /usr/local/bin/webcamd
cp -r ./webcamd.service /etc/systemd/system/
cp -r ./sample_configs/minimal.conf ${HOME}/klipper_config/webcam.conf
sudo systemctl daemon-reload
sudo systemctl enable webcamd


# Install ustreamer
echo -e "Compiling ustreamer..."
cd ~
git clone https://github.com/pikvm/ustreamer.git
cd ustreamer
sudo apt install build-essential libevent-dev libjpeg-dev libbsd-dev \
libraspberrypi-dev libgpiod
export WITH_OMX=1
make
echo -e "Create symlink..."
ln -s ./ustreamer /usr/local/bin/

# Install v4l2rtspserver
echo -e "Compiling v4l2rtspserver..."
cd ~
git clone https://github.com/mpromonet/v4l2rtspserver.git
cd v4l2rtspserver
sudo apt install cmake liblivemedia-dev libv4l2cpp liblog4cpp5-dev
cmake . && make
echo -e "Create symlink..."
ln -s ./v4l2rtspserver /usr/local/bin/

# create mjpg_streamer symlink
echo -e "Create mjpg_streamer symlink..."
ln -s ${HOME}/mjpg_streamer/mjpg_streamer /usr/local/bin/

# Start webcamd
sudo sh -c "echo bcm2835-v4l2 >> /etc/modules"
sudo systemctl start webcamd

echo -e "Finished Installation..."
echo -e "Please reboot the PI."
exit 0
