input:
	-@$(PACMAN) -S libinput-gestures
	sudo gpasswd -a "$$USER" input
	libinput-gestures-setup start
	libinput-gestures-setup autostart
