FROM nginx:alpine-perl

ENV OTRS_VERSION=6.0.26 \
    ITSM_VERSION=6.0.26 \
    FAQ_VERSION=6.0.24 \
    SURVEY_VERSION=6.0.17 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/otrs/bin

RUN deluser xfs \
    && delgroup www-data \
    && addgroup -g 33 www-data \
    && adduser otrs -D -G www-data \
    && sed -i 's/nginx:x:101:101/nginx:x:101:33/' /etc/passwd \
    && sed -i 's/user  nginx;/user  nginx www-data;/' /etc/nginx/nginx.conf \
    && apk add \
        bash \
        build-base \
        curl \
        expat-dev \
        git \
        graphviz \
        libpq \
        mysql-client \
        openssh-client \
        openssl \
        openssl-dev \
        perl-app-cpanminus \
        perl-crypt-ssleay \
        perl-dbd-mysql \
        perl-dbi \
        perl-dev \
        perl-xml-libxslt \
        postgresql-client \
        postgresql-dev \
        sudo \
        supervisor \
        unixodbc-dev \
        unzip \
        wget \
        vim \
        zip \
        zlib \
        zlib-dev \
    && cpanm --notest \
        Archive::Tar \
        Archive::Zip \
        Authen::NTLM \
        Authen::SASL \
        Cache::Memcached::Fast \
        CGI::Compile \
        CGI::Emulate::PSGI \
        Crypt::Eksblowfish::Bcrypt \
        Crypt::SSLeay Date::Format \
        DateTime DBI \
        DBD::mysql \
        DBD::ODBC \
        DBD::Pg \
        Devel::NYTProf \
        Digest::SHA \
        Encode::HanExtra \
        HTML::Entities \
        HTTP::Server::Brick \
        IO::Socket::SSL \
        IO::Socket::SSL \
        JSON::XS \
        List::Util::XS \
        LWP::UserAgent \
        Mail::IMAPClient \
        Module::Refresh \
        Net::DNS \
        Net::LDAP \
        Plack \
        Search::Elasticsearch \
        Starman \
        Template \
        Template::Stash::XS \
        Text::CSV_XS \
        Time::HiRes \
        XML::LibXML \
        XML::Parser \
        YAML::XS \
    && apk del \
        build-base \
        expat-dev \
        openssl-dev \
        perl-dev \
        unixodbc-dev \
        zlib-dev

SHELL ["/bin/bash", "-c"]

# OTRS code
RUN mkdir /opt/otrs \
    && cd /opt \
    && curl --silent -O https://ftp.otrs.org/pub/otrs/otrs-latest-${OTRS_VERSION%.*}.tar.gz \
    && tar zxpf otrs-latest-${OTRS_VERSION%.*}.tar.gz -C /opt/otrs --strip-components=1 \
    && rm -rf otrs-latest-${OTRS_VERSION%.*}.tar.gz \
    && mkdir -p /opt/otrs/var/article \ 
                /opt/otrs/var/spool \
                /opt/otrs/var/tmp \
                /app-packages \
                /var/www \
    && cd /app-packages \
    && curl --silent -O https://ftp.otrs.org/pub/otrs/itsm/bundle${OTRS_VERSION:0:1}/ITSM-${ITSM_VERSION}.opm \
    && curl --silent -O https://ftp.otrs.org/pub/otrs/packages/FAQ-${FAQ_VERSION}.opm \
    && curl --silent -O https://ftp.otrs.org/pub/otrs/packages/Survey-${SURVEY_VERSION}.opm

WORKDIR /opt/otrs

# include files
COPY etc /etc
COPY opt /opt
COPY var /var
COPY app-init.sh /app-init.sh
COPY app-run.sh /app-run.sh
COPY app-healthcheck.sh /app-healthcheck.sh
COPY app.psgi /app.psgi


# post configuration
RUN sed -i -e "s/${OTRS_VERSION%.*}.x git/${OTRS_VERSION}/g" /opt/otrs/RELEASE \
    && mv var/cron/otrs_daemon.dist var/cron/otrs_daemon \
    && echo '0 2 * * * /opt/otrs/scripts/backup.pl -d /app-backups -r 15' > var/cron/app-backups \
    && sed -i 's|$HOME/bin/otrs.Daemon.pl|. /etc/profile.d/app-env.sh; /opt/otrs/bin/otrs.Daemon.pl|' var/cron/otrs_daemon \
    && echo "PATH=\"$PATH:/opt/otrs/bin\"" > /etc/environment \
    && echo ". /etc/environment" > /opt/otrs/.profile \
    && echo "otrs ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/otrs \
    && chown otrs:www-data -R /opt/otrs \
    && chmod 775 -R /opt/otrs \
    && bin/Cron.sh start otrs \
    && chmod +x /*.sh \
    && mkdir /app-init.d/ \
    && mkdir /app-backups/ \
    && chown otrs:www-data /app-backups /var/www/html/* 

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=20s --retries=2 --start-period=1m CMD /app-healthcheck.sh

# default env values for services
ENV START_FRONTEND=1 \
    START_BACKEND=1 \
    START_PLACKUP=1 \
    DEBUG_MODE=0

CMD /app-run.sh
