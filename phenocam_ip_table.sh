#!/bin/bash
# crontab script to update the ip table
# for each site, for validation of uptime

# some feedback on the action
echo "uploading IP table"

# how many servers do we upload to
nrservers=`awk 'END {print NR}' server.txt`

# grab the name, date and IP of the camera
DATETIME=`date`
ZONE=` cat /etc/config/overlay0.conf | grep overlay_text | cut -d' ' -f18`
DATETIME=`echo $DATETIME | sed "s/UTC/$ZONE/g"`
IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
SITENAME=`cat /etc/config/overlay0.conf | grep overlay_text | cut -d' ' -f2`

# update the IP and time variables
cat site_ip.html | sed "s/DATETIME/$DATETIME/g" | sed "s/SITEIP/$IP/g" > $SITENAME\_ip.html

# run the upload script for the ip data
# and for all servers
for i in `seq 1 $nrservers` ;
do
	SERVER=`awk -v p=$i 'NR==p' server.txt` 
	cat IP_ftp.scr | sed "s/DATETIMESTRING/$DATETIMESTRING/g" | sed "s/SERVER/$SERVER/g" > IP_ftp_tmp.scr
	ftpscript IP_ftp_tmp.scr >> /dev/null
done

# clean up
rm IP_ftp_tmp.scr
