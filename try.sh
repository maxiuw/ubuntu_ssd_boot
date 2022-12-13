#!/bin/zsh
UbuntuBackupLabel="/dev/$1"
parttable="./part_table"
# part=""
part=$UbuntuBackupLabel
# sleep 5 
$(sfdisk -f --wipe always $UbuntuBackupLabel < part_table);
for i in $(seq 1 4); 
do  
    part=$UbuntuBackupLabel$i
    $(umount $part) || echo "$part not mounted";
done