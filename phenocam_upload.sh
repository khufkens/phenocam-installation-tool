#!/bin/sh

#--------------------------------------------------------------------
# This script is cued up in the crontab file and called every
# x min to upload two images, a standard RGB image and an infra-
# red (IR) image (if available) to the PhenoCam server.
#
# last updated and maintained by:
# Koen Hufkens (Januari 2014) koen.hufkens@gmail.com
#--------------------------------------------------------------------

# -------------- SUBROUTINES -----------------------------------------

# subroutine to extract the metadata during image acquisition
metadata() 
{

	# Update the metadata file
	# grab the MAC address
	mac=`ifconfig | grep HWaddr | awk '{print $5}' | sed 's/://g'`
	mac_addr=`echo mac_addr=$mac `

	# grab ip address
	ip=`ifconfig | awk '/inet addr/{print substr($2,6)}'`
	ip_addr=`echo ip=$ip`

	# grab metadata
	cat /dev/video/config0 > /etc/config/metadata.txt

	# colate everything
	echo $ip_addr >> /etc/config/metadata.txt
	echo $mac_addr >> /etc/config/metadata.txt

}


# -------------- SETTINGS -------------------------------------------

# make sure we are in the right directory
cd /etc/config

# export to current clock settings
export TZ=`cat /etc/config/TZ`

# switch time zone sign
if [ -n `echo $TZ | grep -` ]; then
	TZONE=`echo "$TZ" | sed 's/+/-/g'`
else
	TZONE=`echo "$TZ" | sed 's/-/+/g'`
fi

# config device (contains all settings and changing state variables)
CONFIG="/dev/video/config0"

# sets the delay between the
# RGB and IR image acquisitions
DELAY=30

# sets debug state, for script development only
# operational value is 0
DEBUG=1
if [ "$DEBUG" = "1" ] ; then
LOG="/var/tmp/IR_upload.log"
rm -f $LOG > /dev/null
else
LOG="/dev/null"
fi

# -------------- UPLOAD IMAGES --------------------------------------

# grab camera info and make sure it is an IR camera
IR=`status | grep IR | tail -c 2`

# grab camera temperature from memory put it into
# variable TEMP
TEMP=`/bin/mbus -td2 /dev/ds1629 w 0xee w 0xaa,0 r 2 | awk '{ C = and(rshift($1, 7), 0x1ff); if (and(C, 0x100)) C = C - 0x200; C /= 2; printf("%.1f\n", C); }'`

# grab date - keep fixed for RGB and IR uploads
DATE=`date +"%a %b %d %Y %H:%M:%S"`

# grap date and time string to be inserted into the
# ftp scripts - this coordinates the time stamps
# between the RGB and IR images (otherwise there is a
# slight offset due to the time needed to adjust exposure
DATETIMESTRING=`date +"%Y_%m_%d_%H%M%S"`

# substitute the values in the ftp.scr and IR_ftp.scr
# upload scripts
cat ftp.scr | sed "s/DATETIMESTRING/$DATETIMESTRING/g" > ftp_tmp.scr
cat IR_ftp.scr | sed "s/DATETIMESTRING/$DATETIMESTRING/g" > IR_ftp_tmp.scr

# The following few lines updates the time in the overlay
# should time changes have occured it will show up in the
# overlay!! -- this prevents this error

# The following line dumps the current time in the correct format
# to an overlay0_tmp.conf file
cat default_overlay0.conf  | sed "s/TZONE/$TZONE/g" | sed "s/%a %b %d %Y  %H:%M:%S/$DATE/g" | sed "s/\${IC}/$TEMP/g" > overlay0_tmp.conf

# if it's a NetCamSC model make an additional IR picture
# if not just take an RGB picture
if [ "$IR" = "1" ]; then

	# just in case, set IR to 0
	echo "ir_enable=0" > $CONFIG
	sleep $DELAY # adjust exposure

	# grab metadata using the metadata function
	metadata

	# dump overlay configuration to /dev/video/config0
	# device to adjust in memory settings
	# first grab the number of lines in the overlay0_tmp.conf
	# file, then write line by line to the video device
	nrlines=`awk 'END {print NR}' overlay0_tmp.conf`

	for i in `seq 1 $nrlines` ;
	do
	 awk -v p=$i 'NR==p' overlay0_tmp.conf > /dev/video/config0
	done

	# run the upload script With RGB enabled (default)
	ftpscript ftp_tmp.scr >> $LOG
	rm /etc/config/metadata.txt

	# change the settings to enable IR image acquisition
	echo "ir_enable=1" > $CONFIG
	sleep $DELAY	# adjust exposure

	# grab metadata using the metadata function
	metadata

	# dump overlay configuration to /dev/video/config0
	# device to adjust in memory settings
	# first grab the number of lines in the overlay0_tmp.conf
	# file, then write line by line to the video device
	nrlines=`awk 'END {print NR}' overlay0_tmp.conf`

	for i in `seq 1 $nrlines` ;
	do
	 awk -v p=$i 'NR==p' overlay0_tmp.conf > /dev/video/config0
	done

	# run the upload script With IR enabled
	ftpscript IR_ftp_tmp.scr >> $LOG
	rm /etc/config/metadata.txt

	# Reset the configuration to 
	# the default RGB settings
	echo "ir_enable=0" > $CONFIG

	# clean up temporary files
	rm ftp_tmp.scr
	rm IR_ftp_tmp.scr

else

	# just in case, set IR to 0
	echo "ir_enable=0" > $CONFIG
	sleep $DELAY # adjust exposure

	# grab metadata using the metadata function
	metadata

	# dump overlay configuration to /dev/video/config0
	# device to adjust in memory settings
	nrlines=`awk 'END {print NR}' overlay0_tmp.conf`

	for i in `seq 1 $nrlines` ;
	do
	 awk -v p=$i 'NR==p' overlay0_tmp.conf > /dev/video/config0
	done

	# run the upload script With RGB enabled (default)
	ftpscript ftp_tmp.scr >> $LOG
	rm /etc/config/metadata.txt

	# clean up temporary files
	rm ftp_tmp.scr
fi

# restore overlay with auto update for online viewing
nrfiles=`awk 'END {print NR}' overlay0.conf`

for i in `seq 1 $nrfiles` ;
do
 awk -v p=$i 'NR==p' overlay0.conf > /dev/video/config0
done

# clean up shared (between setup) temporary files
rm overlay0_tmp.conf

# Reset the configuration to 
# the default RGB settings (just in case it's stuck at IR)
echo "ir_enable=0" > $CONFIG

exit
