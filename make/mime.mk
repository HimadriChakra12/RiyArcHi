IMAGE = rsxiv.desktop
VIDEO = mpv.desktop
MUSIC = lollypop.desktop
FILE = rdfm.desktop

mime:
	@echo "Setting rsxiv as default image viewer..."
	@for type in \
		image/jpeg \
		image/png \
		image/gif \
		image/webp \
		image/svg+xml \
		image/bmp \
		image/tiff \
		image/x-xpixmap \
		image/avif; do \
			xdg-mime default $(IMAGE) "$$type"; \
		done
	@echo "Setting MPV as default video player..."
	@for type in \
		video/mp4 \
		video/x-matroska \
		video/x-msvideo \
		video/webm \
		video/quicktime \
		video/x-ms-wmv \
		video/mpeg \
		video/3gpp \
		video/ogg; do \
			xdg-mime default $(VIDEO) "$$type"; \
		done
	@echo "Setting Lollypop as default music player..."
	@for type in \
		audio/mpeg \
		audio/x-wav \
		audio/ogg \
		audio/flac \
		audio/aac \
		audio/mp4 \
		audio/x-m4a \
		audio/x-ms-wma \
		audio/webm; do \
			xdg-mime default $(MUSIC) "$$type"; \
		done
	@echo "Setting rdfm as the default file manager..."
	@for type in \
		inode/directory \
		application/x-gnome-saved-search; do \
			xdg-mime default $(FILE) "$$type"; \
		done
	@echo "All defaults configured successfully!"
