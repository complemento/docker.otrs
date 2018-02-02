
[![N|Solid](https://i1.wp.com/complemento.net.br/wp-content/uploads/2017/11/logo_otrs6free.png?fit=300%2C68&ssl=1)]()

# OTRS Docker Installation

## What's OTRS?
OTRS is the world most popular Service Desk software, delivered by OTRS Group and a large open source community. You can check more information and all OTRS Group Services in their web site:
http://www.otrs.com

This Docker image is maintained by Complemento, a Brazilian company dedicate to delivery ITSM with open source software. We develop many Free and Enterprise AddOns for OTRS. You can check our website for more information:
http://www.complemento.net.br

## About this Image
This image aims to make a fresh new application install of OTRS. You will need to create another mysql container or use an traditional mysql server/service. We have a Mysql image tunned for OTRS if you want it:
https://hub.docker.com/r/ligero/otrs_mysql/

If you want a really easy OTRS Docker installation for testing purposes, please check this other option, with Database deployment included in the same container and you will be able to run OTRS in a few seconds:
https://hub.docker.com/r/ligero/otrs_easy/

## How to Run it

### I already have a running Mysql

If you just want to run a docker container with our OTRS 6 flavor, follow these steps:

 1. Install a docker server. You can download Docker Community Edition from this link: 
	https://www.docker.com/community-edition#/download
	
 2. Run the following command:
`docker run -d -v otrs_data:/opt/otrs -p 80:80 ligero/otrs`

 3. Start the OTRS Web Installer:
If you are running your docker container on your localhost, go to http://localhost/otrs/installer.pl to proceed with the rest of the installation.
Check how to finish the installation at OTRS documentation:
http://doc.otrs.com/doc/manual/admin/stable/en/html/web-installer.html

### I don't have a running Mysql server

 1. Create a docker user network for you application:
```
docker network create my_otrs_net
```

2. Create a new Mysql OTRS Tunned Database, connected to your new network:
```
docker run -d --name otrs_db -v otrs_mysql:/var/lib/mysql \
--network my_otrs_net -e MYSQL_PASSWORD=MyRootMysqlPassword123 \
ligero/otrs_mysql
```
3. Run OTRS Image
```
docker run -d --name otrs_app -v otrs_app:/opt/otrs \
--network my_otrs_net ligero/otrs:6.0.4
```
 4. Find your application IP address:
```
docker exec otrs_app ip a | grep global
```
The output should be something like this:

    inet 172.22.0.3/16 scope global eth0
    inet 172.17.0.6/16 scope global eth1

 5. Access you web installer:

Choose one of the IP addresses informed in the last command, and use it as your OTRS web installer:
http://172.22.0.3/otrs/installer.pl

 6. Follow the instructions and set the database information in 2nd step. Remember the password you have set in MYSQL_PASSWORD parameter. Change the host to **otrs_db**. Clique em Check database and proceed with the installation:
![enter image description here](https://complemento.net.br/wp-content/uploads/2018/02/Sele%C3%A7%C3%A3o_020.png)


## For Production Environments
 - In production environments, we recommend you to set the version of your choice:
```
docker run -d -v otrs_data:/opt/otrs -p 80:80 ligero/otrs:6.0.4
```
 
 Currently available versions:
 - 6.0.4
 - 5.0.26

Older not maintained versions:
 - 6.0.3
 - 6.0.2
 - 6.0.1
