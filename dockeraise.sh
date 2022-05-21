#!/bin/bash

# Make sure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install dependencies 
echo "[::] Updating repositories..."
sudo apt-get update > /dev/null 
echo "[+] Done."
echo "[::] Installing dependencies..."
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release > /dev/null
echo "[+] Done."

# Add GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "[+] Added Docker's GPG key"

# Add repository
echo "[::] Adding stable repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "[+] Done."

# Install Docker
echo "[::] Updating repositories..."
apt-get update > /dev/null
echo "[+] Done."
echo "[::] Installing Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null
echo "[+] Docker successfully installed:"
docker --version

# Install Docker Compose
while true; do
    read -p "[?] Do you want to install Docker Compose? [y/n] " yn
    case $yn in
        [Yy]* ) apt-get install -y docker-compose > /dev/null; break;;
        [Nn]* ) exit;;
        * ) echo "Invalid input.";;
    esac
done

echo "[+] Docker compose installed:"
docker-compose --version

# Create Docker user
while true; do
    read -p "[?] Do you want to create a Docker user with uid=1000 and gid=1000? [y/n] ?" yn
    case $yn in
        [Yy]* ) /usr/sbin/groupadd -g 1000 dockeruser && /usr/sbin/useradd dockeruser -u 1000 -g 1000 -m -s /bin/bash; break;;
        [Nn]* ) exit;;
        * ) echo "Invalid input.";;
    esac
done

echo "[+] Docker user created:"
id dockeruser

# Enable Docker at startup
systemctl start docker.service docker.socket && systemctl enable docker.service docker.socket
echo "[::] Process completed. Run 'systemctl status docker' to check Docker's status."
