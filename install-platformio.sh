#!/bin/sh

# update the container's mirrorlist
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

aur-install platformio
