#!/usr/bin/env bash
RED="\033[1;31m"
GRE="\033[1;32m"
YEL="\033[1;33m"
BLU="\033[1;34m"
LBL="\033[1;36m"
DEF="\033[1;00m"

printf "======================Welcome=======================\n"

if [ "$UID" == 0 ]; then
  printf "${RED}\r"
else
  printf "${YEL}\r"
fi
figlet $(whoami) || printf "${RED}Can't print figlet\n"
printf "${DEF}\r"
printf "Server Time: $(date)\n"
printf "=====================Disk Space=====================\n"
df -h | sed -n '/^\/dev/p'
printf "======================Free RAM======================\n"
free -m
printf "System UpTime & Active Users:\n"
w
printf "\n"
printf "Hostname: $(hostname -f)\n"
printf "Current Directory: $(pwd)\n"
if [ "$UID" == 0 ]; then
  printf "=============Last failed logins (3)=================\n"
  lastb | head -n 3
fi
printf "Last passwd: $(passwd -S $(whoami))\n"
printf "Last reboot: \n$(last reboot)\n"

printf "Last dmesg errors (5) :\n"
dmesg | grep error | tail -n 5
