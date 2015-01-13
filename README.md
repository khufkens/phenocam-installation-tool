# PhenoCam Installation Tool (PIT)

PhenoCam Installation Tool (PIT) is a set of scripts for Linux/Mac OSX and Windows taking care of the settings as needed by cameras installed by or associated with the [PhenoCam network](http://phenocam.sr.unh.edu).

Custom changes can be made to the code to suite your own needs however, remember to save any changes twice. First by altering the configuration files you want to see changed, second by writing these changes from volatile to persistent (flash) memory using the following command:

	config save

## Installation

clone the project to your home computer using the following command (with git installed)

	git clone https://khufkens@bitbucket.org/khufkens/phenocam-installation-tool.git

alternatively, download the project using [this link](https://bitbucket.org/khufkens/phenocam-installation-tool/get/master.zip).

Unzip the downloaded files or use the files cloned by git as is.

## Use

The installation script runs within a terminal on all platforms. To open a terminal search for “Terminal” in OSX spotlight or “cmd” in the program search field (under the Start button) in Windows. For linux users I assume a familiarity with opening a terminal.

### Windows
On the command prompt of a terminal the scripts have the same syntax, for Windows script this would be:

	PIT.bat IP USER PASSWORD CAMERA TIME_OFFSET TZ CRON_START CRON_END CRON_INT

You will need the telnet.exe program to be installed on your computer. As of Windows 7 this isn't installed by default anymore but can still be downloaded from the Microsoft website. Full instructions can be found [here](http://technet.microsoft.com/en-us/library/cc771275%28v=ws.10%29.aspx).

### Linux / OSX
On Linux / Mac OSX systems this would read:

	sh PIT.sh IP USER PASSWORD CAMERA TIME_OFFSET TZ CRON_START CRON_END CRON_INT
or

	./PIT.sh IP USER PASSWORD CAMERA TIME_OFFSET TZ CRON_START CRON_END CRON_INT

with:

Parameter     | Description                    	
------------- | ------------------------------ 	
IP	      | ip address of the camera 		
USER	      | user name (admin - if not set) 	
PASSWORD      | user password (on a new Stardot NetCam this is admin) 
CAMERA        | the name of the camera / site
TIME_OFFSET   | difference in hours from UTC of the timezone in which the camera resides (always use + or - signs to denote differences from UTC)
TZ            | a text string corresponding to the local time zone (e.g. EST)
CRON_START    | start of the scheduled image acquisitions (e.g. 4 in the morning)
CRON_END      | end of the scheduled image acquisitions (e.g. ten at night, so 22 in 24-h notation)
CRON_INT      | interval at which to take pictures (e.g. 15, every 15 minutes - default phenocam setting is 30)
[all parameters are required!]

An example of our in lab test camera configuration:

	./PIT.sh 140.247.89.xx admin admin testcam3 -5 EST 4 22 30

This configures the camera 'testcam3', located in the EST time zone (UTC -5) to take images every half hour between 4 and 22h.

## Additional information

The script will take care of any differences in model types, and will enable the upload of infrared (IR) images by default (if available). After the install be sure to check the results by browsing to the camera's IP address. You can see that the above commands have taken effect as the name and time zone offset are mentioned in the overlay on top of the image. If you are not sure about your time zone offset a visual time zone map can be found [here](http://www.timeanddate.com/time/map/).

Throughout the installation procedure the command prompt gives you feedback on the process. To test a succesful install it will try to upload a set of images to the PhenoCam server. If you request a site name beforehand (the data directory has to be created on the server), we can validate if the setup is pushing data correctly right after your install.

Critical in the operation is that you check and double check the input parameters (no checks are in place yet). Although the script will never 'brick' a camera it can push settings which make the camera not behave properly and hard to reconfigure. In such a case the configuration of the camera can be reset to factory defaults by pushing the reset button on the back of the camera using a small rod. However, if access to the site is difficult you might want to make sure you push the right settings to the camera. Furthermore, as the configuration files are pulled from the PhenoCam server, internet access is vital to configure the camera correctly, if you have only intermitted internet access on your site make sure to run the install script during this time.
