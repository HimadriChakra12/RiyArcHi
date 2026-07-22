include make/help.mk


HOMEDIR ?= $(shell getent passwd $$(logname 2>/dev/null || echo $(SUDO_USER)) | cut -d: -f6)
HOMEDIR ?= $(shell getent passwd $$(logname) | cut -d: -f6)
RIYA := $(shell pwd)

include make/command.mk
include make/dots.mk
include make/mime.mk
include make/pkg.mk
include make/pacman.mk
include make/input.mk
include make/docker.mk
include make/wifi.mk
include make/wine.mk


all: welcome-banner2 time base dots

time:
	sudo timedatectl set-timezone Asia/Dhaka

tty:
	sudo usermod -aG tty himadri

pac: pacinit pacupdate reflector

pacup:
	$(PACMAN) -Syu

docker: docker-install docker-configure docker-group docker-setup

base-install:
	$(PACMAN) -S $(NEED) $(CORE) $(RI) $(XDG) $(GTK) $(UTILS) $(FONT) $(MEDIA) $(GVFS) $(ROFI) $(LANG) $(SHELLUTIL) 

devel:
	$(PACMAN) -S $(CLANG) $(NEED)

dots: dotfiles mimeconf mpv pkgit bash rdfmconf gimp darktable dunst gh git lazygit rofi okular alacritty tmux vim lyconf nvim
base: pacup base-install ly devel fetch dtop det wtf rdfm dacam chromium

xorginit:
	$(PACMAN) -S $(XORG)
wayinit:
	$(PACMAN) -S $(WAY)

x: xorginit shot px sxat rsxiv i3
way: wayinit whot pw swat

gpu:
	$(PACMAN) -S xf86-video-intel

xorgconf:
	sudo cp $(RIYA)/xorg.config.d/* -f /etc/X11/xorg.conf.d/
	ls /etc/X11/xorg.conf.d/

clean:
	-sudo paccache -r
	-$(PACMAN) -Scc --noconfirm
	-@orphans=$$($(PACMAN) -Qtdq); \
	if [ -n "$$orphans" ]; then \
		$(PACMAN) -Rns $(NOC) $$orphans; \
	else \
		echo "No orphaned packages found."; \
	fi
	-sudo journalctl --vacuum-size=500M
	-sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
	-sudo rm -rf /tmp/* /var/tmp/*
	-if command -v docker &> /dev/null; then \
		echo "[6/10] Pruning unused Docker objects..."; \
		sudo docker system prune -a --volumes -f; \
	fi
	-sudo rm -rf /var/cache/*
	-sudo find /root -type f -size +50M -exec ls -lh {} \; | awk '{ print $$9 ": " $$5 }'
	-sudo du -hxd1 /opt | sort -h | awk '$$1 ~ /[0-9]M|G/ {print}'

waydroid:
	$(PACMAN) -S $(NEED) xorg-xwayland cage waydroid
	sudo waydroid init
	sudo waydroid container start

zotero-clean:
	rm -rf $(HOMEDIR)/.mozilla

.PHONY: dotfiles mimeconf base dots base base-install x way mime mpv pkgit bash rdfmconf gimp darktable \
	dunst gh git i3 lazygit rofi okular alacritty tmux vim lyconf nvim shot px sxat rsxiv i3 clean pkgclean \
	docker-install docker-configure docker-group docker-setup zotero zotero-install zotero-arc chromium baph onlyoffice

