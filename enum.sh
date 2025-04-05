#!/bin/bash

read -r -p "Enter target's name (working directory) : " TARGET_NAME

USERNAME=$(whoami)
AKATSUKI_PATH=/home/${USERNAME}/Sec/tools/akatsuki
PROJECT_PATH=/home/${USERNAME}/Sec/BugBounty/${TARGET_NAME}/enum

if ! [ -d ${PROJECT_PATH} ]; then
	mkdir -p ${PROJECT_PATH}
fi

getvalidurl() {
	while true; do

		read -r -p "Enter target url with http* : " FULL_TARGET_URL

		if [[ "${FULL_TARGET_URL}" =~ ^https?:// ]]; then
			TARGET_URL="${FULL_TARGET_URL#http://}"
			TARGET_URL="${FULL_TARGET_URL#https://}"

			break
		else
			echo "The URL must start with 'http://' or 'https://'"
		fi
	done

}

getvalidurl

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
		subfinder -d ${TARGET_URL} | tee ${PROJECT_PATH}/subfinder.txt
	fi

	if check_command "amass"; then
		cat <<EOF
		"Running amass"
EOF
		# amass enum -d ${TARGET_URL} -silent
	fi

	if check_command "assetfinder"; then
		cat <<EOF
		"Running assetfinder"
EOF
		assetfinder -subs-only ${TARGET_URL} | tee ${PROJECT_PATH}/assetfinder.txt
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
		# echo "${TARGET_URL}" | waybackurls >>${PROJECT_PATH}/waybackurls.txt
	fi
}

allurls() {
	cat ${PROJECT_PATH}/subfinder.txt ${PROJECT_PATH}/assetfinder.txt | sort | uniq >${PROJECT_PATH}/allurls.txt
}

liveurls() {
	httpx -l ${PROJECT_PATH}/allurls.txt -sc | awk '
  {print $0 > "'"${PROJECT_PATH}"'/httpxall.txt"}
  
  /503/ {print $1 > "'"${PROJECT_PATH}"'/503.txt"}
  /404/ {print $1 > "'"${PROJECT_PATH}"'/404.txt"}
  /403/ {print $1 > "'"${PROJECT_PATH}"'/403.txt"}
  /401/ {print $1 > "'"${PROJECT_PATH}"'/401.txt"}
  /302/ {print $1 > "'"${PROJECT_PATH}"'/302.txt"}
  /301/ {print $1 > "'"${PROJECT_PATH}"'/301.txt"}
  /200/ {print $1 > "'"${PROJECT_PATH}"'/200.txt"}
  
  !/404/ {print $1 > "'"${PROJECT_PATH}"'/liveurls.txt"} 
'
}

enum
allurls
liveurls

echo ${AKATSUKI_PATH}

notify-send -i ${AKATSUKI_PATH}/assets/icons/logo.svg "Akatsuki" "Subdomain enumeration complete" && paplay ${AKATSUKI_PATH}/assets/sounds/alert.mp3
