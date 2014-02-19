::--------------------------------------------------------------------
:: This script installs all necessary configuration
:: files as required to upload images to the PhenoCam server
:: (phenocam.sr.unh.edu) on your NetCam SC/XL camera REMOTELY with
:: minimum interaction with the camera
::
:: INPUTS: required inputs are a site name and the time difference
:: from UTC -- (no spaces or underscores allowed in site names)
::
:: USE: remote_phenocam_install.bat host_ip mysite utc-offset-in-hours
:: (example: remote_phenocam_install.bat 140.247.98.22 SITE1 +5)
::
:: DETAILS: the script will login to the NetCam and create a small
:: script, this script runs an wget session which pulls all settings
:: and the installation script from a server. It runs the installation
:: scripts and exits. 
::
:: NOTES: the output of the script will be messy, and warnings will
:: be shown, however these can be ignored. Should the script not
:: execute the necessary changes run it again.
::
:: last updated and maintained by:
:: Koen Hufkens (January 2014) koen.hufkens@gmail.com
::--------------------------------------------------------------------
@echo off

:: if the timezone is positive +
:: replace + with the escaped {+} character
set timezone=%5%
set timezone=%timezone:+={+}%

:: Create VBS script

echo set OBJECT=WScript.CreateObject("WScript.Shell") > sendCommands.vbs
echo WScript.sleep 500 >> sendCommands.vbs
echo OBJECT.SendKeys "%2%{ENTER}" >> sendCommands.vbs
echo WScript.sleep 500 >> sendCommands.vbs
echo OBJECT.SendKeys "%3%{ENTER}" >> sendCommands.vbs
echo WScript.sleep 500 >> sendCommands.vbs
echo OBJECT.SendKeys "cd /etc/config{ENTER}" >> sendCommands.vbs
echo WScript.sleep 500 >> sendCommands.vbs
echo OBJECT.SendKeys "wget http://phenocam.sr.unh.edu/data/configs/phenocam_default_install.tar.gz{ENTER}" >> sendCommands.vbs
echo WScript.sleep 1000 >> sendCommands.vbs
echo OBJECT.SendKeys "gunzip phenocam_default_install.tar.gz{ENTER}" >> sendCommands.vbs
echo WScript.sleep 500 >> sendCommands.vbs
echo OBJECT.SendKeys "tar -xvf phenocam_default_install.tar{ENTER}" >> sendCommands.vbs
echo WScript.sleep 500 >> sendCommands.vbs
echo OBJECT.SendKeys "rm phenocam_default_install.tar{ENTER}" >> sendCommands.vbs
echo WScript.sleep 500 >> sendCommands.vbs
echo OBJECT.SendKeys "sh phenocam_install.sh %4 %timezone% %6 %7 %8{ENTER}" >> sendCommands.vbs
echo WScript.sleep 120000 >> sendCommands.vbs
echo OBJECT.SendKeys "exit{ENTER}" >> sendCommands.vbs
echo WScript.sleep 50 >> sendCommands.vbs
echo OBJECT.SendKeys " " >> sendCommands.vbs

:: Open a Telnet window
start telnet.exe %1

:: Run the script
cscript sendCommands.vbs

:: remove VBS script
del sendCommands.vbs

