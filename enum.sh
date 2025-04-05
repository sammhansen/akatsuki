#!/bin/bash

read -p "Enter target's name (working directory) : " TARGET_NAME
read -p "Enter target url without http* : " TARGET_URL
read -p "Enter target url with http* : " FULL_TARGET_URL

USERNAME=$(whoami)
DIRECTORY_PATH=/home/$USERNAME/Sec/BugBounty/$TARGET_NAME/enum

if ! [ -d $DIRECTORY_PATH ]; then
	mkdir -p $DIRECTORY_PATH
fi

check_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "$1" is not installed. skipping
		return 1
	fi

	return 0
}

enum() {
	if check_command "subfinder"; then
		cat <<EOF
		"Running subfinder"
EOF
		subfinder -d $TARGET_URL | tee $DIRECTORY_PATH/subfinder.txt
	fi

	if check_command "amass"; then
		cat <<EOF
		"Running amass"
EOF
		# amass enum -d $TARGET_URL -silent
	fi

	if check_command "assetfinder"; then
		cat <<EOF
		"Running assetfinder"
EOF
		assetfinder -subs-only $TARGET_URL | tee $DIRECTORY_PATH/assetfinder.txt
	fi

	if check_command "gau"; then
		cat <<EOF
	  "Running gau"
EOF
		# gau
	fi

	if check_command "waybackurls"; then
		cat <<EOF
		"Running waybackurls"
EOF
		# echo "${TARGET_URL}" | waybackurls >>$DIRECTORY_PATH/waybackurls.txt
	fi
}

allurls() {
	cat $DIRECTORY_PATH/subfinder.txt $DIRECTORY_PATH/assetfinder.txt | sort | uniq >>$DIRECTORY_PATH/allurls.txt
}

enum
allurls

notify-send -i /home/$USERNAME/Sec/tools/akatsuki/assets/icons/logo.svg "Akatsuki" "Subdomain enumeration complete" && paplay /home/$USERNAME/Sec/tools/akatsuki/assets/sounds/alert.mp3
