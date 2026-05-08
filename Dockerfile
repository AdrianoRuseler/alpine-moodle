ARG ARCH=
#FROM ${ARCH}erseco/alpine-php-webserver:3.20

# For php84
FROM ${ARCH}erseco/alpine-php-webserver:3.23 

LABEL maintainer="Ernesto Serrano <info@ernesto.es>"

USER root
RUN apk add --no-cache composer patch php84-posix php84-xmlwriter php84-pecl-redis \
    php84-ldap php84-pecl-igbinary php84-exif \
    # Remove alpine cache
    && rm -rf /var/cache/apk/*

# add a quick-and-dirty hack  to fix https://github.com/erseco/alpine-moodle/issues/26
RUN apk add --no-cache gnu-libiconv=1.15-r3 --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ --allow-untrusted \
    # Remove alpine cache
    && rm -rf /var/cache/apk/*
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# Moodle version configuration
ARG MOODLE_BRANCH=MOODLE_502_STABLE

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
    memory_limit=256M

# Install git temporarily, clone Moodle, then remove git
RUN set -eux; \
    apk add --no-cache --virtual .build-deps git && \
    rm -rf /var/www/html/* && \
    git clone \
        --depth=1 \
        --branch "${MOODLE_BRANCH}" \
        https://github.com/moodle/moodle.git \
        /var/www/html && \
    rm -rf /var/www/html/.git && \
    apk del .build-deps

COPY --chown=nobody rootfs/ /

USER nobody

#ENV MOOSH_URL=https://github.com/tmuras/moosh/archive/master.tar.gz
#RUN curl -L "$MOOSH_URL" | tar xz --strip-components=1 -C /opt/moosh/

RUN composer install --no-interaction --no-cache --working-dir=/var/www/html/
