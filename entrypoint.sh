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

echo "Installing SSH and Curl since they are needed for our business"
apt-get update && apt-get install -y ssh curl
echo "Installations complete"

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

# Setup node and Angular
echo "Installing NVM...";
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

echo "NVM installed and environment variables set"

echo "Installing Node version 8.9.4"
nvm install 8.9.4
nvm use 8.9.4
echo "Node v8.9.4 now installed and set as the default used version";

#clone the repo
echo "clone repo : $GIT_REPO in folder app of $(pwd)" && \
printf "${SSH_KEY_PASSPHRASE}\n" | git clone $GIT_REPO app && \
cd app && \
printf "${SSH_KEY_PASSPHRASE}\n" | git submodule update --init --recursive --remote --merge

echo "Repo cloned into app of $(pwd): $GIT_REPO";

echo "Currently working in directory: $(pwd)";
echo "Moving to app";
cd app;

#install node app
npm i -g @angular/cli@1.7.4
npm i
ng build

mkdir -p /app/
cp -r ./dist/. /app/
cp ./docker/nginx.default.conf /etc/nginx/conf.d/default.conf

#start app
npm run dev
