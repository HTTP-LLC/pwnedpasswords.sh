#!/bin/bash

usage()
{
echo
echo "[+] Printing Help"
echo

printf "%b" "
This is a simple bash script for searching Troy Hunt's pwnedpassword API using the k-anonymity algorithm

Usage

  $0 [options] PASSWORD

Options:

    -h, --help    Shows this message

Arguments:

	PASSWORD    Provide the password as the first argument or leave blank to provide via STDINT or prompt

"
}

pre_requisites()
{
# Check For Curl Command
	if ! [ -x "$(command -v curl)" ]; then
		echo "[-] ERROR: curl is required, please install curl."
		exit 1
	fi

# Check For Sha1sum || shasum Command (Wasnt On Mac By Default When Testing)
	if [ -x "$(command -v sha1sum)" ]; then
		sha="sha1sum"
	elif [ -x "$(command -v sha1sum)" ]; then
		sha="shasum"
	else
		echo "[-] ERROR: sha1sum or shasum is required, please install sha1sum or shasum."
		exit 1
	fi

}

pwned_password()
{
	local password sha1 short_sha1 sha1_suffix http_status http_body http_response
	password="$1"
	sha1=$(echo -n "$password" | $sha | awk '{print toupper($1)}')
	short_sha1=${sha1:0:5}
	sha1_suffix=${sha1:5}

	http_response=$(curl -s -w "\nHTTPSTATUS:%{http_code}\n" "https://api.pwnedpasswords.com/range/${short_sha1}")
	http_body="$(echo "$http_response" | sed '$d')"
	http_status=$(echo "$http_response" | tail -1 | sed -e 's/.*HTTPSTATUS://')

	if [ ! "$http_status" -eq 200 ]; then
	  echo "Error [HTTP status: $http_status]"
	  return 1
	fi

	MATCHES=$(echo "${http_body}" | grep "${sha1_suffix}" | awk -F ':' '{print $2}' | tr -d '[:space:]')
	return 0
}

clear
echo
echo "[*] Checking Prerequisites..."
pre_requisites
echo "[+] Prerequisites Check Complete..."
echo
echo "[*] Checking Arguments...."

# If Arguments Are Passed Then Check If Help Flag Is Used Else Set PASSWORD To The First Argument
# If No Arguments Are Passed Prompt User For Password If Empty Exit
if [ $# -gt '0' ]; then
	if [ $1 == '-h' ] || [ $1 == '--h' ] || [ $1 == '-help' ] || [ $1 == '--help' ]; then
		usage
		exit 0
	else
		PASSWORD="$1"
		echo "[+] Arguments Check Complete..."
	fi
else
	echo "[~] Arguments Not Found..."
	read -s -p "Please Enter Password -> " PASSWORD
	echo
	if [ -z "$PASSWORD" ]; then
		echo "[-] ERROR: Input Not Found.... Exiting"
		exit 9
	fi
	echo "[+] Arguments Check Complete..."
fi

pwned_password "${PASSWORD}"

if [ -z "$MATCHES" ]; then
	echo
	echo "[+] This password has not appeared in any data breaches!"
	echo
	exit 0
else
	echo
	echo "[!] This password has appeared ${MATCHES} times in data breaches."
	exit 2
	echo
fi
