FROM debian:jessie

MAINTAINER Anthony K GROSS

RUN apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y php5-common php5-cli php5-fpm php5-mcrypt php5-mysql php5-apcu php5-gd php5-imagick php5-curl php5-intl php5-ldap php5-pgsql npm curl git supervisor nginx

RUN rm -rf /var/lib/apt/lists/* && apt-get autoremove -y --purge
RUN usermod -u 1000 www-data

# Installation de Node.js à partir du site officiel
RUN curl -LO "https://nodejs.org/dist/v0.12.5/node-v0.12.5-linux-x64.tar.gz" 
RUN tar -xzf node-v0.12.5-linux-x64.tar.gz -C /usr/local --strip-components=1
RUN rm node-v0.12.5-linux-x64.tar.gz

RUN rm -rf /var/lib/apt/lists/* && apt-get autoremove -y --purge

RUN npm install -g bower
RUN npm install -g gulp
RUN npm install -g less jshint recess uglify-js

WORKDIR /home/ftp/fr/lam/cram/html/

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
