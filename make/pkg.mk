
APP = share/applications

ZOTEROURL = https://download.zotero.org/client/release/9.0.6/Zotero-9.0.6_linux-x86_64.tar.xz

# PAKCAGES
XORG = xorg-server xorg-xinit xorg-apps xorg-xbacklight xbindkeys xorg-xdpyinfo xss-lock xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-fonts-misc xorg-xsetroot xclip picom
EASYEFF = pipewire  pipewire-alsa  pipewire-pulse pipewire-jack wireplumber gst-plugin-pipewire lsp-plugins calf zam-plugins rnnoise easyeffects
CORE = libnotify dbus nwg-look numlockx brightnessctl redshift acpi arandr alsa-utils zip unzip pavucontrol dex pacman-contrib 
SHELLUTIL = curl github-cli lazygit neovim unzip 7zip zoxide awesome-terminal-fonts yt-dlp sysstat tumbler playerctl network-manager-applet wlctl-bin bluetui eza
CLANG = clang gcc
LANG = python python-pipx go rustup jq
ROFI = rofi rofi-greenclip
GVFS = gvfs gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb
MEDIA = mpv ffmpeg wf-recorder 
FONT = noto-fonts ttf-jetbrains-mono-nerd
UTILS = galculator lxappearance
GTK = polkit-gnome gtk-engine-murrine
XDG = archlinux-xdg-menu xdg-user-dirs-gtk
RDFM = libfm libfm-gtk3 intltool libtool gettext pkg-config autoconf automake
mp3 = id3 flac
FLATPAK = com.github.tchx84.Flatseal it.mijorus.gearlever com.github.wwmm.easyeffects

RI = songrec xdman-beta-bin jdownloader2 qbittorrent lollypop localsend-bin

WAY ?=
I3 = i3-wm i3blocks i3lock-color i3status eos-settings-i3wm libx11

flatpak:
	$(PACMAN) -S $(NEED) flatpak
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	flatpak install $(FLATPAK)

mp3:
	$(PACMAN) -S $(MP3)

doi:
	$(CLONE)
	$(MK) && sudo make dmon-install

sxat rsxiv swat:
	$(CLONE)
	$(CD) && bash install.sh

rdfm:
	@$(PACMAN) -S $(RDFM) $(NEED)
	$(CLONE)
	$(CD) && bash install.bash

rot fetch dtop shot whot det px pw wtf:
	$(CLONE)
	$(MK)

STYPE = $(shell echo "$$XDG_SESSION_TYPE")
dacam:
	$(CLONE)
	$(MK) BACKEND=$(STYPE)

ly:
	@sudo pacman -S --noconfirm ly
	@sudo systemctl enable ly.service 2>/dev/null || \
		sudo systemctl enable ly@tty1.service 2>/dev/null || \
		sudo systemctl enable ly@tty2.service

firefox:
	-@$(GG) --no-single-branch $(URL)/$(USC) $(PKG)/$(USC)
	@cd $(PKG)/$(USC) && for branch in $$(git branch -r | grep -v HEAD | grep -v master | grep -v main | sed 's/origin\///'); do git checkout -b $$branch origin/$$branch; done
	@git checkout -b main
	@bash $(PKG)/userChrome/firefox.sh

spotify:
	@yay -S --noconfirm spotify
	@bash <(curl -sSL https://spotx-official.github.io/run.sh)

easyeffects:
	echo "Installing core PipeWire stack..."
	$(PACMAN) -S --needed  $(EASYEFF)
	echo "Enabling PipeWire services..."
	systemctl --user enable pipewire pipewire-pulse wireplumber
	systemctl --user restart pipewire pipewire-pulse wireplumber
	echo "EasyEffects setup complete."

gtk:
	$(PACMAN) -S $(GTK)
	if [ ! -d "$$HOME/.gtk" ]; then \
		git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme "$$HOME/.gtk" --depth 1; \
	fi
	cd "$$HOME/.gtk/themes" && bash install.sh -n Gruvhim -c dark -l --tweaks medium float outline -s compact
	gsettings set org.gnome.desktop.interface color-scheme prefer-dark

pkgclean:
	cd $(PKG) && sudo rm -rf det/ doi/ dtop/ fetch/ px/ rot/ shot/ sxat/ wtf/ dacam/

chromium:
	curl -Lo $(HOMEDIR)/Downloads/chromium-bin.pkg.tar.zst https://github.com/HimadriChakra12/ri/releases/download/chromium/chromium-bin-138.0.7204.183-1-x86_64.pkg.tar.zst
	sudo pacman -U $(HOME)/Downloads/chromium-bin.pkg.tar.zst

zotero:
	curl -Lo "$(HOMEDIR)/Downloads/Zotero-9.0.6_linux-x86_64.tar.xz" \
		$(ZOTEROURL)
	cd "$(HOMEDIR)/Downloads" && \
		tar xf Zotero-9.0.6_linux-x86_64.tar.xz && \
		rm -rf "$(PKG)/Zotero" && \
		mv Zotero_linux-x86_64 "$(PKG)/Zotero" && \
		install -Dm644 "$(PKG)/Zotero/zotero.desktop" "$(HOMEDIR)/.local/$(APP)/zotero.desktop" && \
		sudo install -Dm644 "$(PKG)/Zotero/zotero.desktop" "/usr/$(APP)/zotero.desktop"
