FROM nginx:perl

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# install deps
RUN apt-get update \
    && apt-get install -y locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && apt-get install -y \
        git \
        bash-completion \
        cron \
        apt-utils curl \
        libfcgi-perl \
        libterm-readline-perl-perl \
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
        libnet-dns-perl \
        libnet-ldap-perl \
        libtemplate-perl \
        libtemplate-perl \
        libtext-csv-xs-perl \
        libxml-libxml-perl \
        libxml-libxslt-perl \
        libxml-parser-perl \
        libyaml-libyaml-perl \
        mysql-client \
        make gcc procps sudo \
        build-essential libtry-tiny-perl libyaml-perl \
    && apt-get autoclean

# CREATE OTRS USER
RUN useradd -d /opt/otrs -c 'OTRS user' otrs \
    && usermod -a -G www-data otrs \
    && usermod -a -G otrs www-data \
    && usermod -a -G nginx otrs \
    && usermod -a -G otrs nginx \
    && usermod -a -G www-data nginx 

# fastcgi
RUN git clone https://github.com/mdll/otrs-fcgi.git \
    && cp otrs-fcgi/bin/fastcgi-wrapper.pl /usr/local/bin/ \
    && chmod +x /usr/local/bin/fastcgi-wrapper.pl \
    && cp otrs-fcgi/init.d/otrs-fcgi /etc/init.d/ \
    && chmod +x /etc/init.d/otrs-fcgi \
    && mkdir /var/run/otrs/ \
    && chown www-data /var/run/otrs/

# OTRS code
RUN cd /opt/ && git clone -b rel-6_0 --single-branch https://github.com/OTRS/otrs.git \
    && /opt/otrs/bin/otrs.SetPermissions.pl


# Install Elasticsearch Module 
RUN export PERL_MB_OPT=; export PERL_MM_OPT=; export PERL_MM_USE_DEFAULT=1;perl -MCPAN -e 'install Search::Elasticsearch'

COPY otrs-nginx.conf /etc/nginx/conf.d/default.conf
COPY Config.pm /opt/otrs/Kernel/Config.pm
RUN chown otrs:nginx /opt/otrs/Kernel/Config.pm

VOLUME [ "/opt/otrs" ]

CMD /etc/init.d/otrs-fcgi start; nginx -g 'daemon off;'