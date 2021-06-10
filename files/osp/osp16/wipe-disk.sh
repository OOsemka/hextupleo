#!/bin/bash
if [[ `hostname` = *"ceph"* || `hostname` = *"hci"* ]]
then
  LOG=/tmp/wipe_disk.$$.out
  echo "Number of disks detected: $(lsblk -no NAME,TYPE,MOUNTPOINT | grep "disk" | awk '{print $1}' | wc -l)"  | tee ${LOG}
  for DEVICE in `lsblk -no NAME,TYPE,MOUNTPOINT | grep "disk" | awk '{print $1}'`
  do
    ROOTFOUND=0
    echo "Checking /dev/$DEVICE..." | tee -a ${LOG}
    echo "Number of partitions on /dev/$DEVICE: $(expr $(lsblk -n /dev/$DEVICE | awk '{print $7}' | wc -l) - 1)"  | tee -a ${LOG}
    for MOUNTS in `lsblk -n /dev/$DEVICE | awk '{print $7}'`
    do
      if [ "$MOUNTS" = "/" ]
      then
        ROOTFOUND=1
      fi
    done
    if [ $ROOTFOUND = 0 ]
    then
      echo "Root not found in /dev/${DEVICE}" | tee -a ${LOG}
      echo "Wiping disk /dev/${DEVICE}" | tee -a ${LOG}
      if [[ -e /usr/sbin/wipefs ]]
      then
          /usr/sbin/wipefs -af /dev/${DEVICE} | tee -a ${LOG}
      else
              sgdisk -Z /dev/${DEVICE} | tee -a ${LOG}
              sgdisk -g /dev/${DEVICE} | tee -a ${LOG}
      fi
    else
      echo "Root found in /dev/${DEVICE}" | tee -a ${LOG}
    fi
  done
fi
