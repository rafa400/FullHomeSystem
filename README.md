# FullHomeSystem
HomeAssistant + Mosquitto(MQTT) + NodeRed + PostgreSQL


This is a script to install working set of software from source to get working a Debian based system with the latest versions of each piece.
More info at https://www.telepi.org


Install the latest Raspbian system into your Raspberry Pi 3
Get the script:
```
pi@raspberrypi:~ $ sudo bash
root@raspberrypi:/home/pi# wget https://raw.githubusercontent.com/rafa400/FullHomeSystem/master/telepi_fullhome.sh
```
Execute the script:
```
root@raspberrypi:/home/pi# bash telepi_fullhome.sh
```
Then you will be promted to set arch and reuired NodeJS version. Default values are tested and working right now.
```
*************************
** NODEJS and NODE-RED **
*************************

Architecture? armv6l / armv7l [armv7]:
NodeJS version? [v6.11.3]:
```
You will find some error like. Don't worry about that, the script bypass the problem getting the files and puting it into the right place.
```
node-pre-gyp ERR! Tried to download(404): https://github.com/kelektiv/node.bcrypt.js/releases/download/v1.0.3/bcrypt_lib-v1.0.3-node-v48-linux-arm.tar.gz 
node-pre-gyp ERR! Pre-built binaries not found for bcrypt@1.0.3 and node@6.11.3 (node-v48 ABI) (falling back to source compile with node-gyp) 
```
For mosquitto install, you will be asked again to insert the version to install or accept the default one. Mosquitto compilation will throw a lot of warning. Don't panic!
```
*****************
*** MOSQUITTO ***
*****************

Mosquitto version? [1.4.14]: 
```
