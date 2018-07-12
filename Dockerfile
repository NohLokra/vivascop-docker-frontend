FROM nginx:latest

COPY entrypoint.sh /usr/local/bin/

RUN chmod 777 /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
