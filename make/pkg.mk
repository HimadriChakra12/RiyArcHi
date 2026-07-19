PKG = $(HOME)/pkg
URL = https://github.com/HimadriChakra12

XORG = xorg-server xorg-xinit xorg-apps xorg-xbacklight xbindkeys xorg-xdpyinfo xss-lock xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-fonts-misc xorg-xsetroot xclip picom
EASYEFF = pipewire  pipewire-alsa  pipewire-pulse pipewire-jack wireplumber gst-plugin-pipewire lsp-plugins calf zam-plugins rnnoise easyeffects
CORE = libnotify dbus nwg-look numlockx brightnessctl redshift acpi arandr alsa-utils zip unzip pavucontrol dex
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
RI = songrec xdman-beta-bin jdownloader2 qbittorrent lollypop localsend-bin

MAKE = make && sudo make install

I3 = i3-wm i3blocks i3lock-color i3status eos-settings-i3wm

RDFM = libfm libfm-gtk3 intltool libtool gettext pkg-config autoconf automake

doi:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE) && sudo make dmon-install

rsxiv:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

fetch:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

dtop:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

shot:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

whot:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

det:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

px:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

pw:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

wtf:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && $(MAKE)

sxat:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && bash install.sh

swat:
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && bash install.sh

rdfm:
	@$(PACMAN) -S $(RDFM) $(NEED)
	-@$(GG) $(URL)/$@ $(PKG)/$@
	@cd $(PKG)/$@ && bash install.bash

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
