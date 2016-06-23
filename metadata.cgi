#!/bin/sh
#Copies metadata to temporary file.
#Captures image and send to temporary location
#E.Keel SouthEast Watershed Research Laboratory ARS 2016
TMP=`mktemp /var/tmp/metadata.XXXXXX`
cp /dev/video/config0 $TMP
cp /dev/video/jpeg0 /var/tmp/rgb.jpeg
LEN=`wc -c $TMP | awk '{ print $1 }'`

echo -ne 'Content-type: text/plain\r\n'
echo -ne "Content-length: $LEN\\r\\n"
echo -ne '\r\n'
cat $TMP

rm $TMP
