FROM alpine
MAINTAINER Thomas Schwery <thomas@inf3.ch>

RUN apk add --no-cache --virtual .fetch-deps \
        nginx php5-fpm php5-mcrypt  php5-pcntl php5-openssl \
        php5-gmp php5-pdo_odbc php5-json php5-dom php5-pdo php5-zip \
        php5-pgsql php5-pdo_pgsql php5-bcmath php5-gd php5-odbc \
        php5-gettext php5-xmlreader php5-xmlrpc \
        php5-bz2 php5-iconv php5-pdo_dblib php5-posix \
        php5-curl php5-ctype curl supervisor

# add ttrss as the only nginx site
ADD conf/ttrss.nginx.conf /etc/nginx/sites-available/ttrss
RUN rm /etc/nginx/conf.d/default.conf && ln -s /etc/nginx/sites-available/ttrss /etc/nginx/conf.d/default.conf

# install ttrss and patch configuration
WORKDIR /var/www
RUN curl -SL https://tt-rss.org/gitlab/fox/tt-rss/repository/archive.tar.gz?ref=master | tar xzC /var/www --strip-components 1 \
    && chown root:www-data -R /var/www
RUN cp config.php-dist config.php

RUN mkdir /run/nginx && chown nginx:www-data -R /run/nginx

ADD conf/php5-fpm.conf /etc/php5/fpm.d/default.conf

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
CMD php5 /configure-db.php && supervisord -c /etc/supervisor/conf.d/supervisord.conf
