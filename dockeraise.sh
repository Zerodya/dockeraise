#!/bin/bash

# Make sure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install dependencies 
echo "[::] Updating repositories..."
sudo apt-get update > /dev/null 
echo "[+] Done.\n\n[::] Installing dependencies..."
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "[+] Done.\n\n[++] Added Docker's GPG key"

# Add repository
echo "[::] Adding stable repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
echo "[+] Done.\n\n[::] Updating repositories..."
apt-get update > /dev/null
echo "[+] Done.\n\n[::] Installing Docker..."
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
echo "[+] Docker successfully installed:"
docker --version

# Install Docker Compose
while true; do
    read -p "[?] Do you want to install Docker Compose? [y/n]" yn
    case $yn in
        [Yy]* ) apt-get install docker-compose; break;;
        [Nn]* ) exit;;
        * ) echo "Invalid input.";;
    esac
done

echo "[+] Docker compose installed:"
docker-compose --version

# Create Docker user
while true; do
    read -p "[?] Do you want to create a Docker user with uid=1000 and gid=1000? [y/n]?" yn
    case $yn in
        [Yy]* ) groupadd -g 1000 dockeruser && useradd dockeruser -u 1000 -g 1000 -m -s /bin/bash; break;;
        [Nn]* ) exit;;
        * ) echo "Invalid input.";;
    esac
done

echo "[+] Docker user created:"
id dockeruser

# Show status
echo "[::] Process completed. Run 'systemctl status docker' to check Docker's status."
