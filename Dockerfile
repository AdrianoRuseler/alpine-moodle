ARG ARCH=

# For php84, we use the latest alpine-php-webserver image which includes PHP 8.4 and is based on Alpine Linux. This image provides a lightweight and secure environment for running Moodle with PHP 8.4.
FROM ${ARCH}ruseler/alpine-php-webserver:php84

LABEL maintainer="Adriano Ruseler <ruseler@utfpr.edu.br>" \
      description="Alpine Linux image with Moodle and PHP 8.4" \
      version="5.2"

USER root
RUN apk add --no-cache graphviz ghostscript ghostscript-fonts poppler-utils aspell aspell-en python3 composer patch gnu-libiconv \
    # Remove alpine cache
    && rm -rf /var/cache/apk/*

# Environment variable for iconv fix
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# Moodle version configuration
ARG MOODLE_BRANCH=MOODLE_502_STABLE
ARG MOODLE_PGLS=AdrianoRuseler/moodle502-plugins
#ARG MOODLE_PGLS=""

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
    MOODLE_EMAIL=admin@host.docker.internal \
    MOODLE_LANGUAGE=en \
    MOODLE_SITENAME=Dockerized_Moodle \
    MOODLE_USERNAME=admin \
    MOODLE_PASSWORD=M@0dl3ing \
    SMTP_HOST=smtp.host.docker.internal \
    SMTP_PORT=587 \
    SMTP_USER=your_email@host.docker.internal \
    SMTP_PASSWORD=your_password \
    SMTP_PROTOCOL=tls \
    MOODLE_MAIL_NOREPLY_ADDRESS=noreply@host.docker.internal \
    MOODLE_MAIL_PREFIX=[moodle] \
    AUTO_UPDATE_MOODLE=true \
    RUN_CRON_TASKS=true \
    DEBUG=false

RUN set -eux; \
    # Install Git temporarily
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
    # Check and download custom plugins if variable is set
    if [ -n "${MOODLE_PGLS:-}" ]; then \
        mkdir -p /tmp/moodle-source; \
        \
        DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$MOODLE_PGLS/releases/latest" | jq -r '.assets[] | select(.name | endswith(".tar.xz")) | .browser_download_url'); \
        \
        if [ "$DOWNLOAD_URL" != "null" ] && [ -n "$DOWNLOAD_URL" ]; then \
            curl -Lk "$DOWNLOAD_URL" | tar -xJ -C /tmp/moodle-source --strip-components=1; \
            \
            # FIXED: Corrected destination path. 
            # Assuming your release zip has a 'public' folder containing the plugins:
            if [ -d "/tmp/moodle-source/public" ]; then \
                cp -rf /tmp/moodle-source/public/* /var/www/html/; \
            else \
                cp -rf /tmp/moodle-source/* /var/www/html/; \
            fi; \
        fi; \
        rm -rf /tmp/moodle-source; \
    fi; \
    \
    # Install Moosh from GitHub (2.x Branch)
    git clone -b 2.x --depth=1 https://github.com/tmuras/moosh.git /opt/moosh; \
    cd /opt/moosh; \
    composer install --no-dev --no-interaction --no-cache; \
    ln -s /opt/moosh/moosh /usr/local/bin/moosh; \
    \
    # Housekeeping: Wipe Git histories and temporary files to shrink image size
    rm -rf /var/www/html/.git /opt/moosh/.git; \   
    apk del .build-deps

COPY --chown=nobody rootfs/ /

RUN echo "alias moosh='moosh --moodle-path=/var/www/html/public'" >> /etc/profile.d/moosh.sh
USER nobody
