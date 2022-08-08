#!/bin/bash

export err="\033[1;31m[-]\033[m"
export msg="\033[1;32m[+]\033[m"
export info="\033[0;36m[:]\033[m"

# Make sure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${err} This script must be run as root." 1>&2
   exit 1
fi

# Check if Docker is already installed
if [[ "$(command -v docker)" -ne "" ]]; then
        echo -e "${err} Docker is already installed."
        exit 1;
fi

# Install dependencies 
echo -e "${info} Updating repositories..."
apt-get update &> /dev/null 
echo -e "${info} Installing dependencies..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release &> /dev/null 

# Add GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo -e "${add} Added Docker's GPG key"

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list &> /dev/null
echo -e "${add} Added Docker's stable repository"

# Install Docker
echo -e "${info} Updating repositories..."
apt-get update &> /dev/null
echo -e "${info} Installing Docker. Please wait..."
apt-get install -y docker-ce docker-ce-cli containerd.io  &> /dev/null
echo -e "${add} Docker successfully installed:" $(docker --version)


# Install Docker Compose
while true; do
    read -p "[?] Do you want to install Docker Compose? [y/n] " yn
    case $yn in
        [Yy]* ) echo -e "${info} Installing Docker Compose. Please wait...";
               apt-get install -y docker-compose  &> /dev/null ;
               echo -e "${add} Docker Compose successfully installed:" $(docker-compose --version);
               break;;
        [Nn]* ) break;;
        * ) ;;
    esac
done

# Create Docker user
while true; do
    read -p "[?] Do you want to create a Docker user? [y/n] " yn
    case $yn in
        [Yy]* ) read -p "Please choose an id for the new user/group: " id;
               /usr/sbin/groupadd -g $id dockeruser && /usr/sbin/useradd dockeruser -u $id -g $id -m -s /bin/bash && echo "${add} Docker user created:" && id dockeruser; 
               break;;
        [Nn]* ) break;;
        * ) ;;
    esac
done

# Enable Docker service at startup
systemctl start docker.service docker.socket containerd && systemctl enable docker.service docker.socket containerd &> /dev/null
echo -e "${msg} Docker service started and enabled."

echo -e "${info} Process completed. Run '\033[0;36msystemctl status docker\033[m' to check Docker's status."
