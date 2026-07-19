#!/bin/bash
set -e

### COLORS ###
GREEN="\033[0;32m"
NC="\033[0m"

### INSTALL DOCKER (Arch / yay) ###
docker_pkgs=(
    docker
    docker-compose
)

echo -e "${GREEN}Installing Docker & Plugins!${NC}"
sudo pacman -S --noconfirm "${docker_pkgs[@]}"

### MUST BE ROOT ###
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "  sudo $0"
    exit 1
fi

### DETECT REAL USER ###
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")
DOCKER_DATA_ROOT="$USER_HOME/.dockerdat"

echo "Configuring Docker for user: $USER_NAME"
echo "Docker data-root: $DOCKER_DATA_ROOT"

### ENABLE & START DOCKER ###
systemctl enable docker

### CREATE DATA ROOT ###
mkdir -p "$DOCKER_DATA_ROOT"
chown -R root:root "$DOCKER_DATA_ROOT"
chmod 711 "$DOCKER_DATA_ROOT"

### CONFIGURE DOCKER DAEMON ###
DAEMON_JSON="/etc/docker/daemon.json"

mkdir -p /etc/docker

cat >"$DAEMON_JSON" <<EOF
{
  "data-root": "$DOCKER_DATA_ROOT"
}
EOF

echo "✔ Docker data-root configured"

### RESTART DOCKER ###
systemctl restart docker

### DOCKER GROUP ###
if getent group docker >/dev/null; then
    echo "✔ docker group already exists"
else
    echo "➕ Creating docker group"
    groupadd docker
fi

if id -nG "$USER_NAME" | grep -qw docker; then
    echo "✔ User '$USER_NAME' already in docker group"
else
    echo "➕ Adding user '$USER_NAME' to docker group"
    usermod -aG docker "$USER_NAME"
fi

echo
echo "✅ Docker fully configured!"
echo
echo "⚠ IMPORTANT:"
echo "Log out and log back in OR run:"
echo "  newgrp docker"
echo
echo "Verify with:"
echo "  docker info | grep 'Docker Root Dir'"
echo "  docker ps"
