#!/bin/bash

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env(){
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'SSH_KEY'
file_env 'GIT_REPO'

#add SSH_KEY
mkdir -p /root/.ssh && \
chmod 0700 /root/.ssh && \
echo "add bitbucket to known_hosts" && \
ssh-keyscan bitbucket.org > /root/.ssh/known_hosts && \
/usr/bin/printf "%s" "${SSH_KEY}" > /root/.ssh/id_rsa && \
chmod 600 /root/.ssh/id_rsa && \
echo "eval ssh-agent" && \
eval `ssh-agent -s` && \
printf "${SSH_KEY_PASSPHRASE}\n" | ssh-add $HOME/.ssh/id_rsa && \

#clone the repo
echo "clone repo : $GIT_REPO in folder app of $(pwd)" && \
printf "${SSH_KEY_PASSPHRASE}\n" | git clone $GIT_REPO app && \
cd app/client

echo "Repo cloned: $GIT_REPO";
echo "Currently working in directory: $(pwd)";

echo "Installing project dependencies..."
npm i
echo "Dependencies installed successfuly"
echo "Building project"
ng build
cp ./dist/. ../public

echo "dist folder is ready to be served"

#start app
cd ..
npm i
npm start