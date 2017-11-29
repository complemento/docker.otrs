OTRS 6 Dockerfile
-------------------
This repository brings to you a OTRS 6 Dockerfile, without database instalation.

If you want a really easy OTRS Docker installation, please check this other option, with Database deploy:
docker.easy.otrs (available soon)

If you just want to run a docker container with our OTRS 6 flavor, follow these steps:

 1. Install a docker server. You can download Docker Community Edition from this link: 

	https://www.docker.com/community-edition#/download

 2. Run the following command:

`docker run -tid -v otrs_data:/opt/otrs -p 80:80 ligero/otrs`

If you are running your docker container on your localhost, go to http://localhost/otrs/installer.pl to proceed with the rest of the installation.

