[![N|Solid](https://i1.wp.com/complemento.net.br/wp-content/uploads/2017/11/logo_otrs6free.png?fit=300%2C68&ssl=1)]()

OTRS Docker Installation
========================

What's OTRS?
------------

OTRS is the world most popular Service Desk software, delivered by OTRS Group and a large open source community. You can check more information and all OTRS Group Services in their web site:
http://www.otrs.com

This Docker image is maintained by Complemento, a Brazilian company dedicate to delivery ITSM with open source software. We develop many Free and Enterprise AddOns for OTRS. You can check our website for more information:
http://www.complemento.net.br

About this Image
----------------
This image aims to make a fresh new application install of OTRS. You will need to create another mysql container for your own (or use an traditional mysql server/service).

If you want a really easy OTRS Docker installation for testing purposes, please check this other option, with Database deployment included in the same container:

https://hub.docker.com/r/ligero/otrs_easy/

If you just want to run a docker container with our OTRS 6 flavor, follow these steps:

 1. Install a docker server. You can download Docker Community Edition from this link: 

	https://www.docker.com/community-edition#/download

 2. Run the following command:

`docker run -d -v otrs_data:/opt/otrs -p 80:80 ligero/otrs`

 - In production environments, we recommend you to set the version of your choice:
 
 `docker run -d -v otrs_data:/opt/otrs -p 80:80 ligero/otrs:6.0.4`
 
 Currently available versions:
 - 6.0.4
 - 5.0.26

Older not maintained versions:
 - 6.0.3
 - 6.0.2
 - 6.0.1

 
If you are running your docker container on your localhost, go to http://localhost/otrs/installer.pl to proceed with the rest of the installation.
