#!/bin/bash

# Make sure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install dependencies 
echo "[:] Updating repositories..."
apt-get update > /dev/null 
echo "[:] Installing dependencies..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release &> /dev/null 

# Add GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "[+] Added Docker's GPG key"

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
echo "[+] Added Docker's stable repository"

# Install Docker
echo "[:] Updating repositories..."
apt-get update > /dev/null
echo "[:] Installing Docker. Please wait..."
apt-get install -y docker-ce docker-ce-cli containerd.io  &> /dev/null 
echo "[+] Docker successfully installed:"
docker --version

# Install Docker Compose
while true; do
    read -p "[?] Do you want to install Docker Compose? [y/n] " yn
    case $yn in
        [Yy]* ) echo "[:] Installing Docker Compose. Please wait...";
               apt-get install -y docker-compose  &> /dev/null ;
               echo "[+] Docker Compose successfully installed:";
               docker-compose --version;
               break;;
        [Nn]* ) break;;
        * ) echo "Invalid input.";;
    esac
done

# Create Docker user
while true; do
    read -p "[?] Do you want to create a Docker user with uid=1000 and gid=1000? [y/n] " yn
    case $yn in
        [Yy]* ) read -p "Please choose a user/group id: " id;
               /usr/sbin/groupadd -g $id dockeruser && /usr/sbin/useradd dockeruser -u $id -g $id -m -s /bin/bash && echo "[+] Docker user created:" && id dockeruser; 
               break;;
        [Nn]* ) break;;
        * ) echo "Invalid input.";;
    esac
done

# Enable Docker service at startup
systemctl start docker.service docker.socket containerd && systemctl enable docker.service docker.socket containerd > /dev/null
echo "[+] Docker service started and enabled to run at boot."

echo "Process completed. Run 'systemctl status docker' to check Docker's status."
