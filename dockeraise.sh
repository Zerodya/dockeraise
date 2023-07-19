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
    while true; do
        echo -e "${err} Docker is already installed."
        read -p "Do you want still want to run the script? [y/n] " yn </dev/tty
        case $yn in
            [Yy] ) break;;
            [Nn] ) exit 1;;
            * ) ;;
        esac
    done
fi

# Check if machine runs Debian (only checks if apt-get exists, maybe needs a better implementation?)
if ! command -v apt-get &>/dev/null; then
    echo -e "${err} This script only works on Debian machines, sorry!"
    exit 1
fi

# Remove old and incompatible packages
echo -e "${info} Removing old and incompatible packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove -y $pkg >/dev/null; done

# Install dependencies
echo -e "${info} Updating repositories..."
apt-get update >/dev/null
echo -e "${info} Installing dependencies..."
apt-get install -y ca-certificates curl gnupg >/dev/null

# Add GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg &&
chmod a+r /etc/apt/keyrings/docker.gpg &&
echo -e "${msg} Added Docker's GPG key"

# Add repository
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null &&
echo -e "${msg} Added Docker's stable repository"

# Install Docker
echo -e "${info} Updating repositories..."
apt-get update >/dev/null
echo -e "${info} Installing Docker and Docker compose (this might take a while)..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null &&
echo -e "${msg} Docker successfully installed: \033[0;32m$(docker --version)\033[m"

# Create Docker user
while true; do
    echo -e -n "${ask} "
    read -p "Do you want to create a Docker user? [y/n] " yn </dev/tty
    case $yn in
        [Yy] ) while true; do
            echo -e -n "${ask} "
            read -p "Please choose an ID for the new user/group: " id </dev/tty;
            if id $id &>/dev/null; then
                echo -e "${err} An user with the same ID already exists: \033[0;36m$(id $id)\033[m";
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
systemctl enable --now docker.service containerd.service >/dev/null &&
echo -e "${msg} Docker services started and enabled." || echo -e "${err} Could not start docker services. Try running \033[0;36msystemctl enable --now docker.service containerd.service\033[m again in a few minutes."

echo -e "${info} Process completed. Run '\033[0;36msystemctl status docker\033[m' to check Docker's status."
