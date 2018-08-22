#!/bin/bash

# Your Settings
PORTAINER_PASSWORD=ligero

ADDONS_TO_INSTALL="http://ftp.otrs.org/pub/otrs/packages/FAQ-6.0.9.opm
                   http://ftp.otrs.org/pub/otrs/packages/Survey-6.0.5.opm
                   http://ftp.otrs.org/pub/otrs/itsm/bundle6/ITSM-6.0.10.opm"

# Other Settings
LOCAL_IP=`hostname -I | awk '{print $1}'`
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
# printf "${green}text${reset}"


printf "\n${green}Updating CentOS packages...\n\n${reset}"
yum update -y

printf "\n${green}Done${reset}\n\n"

printf "\n${green}Installing Docker...\n\n${reset}"

# Reference: https://complemento.net.br/2018/08/14/instalando-o-docker-no-centos-7/
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce
chkconfig docker on
systemctl start docker
yum install -y bash-completion wget

printf "\n${green}Done${reset}\n\n"

printf "${green}Installing docker-compose...${reset}\n"
curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.22.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

printf "${green}Done${reset}\n\n"

printf "${green}Installing Portainer for easily manage the stack...${reset}\n"
docker volume create portainer_data
PORTAINER_PASSWORD_CRYPT=`docker run --rm httpd:2.4-alpine htpasswd -nbB admin $PORTAINER_PASSWORD | cut -d ":" -f 2`
docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer -H unix:///var/run/docker.sock --admin-password "$PORTAINER_PASSWORD_CRYPT"

printf "${green}Done.\n${reset}"

printf "\n${green}Downloading OTRS 6 docker-compose file...${reset}\n"

cd /opt
mkdir ligero-otrs
cd ligero-otrs
wget https://raw.githubusercontent.com/complemento/docker.otrs/master/docker-compose.yaml
mkdir otrs_addons

printf "${green}Done${reset}\n\n"

printf "${green}Downloading your AddOns...${reset}\n\n"

cd otrs_addons
for addons in $ADDONS_TO_INSTALL
do
        wget $addons
done
printf "${green}Done${reset}\n\n"

printf "${red}Starting OTRS 6 for the first time...${reset}"
printf "${red}It can take some minutes, since we will install the addons also. We will let you know when it's ready...${reset}\n"

cd /opt/ligero-otrs
sed -i -- "s/# ports:/ports:/g" docker-compose.yaml
sed -i -- "s/#   - 80:80/   - 80:80/g" docker-compose.yaml

docker-compose up -d
printf "${green}\nStill loading...${reset}";
while ! curl -s http://localhost/otrs/index.pl|grep -ni "otrs ag"; do 
    sleep 10; printf "${green}..${reset}";
done

printf "${green}\nDone!${reset}\n\n"

printf "${green}\Moving installed Addons for historical porpuses!${reset}\n\n"
mkdir /opt/ligero-otrs/otrs_addons_installed/
mv /opt/ligero-otrs/otrs_addons/* /opt/ligero-otrs/otrs_addons_installed/
printf "${green}\nDone!${reset}\n\n"

printf "${green}\n\nYou can access Portainer (Stack Administration)at\nhttp://$LOCAL_IP:9000${reset}"
printf "${green}\nUser: admin${reset}"
printf "${green}\nPassword: $PORTAINER_PASSWORD ${reset}\n\n"

printf "${green}\n\nYou can access OTRS at\nhttp://$LOCAL_IP/otrs/index.pl${reset}"
printf "${green}\nUser: root@localhost${reset}"
printf "${green}\nPassword: ligero${reset}\n\n"

printf "${green}\nGet in touch with us:${reset}"
printf "${green}\nEmail: contato@complemento.net.br${reset}"
printf "${green}\nWhatsapp: https://wa.me/551125060180${reset}"
printf "${green}\nWebsite: https://complemento.net.br${reset}"

printf "\n\n"

# printf "${green}Installing...${reset}"
# {
# } &> /dev/null
# printf "${green}Done${reset}\n\n"
