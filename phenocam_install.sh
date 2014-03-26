#!/bin/sh

#--------------------------------------------------------------------
# This script installs all necessary configuration
# files as required to upload images to the PhenoCam server
# (phenocam.sr.unh.edu) on your NetCam SC/XL camera
#
# NOTES: this program can be used stand alone or called remotely
# as is done in the remote_phenocam_install.sh script. The script
# will pull all installation files from a server and adjust the
# settings on the NetCam accordingly.
#
# Koen Hufkens (January 2014) koen.hufkens@gmail.com
#--------------------------------------------------------------------

# -------------- SETTINGS -------------------------------------------

# get todays date
TODAY=`date +"%Y_%m_%d_%H%M%S"`

# set the new camera name / could be the same if the camera
# has not moved, or did not get a new function
NEW_CAMERA_NAME=$1

# The time offset of your camera position relative to UTC time
# as specified in + or - XYZ hours
TIMEOFFSET=$2

# set local time zone string if available, otherwise default to LOCAL
if [ -n "$3" ]; then
    LOCALTZ=$3
else
    LOCALTZ="LOCAL"
fi

# set crontab start and end times default
# to 4 and 22 if not provided, set interval
# to 30 min

if [ -n "$4" ]; then
    CRONSTART=$4
else
    CRONSTART="4"
fi

if [ -n "$5" ]; then
    CRONEND=$5
else
    CRONEND="22"
fi

if [ -n "$6" ]; then
    CRONINT=$6
else
    CRONINT="30"
fi

# upload / download server - location from which to grab and
# and where to put config files
HOST='klima.sr.unh.edu'
USER='anonymous'
PASSWD='anonymous'

# make sure we are in the config directory
# before proceeding
cd /etc/config

# -------------- BACKUP OLD CONFIG ----------------------------------

echo ""
echo "#--------------------------------------------------------------------"
echo "#"
echo "# Backing up settings for $NEW_CAMERA_NAME !"
echo "#"
echo "#--------------------------------------------------------------------"
echo ""


# In order to keep track of all the state changes of the camera
# we will upload the current camera configuration to the server.

# remove previous zip files
if [ -f $NEW_CAMERA_NAME\_backup_settings\_$TODAY.tar.gz ]; then
	rm $NEW_CAMERA_NAME\_backup_settings\_$TODAY.tar.gz
fi

# archive all settings
tar -cf $NEW_CAMERA_NAME\_backup_settings\_$TODAY.tar *.conf *.scr

# zip stuff
gzip $NEW_CAMERA_NAME\_backup_settings\_$TODAY.tar

ftp -n << EOF
	open $HOST
	user $USER $PASSWD
	cd data/$1
	binary
	put $NEW_CAMERA_NAME\_backup_settings\_$TODAY.tar.gz
	bye
EOF

# delete uploaded tar archive
rm $NEW_CAMERA_NAME\_backup_settings\_$TODAY.tar.gz

# -------------- DOWNLOAD CONFIG FILES ------------------------------

# download the config files from a server
# using the netcam's ftp function (headless)
# no user input required

# check if default_* files are there
# if so do not download them again
if [ ! -f default_ftp.scr ]; then

echo ""
echo "#--------------------------------------------------------------------"
echo "#"
echo "# Downloading settings from $HOST !"
echo "#"
echo "#--------------------------------------------------------------------"
echo ""

# remove previous install files
if [ -f phenocam_default_install.tar* ]; then
	rm phenocam_default_install.tar*
fi

wget http://$HOST/data/configs/phenocam_default_install.tar.gz

gunzip phenocam_default_install.tar.gz
tar -xvf phenocam_default_install.tar
rm phenocam_default_install.tar

fi

# -------------- SET CAMERA NAME ------------------------------------

# NOTE!! : The system doesn't do well when overwriting the original files
# using sed / awk, always use a tmp file. This is the reason for
# moving the files from the default_ uploaded ones to the final
# correct file names. It makes tracing errors more easy as well.

# grab camera info and make sure it is an IR camera
MODEL=`info | grep "NetCamSC" | cut -d'=' -f2`
MODELNAME=`echo $MODEL | sed 's/NetCam/NetCam /g'`

if [ "$MODEL" = "NetCamSC" ] ; then
	MODELNAME="NetCam SC IR"
else
	MODELNAME="NetCam XL"
fi

# set proper camera names in all config files
# and upload scripts
cat default_overlay0.conf	| sed "s/mycamera/$NEW_CAMERA_NAME/g" | sed "s/netcammodel/$MODELNAME/g" | sed "s/LOCAL/$LOCALTZ/g" > bak_overlay0.conf
cat default_ftp.scr 		| sed "s/mycamera/$NEW_CAMERA_NAME/g" > ftp.scr
cat default_IR_ftp.scr 		| sed "s/mycamera/$NEW_CAMERA_NAME/g" > IR_ftp.scr

# rewrite everything into new files, just to be sure
cat default_video.conf 	> video.conf
cat default_video0.conf > video0.conf
cat default_ntp.server 	> ntp.server
cat default_sched0.conf > sched0.conf

# remove all default files
rm default_*

echo ""
echo "#--------------------------------------------------------------------"
echo "#"
echo "# Adjusting setting files !"
echo "#"
echo "#--------------------------------------------------------------------"
echo ""

# -------------- APPLY NEW CONFIGURATION ----------------------------

# set time zone
# dump setting to config file
SIGN=`echo $TIMEOFFSET | cut -c'1'`

if [ "$SIGN" = "+" ]; then
	echo "UTC$TIMEOFFSET" | sed 's/+/-/g' > /etc/config/TZ
else
	echo "UTC$TIMEOFFSET" | sed 's/-/+/g' > /etc/config/TZ
fi

# export to current clock settings
export TZ=`cat /etc/config/TZ`

echo "# The camera clock is set to UTC$TIMEOFFSET"
echo "# validate this setting - set date/time shown below !!!"
date

# convert the sign from the UTC time zone TZ variable (for plotting in overlay)
if [ "$SIGN" = "+" ]; then
	TZONE=`echo "$TZ" | sed 's/-/+/g'`
else
	TZONE=`echo "$TZ" | sed 's/+/-/g'`
fi

# adjust overlay settings to reflect current time baseline (UTC)
cat bak_overlay0.conf  | sed "s/TZONE/$TZONE/g" > overlay0.conf

# check if the exposure grid is altered from factory default
# if so retain this exposure grid but alter all other settings
# this avoids resetting exposure grids on certain funky cameras
# which have been adjusted previously but might still benefit 
# from an update (e.g. having the meta-data pushed etc).
factory_grid="0x007e7e7e7e7e7e00"
current_grid=`cat /dev/video/config0 | grep 'exposure_grid' | cut -d'=' -f2`
phenocam_grid=`cat video.conf | grep 'exposure_grid' | cut -d'=' -f2`

if [ "$factory_grid" != "$current_grid" ];then
	cat video.conf | sed -e s/"$phenocam_grid"/"$current_grid"/g > tmp.conf
	
	# overwrite the PhenoCam default settings with those
	# preserving the old exposure grid
	mv tmp.conf video.conf
fi

# dump video configuration to /dev/video/config0
# device to adjust in memory settings
nrfiles=`awk 'END {print NR}' video.conf`

for i in `seq 1 $nrfiles` ;
do
 # assign a shell variable to a awk parameter with
 # the -v statement
 awk -v p=$i 'NR==p' video.conf > /dev/video/config0
done

# dump overlay configuration to /dev/video/config0
# device to adjust in memory settings
nrfiles=`awk 'END {print NR}' overlay0.conf`

for i in `seq 1 $nrfiles` ;
do
 # assign a shell variable to a awk parameter with
 # the -v statement
 awk -v p=$i 'NR==p' overlay0.conf > /dev/video/config0
done

# cycle the clocks settings by calling the rc script
# which governs NTP settings
rc.ntpdate

# -------------- SET SCHEDULED UPLOADS -------------------------------

# set the cron job
# this job calls the phenocam_upload.sh script and
# upload a RGB and IR picture (if available) to the
# phenocam servers

echo ""
echo "#--------------------------------------------------------------------"
echo "#"
echo "# Setting a crontab for timed uploads to the PhenoCam network !"
echo "#"
echo "#--------------------------------------------------------------------"
echo ""

# grap the default settings
cat /etc/default/crontab > crontab

# append the custom line
echo "*/$CRONINT $CRONSTART-$CRONEND * * * admin sh /etc/config/phenocam_upload.sh" >> crontab

# -------------- SAVE CONFIG / UPLOAD TEST IMATES -----------------------

echo ""
echo "#--------------------------------------------------------------------"
echo "#"
echo "# Saving config files to flash memory / uploading test images !"
echo "#"
echo "#--------------------------------------------------------------------"
echo ""

# !!!! MOST IMPORTANT, SAVE CONFIG TO FLASH !!!!
config save

# uploading first images, testing the upload procedure
echo "Uploading the first images as a test... (wait 30s)"
sh phenocam_upload.sh

echo ""
echo "#--------------------------------------------------------------------"
echo "#"
echo "# Done !!! - close the terminal if it remains open !"
echo "#"
echo "#--------------------------------------------------------------------"
echo ""


exit 0
