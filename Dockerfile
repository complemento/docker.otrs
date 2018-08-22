FROM ubuntu:16.04
MAINTAINER Complemento <https://www.complemento.net.br>

# Definitions
ENV OTRS_VERSION=6.0.10
ENV LIGERO_REPOSITORY=6.0.0

RUN apt-get update && \
    apt-get install -y supervisor \
    apt-utils \
    libterm-readline-perl-perl && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get install -y apache2 git bash-completion cron sendmail curl vim wget mysql-client

# CREATE OTRS USER
RUN useradd -d /opt/otrs -c 'OTRS user' otrs && \
    usermod -a -G www-data otrs && \
    usermod -a -G otrs www-data

RUN mkdir /opt/src && \
    cd /opt/src/ && \
    chown otrs:www-data /opt/src && \
    su -c "git clone -b rel-$(echo $OTRS_VERSION | sed --expression='s/\./_/g') \
    --single-branch https://github.com/OTRS/otrs.git" -s /bin/bash otrs

RUN sed -i -e "s/6.0.x git/${OTRS_VERSION}/g" /opt/src/otrs/RELEASE

COPY link.pl /opt/src/

RUN chmod 755 /opt/src/link.pl && \
    mkdir /opt/otrs && \
    chown otrs:www-data /opt/otrs

# perl modules
RUN apt-get install -y  libarchive-zip-perl \
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
                        libtemplate-perl \
                        libtemplate-perl \
                        libtext-csv-xs-perl \
                        libxml-libxml-perl \
                        libxml-libxslt-perl \
                        libxml-parser-perl \
                        libyaml-libyaml-perl


RUN /opt/src/otrs/bin/otrs.SetPermissions.pl --web-group=www-data

RUN ln -s /opt/src/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-available/otrs.conf && \
    a2ensite otrs && \
    a2dismod mpm_event && \
    a2enmod mpm_prefork && \
    a2enmod headers

# Supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup a cron for checking when OTRS is already installed, then start otrs Cron
COPY daemonstarter.sh /opt/src/
RUN chmod +x /opt/src/daemonstarter.sh
RUN echo "* * * * * /opt/src/daemonstarter.sh" | crontab -

COPY otrs.sh /opt/src/
RUN chmod 755 /opt/src/otrs.sh

RUN mkdir /opt/ligero_addons/ && chown otrs:www-data /opt/ligero_addons

ADD https://addons.ligerosmart.com/AddOns/6.0/Community/LigeroRepository/LigeroRepository-${LIGERO_REPOSITORY}.opm /opt/ligero_addons/

RUN chown otrs:www-data /opt/ligero_addons -R

EXPOSE 80

CMD ["/opt/src/otrs.sh"]
