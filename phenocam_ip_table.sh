#!/bin/bash
# crontab script to update the ip table

# grab the name, date and IP of the camera
DATETIME=`date`
ZONE=` cat /etc/config/overlay0.conf | grep overlay_text | cut -d' ' -f18`
DATETIME=`echo $DATETIME | sed "s/UTC/$ZONE/g"`
IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
SITENAME=`cat /etc/config/overlay0.conf | grep overlay_text | cut -d' ' -f2`

# update the IP and time variables
cat site_ip.html | sed "s/DATETIME/$DATETIME/g" | sed "s/SITEIP/$IP/g" > $SITENAME\_ip.html

# run the upload script for the ip data
ftpscript IP_ftp.scr >> /dev/null
