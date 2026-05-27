ARG ARCH=
#FROM ${ARCH}erseco/alpine-php-webserver:3.20

# For php84
FROM ${ARCH}erseco/alpine-php-webserver:3.23 

LABEL maintainer="Ernesto Serrano <info@ernesto.es>"

USER root
RUN apk add --no-cache graphviz ghostscript ghostscript-fonts poppler-utils aspell aspell-en python3 composer patch php84-posix php84-xmlwriter php84-pecl-redis php84-opcache\
    php84-ldap php84-pecl-igbinary php84-exif php84-xsl\
    # Remove alpine cache
    && rm -rf /var/cache/apk/*

# add a quick-and-dirty hack  to fix https://github.com/erseco/alpine-moodle/issues/26
RUN apk add --no-cache gnu-libiconv=1.15-r3 --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ --allow-untrusted \
    # Remove alpine cache
    && rm -rf /var/cache/apk/*
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# Moodle version configuration
ARG MOODLE_BRANCH=MOODLE_502_STABLE
ARG MOODLE_PGLS=AdrianoRuseler/moodle502-plugins

# Set default environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    SITE_URL=http://localhost \
    DB_TYPE=pgsql \
    MOODLE_DATABASE_TYPE= \
    DB_HOST=postgres \
    DB_PORT=5432 \
    DB_NAME=moodle \
    DB_USER=moodle \
    DB_PASS=moodle \
    DB_PREFIX=mdl_ \
    DB_DBHANDLEOPTIONS=false \
    REDIS_HOST= \
    REDIS_PASSWORD= \
    REDIS_USER= \
    REVERSEPROXY=false \
    SSLPROXY=false \
    MY_CERTIFICATES=none \
    MOODLE_EMAIL=user@example.com \
    MOODLE_LANGUAGE=en \
    MOODLE_SITENAME=Dockerized_Moodle \
    MOODLE_USERNAME=moodleuser \
    MOODLE_PASSWORD=PLEASE_CHANGEME \
    SMTP_HOST=smtp.gmail.com \
    SMTP_PORT=587 \
    SMTP_USER=your_email@gmail.com \
    SMTP_PASSWORD=your_password \
    SMTP_PROTOCOL=tls \
    MOODLE_MAIL_NOREPLY_ADDRESS=noreply@localhost \
    MOODLE_MAIL_PREFIX=[moodle] \
    AUTO_UPDATE_MOODLE=true \
    DEBUG=false \
    client_max_body_size=50M \
    post_max_size=50M \
    upload_max_filesize=50M \
    max_input_vars=5000 \
    memory_limit=256M \
    opcache_enable=1 \
    opcache_enable_cli=1 \
    opcache_memory_consumption=512 \
    opcache_interned_strings_buffer=64 \
    opcache_max_accelerated_files=60000 \
    opcache_validate_timestamps=1 \
    opcache_revalidate_freq=60 \
    opcache_save_comments=1 \
    opcache_enable_file_override=1 \
    opcache_jit=tracing \
    opcache_jit_buffer_size=128M

RUN set -eux; \
    # 1. Install Git temporarily
    apk add --no-cache --virtual .build-deps git curl tar jq xz; \
    \
    # 2. Clear default web root and clone official Moodle
    rm -rf /var/www/html/*; \
    git clone \
        --depth=1 \
        --branch "${MOODLE_BRANCH}" \
        https://github.com/moodle/moodle.git \
        /var/www/html; \
    \
    # 3. Create a temporary workshop directory for the plugins
    mkdir -p /tmp/moodle-source; \
    \
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$MOODLE_PGLS/releases/latest" | jq -r '.assets[] | select(.name | endswith(".tar.xz")) | .browser_download_url'); \
    \
    curl -Lk "$DOWNLOAD_URL" | tar -xJ -C /tmp/moodle-source --strip-components=1; \
    \
    # 5. Correctly merge the contents directly into Moodle root
    cp -rf /tmp/moodle-source/public/* /var/www/html/public/; \
    # cp -rf /tmp/moodle-source/* /var/www/html/; \
    # 6. Housekeeping: Wipe Git histories and temporary files to shrink image size
    rm -rf /var/www/html/.git; \
    rm -rf /tmp/moodle-source; \
    apk del .build-deps

COPY --chown=nobody rootfs/ /

USER nobody

#ENV MOOSH_URL=https://github.com/tmuras/moosh/archive/master.tar.gz
#RUN curl -L "$MOOSH_URL" | tar xz --strip-components=1 -C /opt/moosh/

#RUN composer install --no-interaction --no-cache --working-dir=/var/www/html/
