# ubuntu_ssd_boot
Script and instruction how to create multiple bootable ubuntu ssd drives
Majority of the code was written by Pierre ALBARÈDE, the author of [this post](https://askubuntu.com/questions/1267225/how-to-create-a-bootable-clone-of-boot-disk/1333501#1333501).

## 1. Create first bootable disk follow [this post](https://campus-rover.gitbook.io/lab-notebook/infrastructure/ssd-instructions).
Quite useful command throughout the whole process (in case you don't know) `lsblk` listing all connected devices and their partitions.
Pay attantion which ones you are using so you don't reset you main system by the accident :)
Important note: for the future reference do not seperate /home and /, that creates weird problems. Instead create a large enough / partition and proceed with that.  


After that you may need to run boot-repair on the ubuntu that you have on you local machine. 


[Boot-repair instruction](https://help.ubuntu.com/community/Boot-Repair)

In case you cannot get to the the system (grub terminal on the launch) follow [stackechange post](https://unix.stackexchange.com/questions/329926/grub-starts-in-command-line-after-reboot/330852#330852).

## 2. Create partition table of the main ssd disk

`sudo sfdisk -d /dev/sdX > part_table` 

## 3. Create an image of echa partition (4 images according to the tutorial)
To do that we avoid creating 500gb (im my case) image of the ssd drive. Instead we have 4 images occupying ~40gb together (you can make it much smaller)


`sudo dd if=/dev/sdXi of=sdXi.iso bs=4M status=progress`


## 4. No put the script _copy_disks.sh in the folder where the images are and run

`sudo sh copy_disks.sh sdX sdY` 

where `sdX` is the source disk and `sdY` is its copy.

notes:

1. I realiezed that sometimes if you do it for multiple disks at the same time, for some reason it does not work. Just re-do it.

2. Sometimes, it is better to removed all the partition of ssd (`sdY`) drive before. It is sone in `copy_disks.sh` when we first wipe and then copy partition table, but for some reason sometimes it did not work :)
