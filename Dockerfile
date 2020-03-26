FROM php:7.3

LABEL maintainer="yinjiajiu <1401128990@qq.com>" version="2.0"

# --build-arg timezone=Asia/Shanghai
ARG timezone
# default use www-data user
ARG work_user=www-data

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    PHPREDIS_VERSION=4.3.0 \
    SWOOLE_VERSION=4.4.12 \
    PROTOCOL_VERSION=3.11.4 \
    COMPOSER_ALLOW_SUPERUSER=1

# Libs -y --no-install-recommends
RUN apt-get update \
    && apt-get install -y \
        autoconf automake make g++ libtool curl wget git libzip-dev unzip less vim procps lsof tcpdump htop openssl \
        libz-dev \
        libssl-dev \
        libnghttp2-dev \
        libpcre3-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
# Install PHP extensions
    && docker-php-ext-install \
       bcmath gd pdo_mysql mbstring sockets zip sysvmsg sysvsem sysvshm exif gettext shmop

# Install composer
Run curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer self-update --clean-backups \
# Install redis extension
    && wget http://pecl.php.net/get/redis-${PHPREDIS_VERSION}.tgz -O /tmp/redis.tar.tgz \
    && pecl install /tmp/redis.tar.tgz \
    && rm -rf /tmp/redis.tar.tgz \
    && docker-php-ext-enable redis \
# Install swoole extension
    && wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-mysqlnd --enable-sockets --enable-openssl --enable-http2 \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole \
# Install protoBuf
    && wget https://pecl.php.net/get/protobuf-${PROTOCOL_VERSION}.tgz -O /tmp/protobuf.tar.tgz \
    && pecl install /tmp/protobuf.tar.tgz \
    && rm -rf /tmp/protobuf.tar.tgz \
    && docker-php-ext-enable protobuf \
# Clear dev deps
    && apt-get clean \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
# Timezone
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && echo "[Date]\ndate.timezone=${TIMEZONE}" > /usr/local/etc/php/conf.d/timezone.ini \

WORKDIR /var/www
EXPOSE 9501
