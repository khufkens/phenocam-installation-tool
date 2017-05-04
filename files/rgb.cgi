#!/bin/sh
#This .cgi will get the temporary image file created by the metadata.cgi
#E.Keel SouthEast Watershed Research Laboratory ARS 2016
LEN=`wc -c $/var/tmp/rgb.jpeg | awk '{ print $1 }'`

echo -ne 'Content-type: image/jpeg\r\n'
echo -ne "Content-length: $LEN\\r\\n"
echo -ne '\r\n'
cat /var/tmp/rgb.jpeg

rm /var/tmp/rgb.jpeg
