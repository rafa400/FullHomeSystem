#!/bin/bash
#
#  Rafael Gandia-Castello
#  Carcaixent, 01/10/2017
#
# Copyright 2017   Rafael GandiaCastello
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

arch="armv7l"       # RPi3: armv7l // RPi: armv6l
node_ver="v6.11.3"  # NodeJS version to compose the filename to download

mosquitto_ver="1.4.14"

apt-get -y update
apt-get -y install vim git

echo ""
echo "*************************"
echo "** NODEJS and NODE-RED **"
echo "*************************"
echo ""
read -p 'Architecture? armv6l / armv7l [armv7]: ' arch2
read -p 'NodeJS version? [v6.11.3]: ' node_ver2

arch=${arch2:-$arch}
node_ver=${node_ver2:-$node_ver}

cd /opt
wget https://nodejs.org/dist/$node_ver/node-$node_ver-linux-$arch.tar.xz
tar -xf node-$node_ver-linux-$arch.tar.xz
rm node-$node_ver-linux-$arch.tar.xz
ln -s node-$node_ver-linux-$arch node

mkdir /opt/node/lib/nde_modules
cd /opt/node/lib/nde_modules
wget https://github.com/kelektiv/node.bcrypt.js/archive/master.zip
unzip master.zip
mv node.bcrypt.js-master bcrypt

cd /opt
chown pi:pi node-$node_ver-linux-$arch -R

if grep -q "/opt/node/bin" "/home/pi/.profile"; then
  echo "PATH ready at /home/pi/.profile"
else
cat >> /home/pi/.profile << EOF
if [ -d "/opt/node/bin" ] ; then
   PATH="\$PATH:/opt/node/bin"
fi
EOF
fi
if grep -q "/opt/node/bin" "/root/.profile"; then
  echo "PATH ready at /root/.profile"
else
cat >> /root/.profile << EOF
if [ -d "/opt/node/bin" ] ; then
   PATH="\$PATH:/opt/node/bin"
fi
EOF
fi

source ~/.profile

su -c "npm config set prefix '/opt/node'" - pi
su -c "npm install -g node-red" - pi

apt-get -y install sense-hat python3-pip
pip3 install pillow 

su -c "npm install -g node-red-contrib-ibm-watson-iot node-red-contrib-play-audio node-red-node-ledborg node-red-node-pi-sense-hat node-red-node-ping node-red-node-random node-red-node-smooth suncalc moment https node-red-contrib-https node-red-contrib-ramp-thermostat node-red-contrib-bigtimer" - pi

# node-red-node-serialport removed to avoid warnings

# wget https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/nodered.service -O /lib/systemd/system/nodered.service
# Changed to set PATH as needed
cat > /lib/systemd/system/nodered.service << EOF
# systemd service file to start Node-RED

[Unit]
Description=Node-RED graphical event wiring tool.
Wants=network.target
Documentation=http://nodered.org/docs/hardware/raspberrypi.html

[Service]
Type=simple
# Run as normal pi user - feel free to change...
User=pi
Group=pi
WorkingDirectory=/home/pi
Nice=5
Environment="NODE_OPTIONS=--max_old_space_size=256"
Environment="PATH=/opt/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
# uncomment and edit next line if you need an http proxy
#Environment="HTTP_PROXY=my.httpproxy.server.address"
# uncomment the next line for a more verbose log output
#Environment="NODE_RED_OPTIONS=-v"
#ExecStart=/usr/bin/env node $NODE_OPTIONS red.js $NODE_RED_OPTIONS
ExecStart=/usr/bin/env node-red-pi $NODE_OPTIONS $NODE_RED_OPTIONS
# Use SIGINT to stop
KillSignal=SIGINT
# Auto restart on crash
Restart=on-failure
# Tag things in the log
SyslogIdentifier=Node-RED
#StandardOutput=syslog

[Install]
WantedBy=multi-user.target
EOF

wget https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-start -O /usr/bin/node-red-start
wget https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-stop -O /usr/bin/node-red-stop
chmod +x /usr/bin/node-red-st*
systemctl --system daemon-reload
systemctl enable nodered.service

echo ""
echo "*****************"
echo "*** MOSQUITTO ***"
echo "*****************"
echo ""
read -p 'Mosquitto version? [1.4.14]: ' mosquitto_ver2
mosquitto_ver=${mosquitto_ver2:-$mosquitto_ver}

# cd /etc/apt/sources.list.d
# wget http://repo.mosquitto.org/debian/mosquitto-stretch.list
# wget http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key
# apt-key add mosquitto-repo.gpg.key
# rm mosquitto-repo.gpg.key
# apt-get install FAILED due to some packages version into "Debian Strech": libssl1.0.0 and libwebsockets3 now its libssl1.0.2 ó libssl1.1 and libwebsockets8
apt-get -y install libc-ares-dev  uuid-dev libwebsockets-dev libssl-dev make xsltproc docbook-to-man docbook-xsl

cd /
wget http://mosquitto.org/files/source/mosquitto-$mosquitto_ver.tar.gz
tar -xf mosquitto-$mosquitto_ver.tar.gz
cd mosquitto-$mosquitto_ver

make WITH_WEBSOCKETS=yes
make install
useradd -M mosquitto
mkdir /var/lib/mosquitto
chown mosquitto:mosquitto /var/lib/mosquitto
mkdir /var/log/mosquitto
chown mosquitto:mosquitto /var/log/mosquitto
mkdir /etc/mosquitto/conf.d
chown mosquitto:mosquitto /etc/mosquitto/conf.d

# https://www.freedesktop.org/software/systemd/man/systemd.service.html
cat > /etc/systemd/system/mosquitto.service << EOF
[Unit]
Description=mosquitto MQTT v31 message broker
Requires=network.target
After=network.target

[Service]
Type=simple
PIDFile=/var/run/mosquitto.pid
ExecStart=/usr/bin/env /usr/local/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf
User=mosquitto

[Install]
WantedBy=multi-user.target
EOF
# Conf file with password file commented
cat >> /etc/mosquitto/mosquitto.conf << EOF
# Place your local configuration in /etc/mosquitto/conf.d/
#
# A full description of the configuration file is at
# /usr/share/doc/mosquitto/examples/mosquitto.conf.example

pid_file /var/run/mosquitto.pid

persistence true
persistence_location /var/lib/mosquitto/

log_dest file /var/log/mosquitto/mosquitto.log
#password_file /etc/mosquitto/passwd

#allow_anonymous false

include_dir /etc/mosquitto/conf.d

#bridge_cafile /etc/ssl/certs/ca-certificates.crt
EOF
# Make a reolad of available services 
systemctl --system daemon-reload
systemctl enable mosquitto.service


echo ""
echo "**********************"
echo "*** HOME ASSISTANT ***"
echo "**********************"
echo ""
apt-get -y install docker bash socat jq curl libpq-dev
apt-get -y install python3 python3-venv python3-pip
# https://home-assistant.io/docs/installation/raspberry-pi/

useradd -m -d /home/homeassistant -s /bin/bash homeassistant
mkdir /var/log/homeassistant
chown homeassistant:pi /var/log/homeassistant
mkdir /srv/homeassistant
chown homeassistant:pi /srv/homeassistant

cd /srv/homeassistant
#pip3 install --upgrade pip 
#pip3 install wheel
pip3 install --upgrade --user homeassistant pip setuptools wheel virtualenv
pip3 install --user homeassistant psycopg2

su - homeassistant <<'EOF'
cd /srv/homeassistant
python3 -m venv .
source bin/activate
pip3 install homeassistant

mkdir /home/homeassistant/.homeassistant
touch /home/homeassistant/.homeassistant/known_devices.yaml
EOF

# https://www.freedesktop.org/software/systemd/man/systemd.service.html
cat > /etc/systemd/system/homeassistant.service << EOF
[Unit]
Description=Homeassistant
Requires=network.target
After=network.target

[Service]
Type=simple
PIDFile=/var/run/homeassistant.pid
ExecStart=/usr/bin/env /bin/bash -c 'cd /srv/homeassistant; source bin/activate; hass;'
User=homeassistant

[Install]
WantedBy=multi-user.target
EOF

# Make a reolad of available services 
systemctl --system daemon-reload
systemctl enable homeassistant.service

echo ""
echo "****************"
echo "*** Postgres ***"
echo "****************"
echo ""

apt-get -y install postgresql
echo ""
echo "*********************************************************************************"
echo "*** To set a password for the postgres user execute:                          ***"
echo ""
echo "su -c \"psql ALTER USER \"postgres\" WITH PASSWORD \'new_password\';\" - postgres"
echo ""
echo "*********************************************************************************"

