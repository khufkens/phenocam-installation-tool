PhenoCam Installation Tool (PIT) is a set of scripts for Linux/Mac OSX and Windows taking care of the settings as needed by cameras installed by or associated with the PhenoCam network (http://phenocam.sr.unh.edu).

The installation script runs within a terminal on all platforms. To open a terminal search for “Terminal” in OSX spotlight or “cmd” in the program search field (under the Start button) in Windows. For linux users I assume a familiarity with opening a terminal.

On the command prompt of a terminal the scripts have the same syntax, in case of the windows script this would be:


	PIT.bat IP USER PASSWORD CAMERA TIME_OFFSET TZ_FLAG

on Linux / Mac OSX this would read:


	sh PIT.sh IP USER PASSWORD CAMERA TIME_OFFSET TZ_FLAG
or

	./PIT.sh IP USER PASSWORD CAMERA TIME_OFFSET TZ_FLAG

with:

Parameter     | Description                    	
------------- | ------------------------------ 	
IP*	      | ip address of the camera 		
USER*	      | user name (admin - if not set) 	
PASSWORD*     | user password (on a new Stardot NetCam this is admin) 
CAMERA*       | the name of the camera / site
TIME_OFFSET*  | difference in hours from UTC of the timezone in which the camera resides (no daylight savings)
TZ_FLAG       | a text string corresponding to the local time zone (e.g. EST; set to LOCAL when not provided)

[* required parameters]
