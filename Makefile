include make/command.mk
include make/dots.mk
include make/mime.mk
include make/pkg.mk
include make/pacman.mk
include make/input.mk

all: base dots

pac: pacinit pacupdate reflector

pacup:
	$(PACMAN) -Syu

dots: dotfiles mimeconf mpv pkgit bash rdfmconf gimp darktable dunst gh git lazygit rofi okular alacritty tmux vim lyconf nvim

base-install:
	$(PACMAN) -S $(NEED) $(CORE) $(RI) $(XDG) $(GTK) $(UTILS) $(FONT) $(MEDIA) $(GVFS) $(ROFI) $(LANG) $(SHELLUTIL) 

devel:
	$(PACMAN) -S $(CLANG) $(NEED)

base: pacup base-install ly devel fetch dtop det wtf rdfm

x: shot px sxat rsxiv i3
	$(PACMAN) -S $(XORG)

way: whot pw swat
	$(PACMAN) -S $(WAY)

gpu:
	$(PACMAN) -S xf86-video-intel

xorgconf:
	sudo cp $(HOME)/riyarchi/xorg.config.d/* -f /etc/X11/xorg.conf.d/
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

.PHONY: dotfiles mimeconf base dots base base-install x way mime mpv pkgit bash rdfmconf gimp darktable \
	dunst gh git i3 lazygit rofi okular alacritty tmux vim lyconf nvim shot px sxat rsxiv i3 clean pkgclean
