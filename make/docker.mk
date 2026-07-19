DOCKER_DATA_ROOT = $(HOMEDIR)/.dockerdat
DAEMON_JSON = /etc/docker/daemon.json
USER_NAME ?= $(shell echo $${SUDO_USER:-$$USER})

.PHONY: 
docker-setup: docker-install docker-configure docker-group
	@echo "Docker fully configured!"
	@echo "IMPORTANT:"
	@echo "Log out and log back in OR run: newgrp docker"
	@echo "Verify with:"
	@echo "  docker info | grep 'Docker Root Dir'"
	@echo "  docker ps"

docker-install:
	@echo "Installing Docker packages..."
	pacman -S --noconfirm docker docker-compose
	systemctl enable docker

docker-configure:
	@echo "Configuring Docker for user: $(USER_NAME)"
	@echo "Docker data-root: $(DOCKER_DATA_ROOT)"
	mkdir -p $(DOCKER_DATA_ROOT)
	chown -R root:root $(DOCKER_DATA_ROOT)
	chmod 711 $(DOCKER_DATA_ROOT)
	mkdir -p /etc/docker
	@printf '{\n  "data-root": "$(DOCKER_DATA_ROOT)"\n}\n' > $(DAEMON_JSON)
	@echo "✔ Docker data-root configured"
	systemctl restart docker

docker-group:
	@getent group docker > /dev/null && echo "✔ docker group already exists" || (echo "➕ Creating docker group" && groupadd docker)
	@id -nG "$(USER_NAME)" | grep -qw docker \
		&& echo "✔ User '$(USER_NAME)' already in docker group" \
		|| (echo "➕ Adding user '$(USER_NAME)' to docker group" && usermod -aG docker "$(USER_NAME)")
