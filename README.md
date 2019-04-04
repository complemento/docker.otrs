
[![N|Solid](https://i1.wp.com/complemento.net.br/wp-content/uploads/2017/11/logo_otrs6free.png?fit=300%2C68&ssl=1)]()

OTRS Docker Installation
========================
## Default OTRS username and password of this Image

Username: root@localhost
Password: ligero

## What's OTRS?

OTRS is the world most popular Service Desk software, delivered by OTRS Group and a large open source community. You can check more information and all OTRS Group Services in their web site:
http://www.otrs.com

This Docker image is maintained by Complemento, a Brazilian company dedicate to delivery ITSM with open source software. We develop many Free and Enterprise AddOns for OTRS. You can check our website for more information:
http://www.complemento.net.br

## About this Image

This image aims to make a fresh new application install of OTRS. You will need to create another MySQL container for your own **or use our docker-compose file**.

## Running this Image

You can run this image in 2 different ways: with docker-compose, creating a stack with OTRS and MySQL with a default installation done, or without docker-compose, running a standalone container and finishing OTRS installation through it's web interface by your own.

First of all, please Install your docker server in case you haven't done yet. You can download Docker Community Edition from this link: 
	https://www.docker.com/community-edition#/download

Now, choose the way you want to run this image:

### Using docker-compose
If you choose this way, please make sure you have installed docker-compose:
https://docs.docker.com/compose/install/#install-compose

Download the docker-compose.yaml file from our github, to some folder of your preference. 

Let's suppose you want to put it under /opt/containers/otrs:

`mkdir -p /opt/containers/otrs`

`cd /opt/containers/otrs`

`wget https://raw.githubusercontent.com/complemento/docker.otrs/master/docker-compose.yaml`

If you want to install AddOns during the Stack startup, you can create an otrs_addons folder under this directory and put the AddOns there. For example, if you want to install FAQ and OTRS ITSM:

`mkdir otrs_addons`

`cd otrs_addons`

`wget ftp://ftp.otrs.org/pub/otrs/itsm/bundle6/ITSM-6.0.9.opm`

`wget ftp://ftp.otrs.org/pub/otrs/packages/FAQ-6.0.8.opm`

Then go back to the stack folder:

`cd /opt/containers/otrs`

And finally, run your Stack!

`docker-compose up -d`

Then you can check if the system could start by it self:

`docker-compose logs -f otrs`

When you see this message on the log:
*INFO success: apache2 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)*

It's because the system is running and you can access it.

You can discover the container IP using the following command:

`docker-compose exec otrs ip a`

And then you can access the system in your web browser:

http://CONTAINER_IP/otrs/index.pl

Username: root@localhost
Password: ligero

#### Docker-compose Variables

You can edit your docker-compose.yaml and adapt to your reallity

| VARIABLE | Default | DESCRIPTION  |
|--|--|--|
| CUSTOMER_ID | ligero | Used for setting database name and other options |
| OTRS_SYSTEM_ID | 10 | SystemID of OTRS |
| OTRS_DEFAULT_LANGUAGE | en | Default Language: en, pt_BR etc
| OTRS_FQDN | myotrs.ligero.online | Used for composing several system notifications. You can change it latter under the sysconfig, or set it here before running the stack |
| INSTALL | 1 | Marked for installing the database and initial setup in a stack (docker-compose) installation |
| DONT_INSTALL_LIGERO_ADDONS | 0 | Set to 1 if you do not want to install Ligero Repository. Our Repository give you access to several free and enterprise AddOns for improving your experience with OTRS |


### Standalone container

If you just want to run a docker container with our OTRS 6 flavor, follow these steps:

 2. Run the following command:

`docker run -d --name my_otrs_container -p 80:80 ligero/otrs`

Then you can check if the system could start by it self:

`docker logs -f my_otrs_container`

When you see this message on the log:
*INFO success: apache2 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)*

It's because the system is running and you can access it.

You can finish the installation through the following address:

http://localhost/otrs/installer.pl (if you set -p 80:80)
or
http://YOUR_CONTAINER_IP/otrs/installer.pl

You can discover the container IP using the following command:

`docker exec my_otrs_container ip a`


## Other settings
A more complex way of running this image:
```
docker run -d --name sd_otrs_app \
-v /opt/docker/ServiceDesk/app/mail/:/etc/mail \
-v /opt/docker/ServiceDesk/app/otrs:/opt/otrs \
-v /usr/share/zoneinfo/America/Sao_Paulo:/etc/localtime:ro \
-P --network=ligero_complemento ligero/otrs
```

You can use OTRS's SMTP protocols for sending emails. This image also contains a sendmail service since it's the recommended way to send emails in OTRS production systems.

If you want to use it instead of OTRS's SMTP protocols, you may map a /etc/mail with sendmail configurations (this is for experts), or access the container and make your own sendmail configuration.

### AddOns Installation
You can map a volume with the addons you want to install during the container startup:
```
docker run -d --name sd_otrs_app \
-v $(pwd)/my_local_addons_folder:/opt/otrs_addons \
ligero/otrs
```

