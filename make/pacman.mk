PACMAN      = sudo pacman
NEED        = --needed
NOC         = --noconfirm

REFARG 		= \
			  --country "Singapore,India,Japan,South Korea,Hong Kong" \
			  --protocol https \
			  --latest 20 \
			  --sort rate \
			  --threads 20 \
			  --save /etc/pacman.d/mirrorlist

pacinit:
	sudo cp $(HOMEDIR)/.dotfiles/pacman.conf /etc/pacman.conf

reflector: pacinit
	@$(PACMAN) -Syyu
	@echo "Installing reflector..."
	@$(PACMAN) -S $(NOC) reflector
	@echo "Backing up current mirrorlist..."
	@sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
	@echo "Generating optimized mirrorlist..."
	@sudo reflector $(REFARG)
	@echo "Enabling reflector systemd timer..."
	@$(CTL) enable reflector.timer
	@$(CTL) start reflector.timer
	@$(PACMAN) -Syyu
	@echo "Mirrorlist updated and automatic updates enabled."
