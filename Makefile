help:
	@echo "Welcome to Riyarchi Make Machine"

HOMEDIR ?= $(shell getent passwd $$(logname 2>/dev/null || echo $(SUDO_USER)) | cut -d: -f6)
HOMEDIR ?= $(shell getent passwd $$(logname) | cut -d: -f6)

include make/command.mk
include make/dots.mk
include make/mime.mk
include make/pkg.mk
include make/pacman.mk
include make/input.mk

RIYA := $(shell pwd)

all: base dots

pac: pacinit pacupdate reflector

pacup:
	$(PACMAN) -Syu

base-install:
	$(PACMAN) -S $(NEED) $(CORE) $(RI) $(XDG) $(GTK) $(UTILS) $(FONT) $(MEDIA) $(GVFS) $(ROFI) $(LANG) $(SHELLUTIL) 

devel:
	$(PACMAN) -S $(CLANG) $(NEED)

dots: dotfiles mimeconf mpv pkgit bash rdfmconf gimp darktable dunst gh git lazygit rofi okular alacritty tmux vim lyconf nvim
base: pacup base-install ly devel fetch dtop det wtf rdfm

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

pkgclean:
	cd $(PKG) && sudo rm -rf det/ doi/ dtop/ fetch/ px/ rot/ rsxiv/ shot/ sxat/ wtf/

wifi:
	iw dev "$$(iw dev | awk '$$1=="Interface"{print $$2}')" set power_save off || true
	install -Dm644 $(RIYA)/nmconf/wifi-powersave.conf /etc/NetworkManager/conf.d/wifi-powersave.conf
	install -Dm644 $(RIYA)/nmconf/iwlmvm.conf /etc/modprobe.d/iwlmvm.conf
	@CONN=$$(nmcli -t -f NAME,TYPE connection show --active | grep wifi | cut -d: -f1); \
	if [ -n "$$CONN" ]; then \
		echo "[+] Active Wi-Fi connection: $$CONN"; \
		nmcli connection modify "$$CONN" 802-11-wireless.band a || true; \
		nmcli connection up "$$CONN" || true; \
	fi
	mkinitcpio -P
	@echo "[+] Done. Reboot recommended."

.PHONY: dotfiles mimeconf base dots base base-install x way mime mpv pkgit bash rdfmconf gimp darktable \
	dunst gh git i3 lazygit rofi okular alacritty tmux vim lyconf nvim shot px sxat rsxiv i3 clean pkgclean
