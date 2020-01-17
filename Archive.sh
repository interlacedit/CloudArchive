#!/bin/bash

## 2020/01/16
## Zac Bolick, Zack McQueen, 
## 
## With the help of rclone this scrip works to archive and push to a remote cloud
## 
## 
## 
## Display a custom error message


logErrorMessage() {
	REASON="$1"
	"$CD" msgbox  --title "Install Error" --text "Error" --informative-text "$REASON" --icon-file "$iconPath" --button1 "Close" --timeout 10
}

downloadFile() {
	echo "Starting Download..." 2>&1
	# Download the specified file from the URL
	tries=2
	echo "$dlURL"
	echo "$pathToFile"
	curl -L "$dlURL" -s -o "$pathToFile" 2>&1
	while [[ "$?" -ne 0 ]]; do
		sleep 2
		if [ "$(cat /tmp/progstat)" = "stopped" ]; then
			exit 1
		fi
		echo "Download Failed, retrying.  This is attempt $tries" 2>&1
		(( tries++ ))
		if [ "$tries" == 11 ]; then
			echo "Download has failed 10 times, exiting" 2>&1
			echo "stopped" > /tmp/progstat
			exit 1
		fi
		curl -L "$dlURL" -s -o "$pathToFile" 2>&1
	done
}

getDownloadSize() {
	curl -sI "$dlURL" | grep -i Content-Length | awk '{print $2}' | tr -d '\r'
}

getDownloadPercent() {
	fSize=$(ls -nl "$pathToFile" | awk '{print $5}')
	percent=$(echo "scale=2;($fSize/$dlSize)*100" | bc)
	percent=${percent%.*}
}

## Check for CocoaDialog and install it if not found
## CocoaDialog Binary will be set as variable "CD" for use in the script.
getCocoaDialogStatus() {
	CD="/Library/Application Support/JAMF/Scripts/cocoaDialog.app/Contents/MacOS/cocoaDialog"
	local tries=1
	while [ ! -e "$CD" ]; do
		if [ "$tries" == 3 ]; then
			echo "Tried to install CocoaDialog 3 times without success. Exiting..."
			exit 1
		else
		    curl -L "https://jamf-repository-su8ch3bpv7h23gzyrmffdr2arw.s3-us-west-2.amazonaws.com/cocoaDialog_3.pkg" -o "/private/tmp/cocoaDialog_3.pkg"
			installer -pkg "/private/tmp/cocoaDialog_3.pkg" -target /
			sleep 5
			(( tries++ ))
		fi
	done
}


# Keep machine awake, as if user is active. 
/usr/bin/caffeinate -disu &


## Install Rclone
## TODO: This needs to be silent right now it prompts for user interaction
## curl https://rclone.org/install.sh | sudo bash
