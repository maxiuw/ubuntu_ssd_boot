#!/bin/zsh
# automates the method explained in
# https://askubuntu.com/questions/1267225/how-to-create-a-bootable-clone-of-boot-disk/1327623#1327623
# USE CAREFULLY, THIS IS INTRINSICALLY DANGEROUS SOFTWARE
# Pierre ALBARÈDE 2021/4/24
# tested with Ubuntu 20.10


# Assumptions:
# - /boot is not on a separate partition.
# - root partition has label $UbuntuLabel and the first partition on the same device is the EFI system partition,
# - root partition backup has label $UbuntuBackupLabel and the first partition on the same device is available for the EFI system partition backup,
# - device names are like sd[a-z].

# To do:
# - pick and exclude duplicate mount (e. g. for NFS) from /etc/fstab to avoid overfilling the backup device,
# -check that backup volume partition sizes are enough.

# --- begin config

UbuntuLabel="/dev/$1"
UbuntuBackupLabel="/dev/$2"

part=""
for i in $(seq 1 4); 
do  
    part=$UbuntuBackupLabel$i
    $(umount $part) || echo "$part not mounted";
done

echo "Are you sure? you will use $UbuntuLabel as source and $UbuntuBackupLabel to offload. \n$UbuntuBackupLabel will be formated and will become a copy of $UbuntuLabel \you have 3s to stop" 
# (optional) move to a new line
# read -p "Press any key to continue or ctrl+c to stop";
sleep 3
echo "copying partition table"
$(sfdisk -f --wipe always $UbuntuBackupLabel < part_table);


echo "copying iso images into $UbuntuBackupLabel";
for i in $(seq 1 4); 
do
    echo "started $UbuntuBackupLabel$i";
    $(dd if="sdc$i.iso" of="$UbuntuBackupLabel$i" status=progress bs=4M);
    echo "/dev/$2$i finished";
done


logfile="rsync.log"
# excluded from rsync
# /swapfile can be big and transfering it is a waste of time,
# not having a swapfile backup makes some errors at boot and shutdown.
# excludedByUser='/export,"/home/*/.cache",/swapfile,$logfile'
excludedByUser='/export,"/home/*/.cache",$logfile'
# --- end config

# Partition attributes are named as in
# % lsblk -PO /dev/sda1
# [filtered]
# NAME="sda1" PATH="/dev/sda1" FSTYPE="vfat" FSUSED="24.1M" FSUSE%="12%" FSVER="FAT32" MOUNTPOINT="/boot/efi" LABEL="EFI" UUID="67E3-17ED" PTUUID="b5ca7ab4-d564-49a1-a43b-d9125d4dcbab" PTTYPE="gpt" PARTTYPE="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" PARTTYPENAME="EFI System" PARTLABEL="EFI System Partition" PARTUUID="05bdacf6-78ff-451d-8c4d-bb812fd68e83" PKNAME="sda"
 
# Many attributes look similar, I use LABEL and UUID, not PARTLABEL and PTUUID, PARTUUID.

alias lsblkn='lsblk -n'

#########
# TESTS #
#########

# # Are all UUIDs distinct?
# [[ -n $(lsblkn -o UUID|grep '\S'|sort|uniq --repeated) ]]&&{echo "Error: not all UUIDs are distinct.  Did you use dd?";exit 1}

# # Does only one partition exists with LABEL $UbuntuLabel?
# [[ $(lsblkn -o LABEL|grep -x $UbuntuLabel|wc -l) != 1 ]]&&{echo "Error: $UbuntuLabel is not unique.";exit 1}

# # Does only one partition exists with LABEL $UbuntuBackupLabel?
# [[ $(lsblkn -o LABEL|grep -x $UbuntuBackupLabel|wc -l) != 1 ]]&&{echo "Error: $UbuntuBackupLabel is not unique.";exit 1}

#######################################
# DETERMINE PARTITION PATHS AND UUIDS #
#######################################
# paths for mount
# UUIDs for (display and) replacement in config files

# blkid (or findfs) finds only one occurrence, that is why I have checked unicity
UbuntuPath=$(blkid --label $UbuntuLabel)
UbuntuBackupPath=$(blkid --label $UbuntuBackupLabel)

devicePath=/dev/$(lsblkn -o PKNAME $UbuntuPath)
deviceBackupPath=/dev/$(lsblkn -o PKNAME $UbuntuBackupPath)

UbuntuUUID=$(lsblkn -o UUID $UbuntuPath)
echo "Ubuntu partition UUID:            $UbuntuUUID"

# EFI is always first partition with number 1
EFIPath="$devicePath"1
EFIUUID=$(lsblkn -o UUID $EFIPath)
echo "EFI system partition UUID:        $EFIUUID"

UbuntuBackupUUID=$(lsblkn -o UUID $UbuntuBackupPath)
echo "Ubuntu backup partition UUID:     $UbuntuBackupUUID"

EFIBackupPath="$deviceBackupPath"1
EFIBackupUUID=$(lsblkn -o UUID $EFIBackupPath)
echo "EFI system partition backup UUID: $EFIBackupUUID"

# determine GRUB partition number from Ubuntu partition name
# on original
UbuntuGpt=$(echo $UbuntuPath|sed "s/\/dev\/sd[a-z]/gpt/")
# on backup
UbuntuBackupGpt=$(echo $UbuntuBackupPath|sed "s/\/dev\/sd[a-z]/gpt/")
