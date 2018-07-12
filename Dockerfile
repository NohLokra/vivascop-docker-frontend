FROM node:8.9.4

COPY entrypoint.sh /usr/local/bin/

RUN chmod 777 /usr/local/bin/entrypoint.sh

RUN apt-get update
RUN apt-get install curl git ssh

RUN npm i -g @angular/cli@1.7.4

# npm config set user 0
# npm config set unsafe-perm true

ENTRYPOINT ["entrypoint.sh"]
