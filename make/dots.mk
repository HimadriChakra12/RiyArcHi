LN   := ln -sfn
DOTS := $(HOME)/.dotfiles
CONF := $(HOME)/.config

define LINK
	@rm -rf "$(2)"
	@$(LN) "$(1)" "$(2)"
	@echo "Linked $(1) -> $(2)"
endef

dotfiles:
	@echo "Cloning .dotfiles"
	-@$(GG) $(URL)/.dotfiles $(DOTS)
	@echo "Done!"
mimeconf:
	$(call LINK,$(DOTS)/mimeapps.list,$(CONF)/mimeapps.list)
mpv:
	$(call LINK,$(DOTS)/mpv,$(CONF)/mpv)
pkgit:
	$(call LINK,$(DOTS)/pkgit,$(CONF)/pkgit)
bash:
	$(call LINK,$(DOTS)/bashconf,$(HOME)/bashconf)
	$(call LINK,$(DOTS)/.bashrc,$(HOME)/.bashrc)
rdfmconf:
	$(call LINK,$(DOTS)/rdfm,$(CONF)/rdfm)
gimp:
	$(call LINK,$(DOTS)/GIMP,$(CONF)/GIMP)
darktable:
	$(call LINK,$(DOTS)/darktable,$(CONF)/darktable)
dunst:
	$(call LINK,$(DOTS)/dunst,$(CONF)/dunst)
gh:
	$(call LINK,$(DOTS)/gh,$(CONF)/gh)
git:
	$(call LINK,$(DOTS)/git,$(CONF)/git)
i3:
	$(call LINK,$(DOTS)/i3,$(CONF)/i3)
lazygit:
	$(call LINK,$(DOTS)/lazygit,$(CONF)/lazygit)
rofi:
	$(call LINK,$(DOTS)/rofi,$(CONF)/rofi)
	$(call LINK,$(DOTS)/greenclip.toml,$(CONF)/greenclip.toml)
okular:
	$(call LINK,$(DOTS)/Okular/okularrc,$(CONF)/okularrc)
	$(call LINK,$(DOTS)/Okular/okularpartrc,$(CONF)/okularpartrc)
alacritty:
	$(call LINK,$(DOTS)/alacritty.toml,$(CONF)/alacritty.toml)
tmux:
	$(call LINK,$(DOTS)/.tmux.conf,$(HOME)/.tmux.conf)
vim:
	$(call LINK,$(DOTS)/.vimrc,$(HOME)/.vimrc)
lyconf:
	sudo cp -f "$(DOTS)/ly/config.ini" /etc/ly/
nvim:
	@echo "Cloning Himstart"
	-@$(GG) $(URL)/himstart.nvim $(CONF)/nvim
	@echo "Done"
picom:
	$(call LINK,$(DOTS)/picom,$(CONF)/picom)
