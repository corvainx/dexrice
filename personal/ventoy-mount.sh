#!/bin/bash
# ------ THIS IS FOR MY PERSONAL USE ONLY, REFRAIN FROM RUNNING RANDOM SCRIPTS UNLESS YOU KNOW WHAT YOU ARE DOING ------
# fix-ventoy-mount.sh — installs exFAT support and fixes an unformatted Ventoy data partition

DEVICE="/dev/sda1" # check the drive name through lsblk command

sudo pacman -S --needed exfatprogs
sudo mkfs.exfat -n VENTOY "$DEVICE"
udisksctl mount -b "$DEVICE"
