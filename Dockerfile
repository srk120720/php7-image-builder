FROM php:7.4-fpm

ARG time_zone=Asia/Seoul
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure -f noninteractive locales \
    && update-locale LANG=en_US.UTF-8

ENV DEBCONF_NOWARNINGS yes
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV TZ=$time_zone
RUN ln -fs /usr/share/zoneinfo/$time_zone /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

RUN apt-get install -y \
    apt-utils \
    libpng-dev \
    libonig-dev \
    libzip-dev \
    curl \
    zip \
    unzip \
    cron \
    vim \
    procps \
    net-tools \
    nginx \
    supervisor

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip opcache

RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN sed -ri "s/post_max_size = 8M/post_max_size = 128M/g" "$PHP_INI_DIR/php.ini"
RUN sed -ri "s/upload_max_filesize = 2M/upload_max_filesize = 32M/g" "$PHP_INI_DIR/php.ini"
RUN sed -ri "s/memory_limit = 128M/memory_limit = 256M/g" "$PHP_INI_DIR/php.ini"

RUN echo 'opcache.enable=1 \n\
opcache.enable_cli=1 \n\
opcache.memory_consumption=512 \n\
opcache.interned_strings_buffer=64 \n\
opcache.max_accelerated_files=32531 \n\
opcache.validate_timestamps=0 \n\
opcache.save_comments=1 \n\
opcache.fast_shutdown=0' >> "$PHP_INI_DIR/conf.d/10-opcache.ini"

ARG php_fpm_conf=/usr/local/etc/php-fpm.d/www.conf
RUN sed -ri "s/pm.max_children = 5/pm.max_children = 50/g" $php_fpm_conf
RUN sed -ri "s/pm.start_servers = 2/pm.start_servers = 20/g" $php_fpm_conf
RUN sed -ri "s/pm.min_spare_servers = 1/pm.min_spare_servers = 10/g" $php_fpm_conf
RUN sed -ri "s/pm.max_spare_servers = 3/pm.max_spare_servers = 30/g" $php_fpm_conf
RUN sed -ri "s/pm.max_requests = 500/pm.max_requests = 5000/g" $php_fpm_conf
RUN sed -ri "s/;request_terminate_timeout = 0/request_terminate_timeout = 30/g" $php_fpm_conf

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www
