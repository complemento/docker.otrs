FROM ubuntu:16.04
MAINTAINER Complemento <https://www.complemento.net.br>

# Definitions
ENV OTRS_VERSION=6.0.1

RUN apt-get update && \
    apt-get install -y apt-utils libterm-readline-perl-perl && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get install -y apache2 git bash-completion cron

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
    chown otrs:www-data /opt/otrs && \
    su -c "/opt/src/link.pl /opt/src/otrs /opt/otrs" -s /bin/bash otrs

# Create missing directories from GIT
RUN mkdir /opt/otrs/var/tmp && \
    chown otrs:www-data /opt/otrs/var/tmp && \
    mkdir otrs:www-data /opt/otrs/var/article

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


RUN rm /opt/otrs/bin/otrs.SetPermissions.pl && \
    cp /opt/src/otrs/bin/otrs.SetPermissions.pl /opt/otrs/bin/otrs.SetPermissions.pl && \
    cd /opt/otrs/; /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data

RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-available/otrs.conf && \
    a2ensite otrs


COPY otrs.sh /opt/src/
RUN chmod 755 /opt/src/otrs.sh

EXPOSE 80
ENTRYPOINT ["/opt/src/otrs.sh"]
CMD ["/opt/src/otrs.sh"]

