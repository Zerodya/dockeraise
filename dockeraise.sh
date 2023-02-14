#!/bin/bash

err="\033[1;31m[!]\033[m"
msg="\033[1;32m[+]\033[m"
info="\033[0;36m[:]\033[m"
ask="\033[0;35m[?]\033[m"

# Make sure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${err} This script must be run as root."
    exit 1
fi

# Check if Docker is already installed
if command -v docker &>/dev/null; then
    echo -e "${err} Docker is already installed."
    exit 1
fi

# Check if machine is Debian-based
if ! command -v apt-get &>/dev/null; then
    echo -e "${err} This script only works on Debian-based machines, sorry!"
    exit 1
fi

# Install dependencies
echo -e "${info} Updating repositories..."
apt-get update >/dev/null
echo -e "${info} Installing dependencies (this might take a while)..."
apt-get install -y ca-certificates curl gnupg lsb-release >/dev/null

# Add GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&
echo -e "${msg} Added Docker's GPG key"

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null &&
echo -e "${msg} Added Docker's stable repository"

# Install Docker
echo -e "${info} Updating repositories..."
apt-get update >/dev/null
echo -e "${info} Installing Docker (this might take a while)..."
apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null &&
echo -e "${msg} Docker successfully installed: \033[0;32m$(docker --version)\033[m"

# Install Docker Compose
while true; do
    echo -e -n "${ask} "
    read -p "Do you want to install Docker-Compose? [y/n] " yn </dev/tty
    case $yn in
        [Yy] ) echo -e "${info} Installing Docker-Compose (this might take a while)...";
            apt-get install -y docker-compose  >/dev/null &&
            echo -e "${msg} Docker Compose successfully installed: \033[0;32m$(docker-compose --version)\033[m"
            break;;
        [Nn] ) break;;
        * ) ;;
    esac
done

# Create Docker user
while true; do
    echo -e -n "${ask} "
    read -p "Do you want to create a Docker user? [y/n] " yn </dev/tty
    case $yn in
        [Yy] ) while true; do
            echo -e -n "${ask} "
            read -p "Please choose an ID for the new user/group: " id </dev/tty;
            if id $id &>/dev/null; then
                echo -e "${err} An user with the same ID already exists.";
                continue;
            else
                /usr/sbin/groupadd -g $id dockeruser && /usr/sbin/useradd dockeruser -u $id -g $id -m -s /bin/bash && 
                echo -e "${msg} Docker user created: \033[0;32m$(id dockeruser)\033[m"
                break;
            fi
        done
        break;;
        [Nn] ) break;;
        * ) ;;
    esac
done

# Enable Docker service at startup
echo -e "${info} Starting Docker services..."
systemctl start docker.service docker.socket containerd && systemctl enable docker.service docker.socket containerd >/dev/null &&
echo -e "${msg} Docker services started and enabled."

echo -e "${info} Process completed. Run '\033[0;36msystemctl status docker\033[m' to check Docker's status."
