#!/bin/bash

PASSWORD='SEU-PASSOWORD'
USERSYSTEM='SEU-USUARIO'
## UUID=FA44ABFF6447FFFE or /dev/sda1

echo $PASSWORD | sudo -S /home/$USERSYSTEM/safe_mount.sh UUID=FA44ABFF6447FFFE /media/$USERSYSTEM/Games
sleep 1
echo $PASSWORD | sudo -S /home/$USERSYSTEM/safe_mount.sh /dev/sda1 /media/$USERSYSTEM/nomepartitionsda1
sleep 1

clear
