FROM ubuntu:16.04

ENV OTRS_VERSION=6.0.30 \
    ITSM_VERSION=6.0.30 \
    FAQ_VERSION=6.0.28 \
    SURVEY_VERSION=6.0.20 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/otrs/bin

SHELL ["/bin/bash", "-c"]

# Language
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=${LANG}

# Packages
RUN apt-get update \
    && apt-get install -y \
        apache2 \
        bash-completion \
        build-essential \
        cron \
        curl \
        gettext \
        git-core \
        graphviz \
        libapache2-mod-perl2 \
        libarchive-zip-perl \
        libauthen-ntlm-perl \
        libauthen-sasl-perl \
        libcrypt-eksblowfish-perl \
        libcrypt-ssleay-perl \
        libdatetime-perl \
        libdbd-mysql-perl \
        libdbd-odbc-perl \
        libdbd-pg-perl \
        libdbi-perl \
        libencode-hanextra-perl \
        libexpat1-dev \
        libgdbm3 \
        libgraphviz-perl \
        libio-socket-ssl-perl \
        libjson-xs-perl \
        libmail-imapclient-perl \
        libnet-dns-perl \
        libnet-ldap-perl \
        libredis-perl \
        libssl-dev \
        libswitch-perl \
        libtemplate-perl \
        libterm-readline-perl-perl \
        libtext-csv-xs-perl \
        libtimedate-perl \
        libxml-libxml-perl \
        libxml-libxslt-perl \
        libxml-parser-perl \
        libxml2-utils \
        libyaml-libyaml-perl \
        lynx \
        mysql-client \
        perl \
        postgresql-client \
        sendmail \
        ssh \
        sudo \
        supervisor \
        tzdata \
        unzip \
        vim \
        zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

# Extra perl modules
RUN curl --silent -L https://cpanmin.us | perl - --sudo App::cpanminus \
    && cpanm --sudo --quiet --notest \ 
            Cache::Memcached::Fast \
            DateTime::TimeZone \
            HTTP::Server::Brick \
            Plack \
            Redis \
            Redis::Fast \
            Search::Elasticsearch@7.30 

# set otrs user
RUN useradd -d /opt/otrs -c 'OTRS user' -g www-data -s /bin/bash otrs \
    && usermod -a -G tty www-data 
    
WORKDIR /opt/otrs

# include files
COPY --chown=otrs:www-data opt /opt
COPY --chown=otrs:www-data var /var
COPY --chown=otrs:www-data app-backups /app-backups
COPY etc /etc
COPY usr /usr
COPY app-packages /app-packages
COPY app-init.d /app-init.d
COPY app-init.sh /app-init.sh
COPY app-run.sh /app-run.sh
COPY app-healthcheck.sh /app-healthcheck.sh

# OTRS code
RUN cd /opt \
    && curl --fail --silent --remote-name https://github.com/OTRS/otrs/archive/rel-6_0_30.tar.gz \
    && tar zxpf rel-6_0_30.tar.gz -C /opt/otrs --strip-components=1 \
    && rm -rf rel-6_0_30.tar.gz \
    && mkdir -p /opt/otrs/var/article \ 
                /opt/otrs/var/spool \
                /opt/otrs/var/tmp \
    && chown otrs:www-data -R /opt/otrs \
    && chmod 775 -R /opt/otrs

# post configuration
RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-available/otrs.conf \
    && a2dismod mpm_event \
    && a2enmod mpm_prefork headers perl include \
    && a2enconf otrs custom-config app-env \
    && sed -i -e "s/${OTRS_VERSION%.*}.x git/${OTRS_VERSION}/g" /opt/otrs/RELEASE \
    && echo "PATH=\"$PATH:/opt/otrs/bin\"" > /etc/environment \
    && echo ". /etc/environment" > /opt/otrs/.profile \
    && echo "otrs ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/otrs \
    && mkdir -p /var/log/supervisor \
    && chmod +x /*.sh \
    && chmod 775 -R /opt/otrs \
    && mkdir /var/run/sshd \
    && rm /etc/update-motd.d/* \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stdout /var/log/apache2/error.log \
    && sed -i 's/access.log combined/access.log combined env=!dontlog/' /etc/apache2/sites-available/*

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=20s --retries=2 --start-period=1m CMD /app-healthcheck.sh

# default env values for services
ENV START_FRONTEND=1 \
    START_BACKEND=1 \
    START_SSHD=0 \
    DEBUG_MODE=0

CMD /app-run.sh
