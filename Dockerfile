FROM ubuntu:18.04
MAINTAINER Mohammad Rahimzada

# Build Args
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV TERM=xterm\
    TZ=Europe/Berlin\
    DEBIAN_FRONTEND=noninteractive


# Update and install php
RUN apt update -y && apt install -y mc snmp apt-utils php apache2 php-pear git curl libssl1.0-dev nodejs-dev node-gyp npm wget mysql-client sed ca-certificates && apt clean


# Php modules
RUN apt-get install -y --no-install-recommends libapache2-mod-php7.2 \
    php7.2-bcmath \
    php7.2-bz2 \
    php7.2-cli \
    php7.2-common \
    php7.2-curl \
    php7.2-dba \
    php7.2-gd \
    php7.2-gmp \
    php7.2-imap \
    php7.2-intl \
    php7.2-ldap \
    php7.2-mbstring \
    php7.2-mysql \
    php7.2-odbc \
    php7.2-pgsql \
    php7.2-recode \
    php7.2-snmp \
    php7.2-soap \
    php7.2-sqlite \
    php7.2-tidy \
    php7.2-xml \
    php7.2-xmlrpc \
    php7.2-xsl \
    php7.2-zip \
    php-apcu


# Composer installation
RUN cd && \
    mkdir /tmp/composer/ && \
    cd /tmp/composer && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod a+x /usr/local/bin/composer && \
    cd / && \
    rm -rf /tmp/composer && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*


# Apache
RUN chown -R www-data:www-data /var/www && \
    apache2ctl -t && \
    mkdir -p /run /var/lib/apache2 /var/lib/php && \
    chown -R www-data:www-data /run /var/lib/apache2 /var/lib/php /etc/php/7.2/apache2/php.ini && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/7.2/apache2/php.ini
RUN a2enmod rewrite

# composer install
RUN cd /var/www/html && composer install --no-dev --optimize-autoloader && php bin/console cache:clear --env=dev --no-debug

# npm install
RUN npm install -g npm
RUN cd /var/www/html && npm install
RUN cd /var/www/html && ./node_modules/.bin/encore dev

# File and folder permissions
RUN cd /var/www/html && chown -R www-data:www-data var && chown -R www-data:www-data public

# Increase maximum upload file size to 10MB
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 5M/g' /etc/php/7.2/cli/php.ini

# Install vim editor tool
RUN apt update
RUN apt install -y vim

#
RUN apache2ctl -t

# Startup Script
COPY startup.sh /var/www/html/startup.sh
RUN chmod 755 /var/www/html/startup.sh

WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT ["./startup.sh"]

CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]