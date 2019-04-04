FROM ubuntu:16.04

ENV OTRS_VERSION=6.0.17 \
    ITSM_VERSION=6.0.17 \
    FAQ_VERSION=6.0.17 \
    SURVEY_VERSION=6.0.11 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 

# Language
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && locale-gen pt_BR.UTF-8

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
        libexpat1-dev \
        libgdbm3 \
        libxml2-utils \
        libarchive-zip-perl \
        libcrypt-eksblowfish-perl \
        libcrypt-ssleay-perl \
        libtimedate-perl \
        libdatetime-perl \
        libdbi-perl \
        libdbd-mysql-perl \
        libdbd-odbc-perl \
        libdbd-pg-perl \
        libencode-hanextra-perl \
        libio-socket-ssl-perl \
        libjson-xs-perl \
        libmail-imapclient-perl \
        libio-socket-ssl-perl \
        libauthen-sasl-perl \
        libauthen-ntlm-perl \
        libapache2-mod-perl2 \
        libnet-dns-perl \
        libnet-ldap-perl \
        libssl-dev \
        libtemplate-perl \
        libtemplate-perl \
        libtext-csv-xs-perl \
        libxml-libxml-perl \
        libxml-libxslt-perl \
        libxml-parser-perl \
        libyaml-libyaml-perl \
        libterm-readline-perl-perl \
        mysql-client \
        postgresql-client \
        perl \
        supervisor \
        sudo \
        unzip \
        zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

# Extra perl modules
RUN curl -L https://cpanmin.us | perl - --sudo App::cpanminus \
    && cpanm --sudo --quiet --notest \ 
            Cache::Memcached::Fast \
            Plack \
            Search::Elasticsearch

# OTRS code
RUN cd /opt \
    && git clone -b rel-$(echo $OTRS_VERSION | sed --expression='s/\./_/g') \
        --single-branch https://github.com/OTRS/otrs.git otrs

WORKDIR /opt/otrs

# include files
COPY Config.pm /opt/otrs/Kernel/Config.pm
COPY app-env.conf /etc/apache2/conf-available/app-env.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# post configuration
SHELL ["/bin/bash", "-c"]
RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-available/otrs.conf \
    && a2ensite otrs \
    && a2dismod mpm_event \
    && a2enmod mpm_prefork \
    && a2enmod headers \
    && a2enmod perl \
    && a2enconf app-env \
    && sed -i -e "s/6.0.x git/${OTRS_VERSION}/g" /opt/otrs/RELEASE \
    && mv var/cron/aaa_base.dist var/cron/aaa_base \
    && mv var/cron/otrs_daemon.dist var/cron/otrs_daemon \
    && useradd -d /opt/otrs -c 'OTRS user' otrs \
    && usermod -a -G www-data otrs \
    && usermod -a -G otrs www-data \
    && mkdir -p /var/log/supervisor \
                /opt/otrs/var/article \ 
                /opt/otrs/var/spool \
                /opt/otrs/var/tmp \
                /opt/otrs/var/packages \
    && bin/otrs.SetPermissions.pl --web-group=www-data \
    && su otrs -c "~/bin/Cron.sh start" \
    && echo "source /etc/profile.d/bash_completion.sh" >> .bashrc \
    && chmod +x .bashrc

# AddOns opm
RUN cd /opt/otrs/var/packages \
    && curl -O http://ftp.otrs.org/pub/otrs/itsm/packages${OTRS_VERSION:0:1}/GeneralCatalog-${OTRS_VERSION}.opm \
    && curl -O http://ftp.otrs.org/pub/otrs/itsm/bundle${OTRS_VERSION:0:1}/ITSM-${ITSM_VERSION}.opm \
    && curl -O http://ftp.otrs.org/pub/otrs/packages/FAQ-${FAQ_VERSION}.opm \
    && curl -O http://ftp.otrs.org/pub/otrs/packages/Survey-${SURVEY_VERSION}.opm

CMD supervisord
