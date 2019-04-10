FROM alpine:3.9
MAINTAINER Thomas Schwery <thomas@inf3.ch>

RUN apk add --no-cache --virtual .fetch-deps \
        nginx php7-fpm php7-mcrypt  php7-pcntl php7-openssl \
        php7-gmp php7-pdo_odbc php7-json php7-dom php7-pdo php7-zip \
        php7-pgsql php7-pdo_pgsql php7-bcmath php7-gd php7-odbc \
        php7-gettext php7-xmlreader php7-xmlrpc \
        php7-bz2 php7-iconv php7-pdo_dblib php7-posix \
        php7-curl php7-ctype php7-mbstring php7-fileinfo php7-session php7 curl supervisor

# add ttrss as the only nginx site
ADD conf/ttrss.nginx.conf /etc/nginx/sites-available/ttrss
RUN rm /etc/nginx/conf.d/default.conf && ln -s /etc/nginx/sites-available/ttrss /etc/nginx/conf.d/default.conf

# install ttrss and patch configuration
WORKDIR /var/www
RUN curl -SL https://git.tt-rss.org/fox/tt-rss/archive/master.tar.gz | tar xzC /var/www --strip-components 1 \
    && chown root:www-data -R /var/www
RUN cp config.php-dist config.php

RUN mkdir /run/nginx && chown nginx:www-data -R /run/nginx

ADD conf/php7-fpm.conf /etc/php7/php-fpm.d/default.conf

# expose only nginx HTTP port
EXPOSE 80

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD configure-db.php /configure-db.php
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD php7 /configure-db.php && supervisord -c /etc/supervisor/conf.d/supervisord.conf
