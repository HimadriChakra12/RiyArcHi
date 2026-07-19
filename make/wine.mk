SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c

PREFIX ?= $(HOMEDIR)/winegames
NAME   ?= $(notdir $(PREFIX))


PKG_MGR := $(shell \
  if command -v pacman >/dev/null 2>&1; then echo pacman; \
  elif command -v apt >/dev/null 2>&1; then echo apt; \
  elif command -v dnf >/dev/null 2>&1; then echo dnf; \
  elif command -v zypper >/dev/null 2>&1; then echo zypper; \
  else echo unknown; fi)

GPU := $(shell \
  gpu_info=$$(lspci 2>/dev/null | grep -E "VGA|3D" | head -n1); \
  if echo "$$gpu_info" | grep -qi nvidia; then echo nvidia; \
  elif echo "$$gpu_info" | grep -qi amd; then echo amd; \
  elif echo "$$gpu_info" | grep -qi intel; then echo intel; \
  else echo unknown; fi)

.PHONY: all detect sudo-check install \
        install-arch install-debian install-fedora install-opensuse \
        gpu-arch verify clean help

wine: banner detect sudo-check install verify done

banner:
	@echo "╔════════════════════════════════════════╗"
	@echo "║   Wine Base Installer v1.0             ║"
	@echo "╚════════════════════════════════════════╝"
	@echo

detect:
	@echo "Detected package manager: $(PKG_MGR)"
	@echo "Detected GPU: $(GPU)"
	@echo

sudo-check:
	@if ! sudo -v; then \
		echo "[ERROR] sudo access required"; \
		exit 1; \
	fi

install:
ifeq ($(PKG_MGR),pacman)
	@$(MAKE) -f $(MAKEFILE_LIST) install-arch
else ifeq ($(PKG_MGR),apt)
	@$(MAKE) -f $(MAKEFILE_LIST) install-debian
else ifeq ($(PKG_MGR),dnf)
	@$(MAKE) -f $(MAKEFILE_LIST) install-fedora
else ifeq ($(PKG_MGR),zypper)
	@$(MAKE) -f $(MAKEFILE_LIST) install-opensuse
else
	@echo "[ERROR] Unsupported package manager"; \
	echo; \
	echo "Please install manually:"; \
	echo "  - Wine (wine-staging preferred)"; \
	echo "  - winetricks"; \
	echo "  - Vulkan drivers for your GPU"; \
	exit 1
endif

install-arch:
	@echo "[PKG] Installing for Arch Linux..."
	sudo pacman -Syu --needed --noconfirm  wine-staging  winetricks  lib32-gnutls  lib32-mesa  vulkan-icd-loader  lib32-vulkan-icd-loader  gamemode  lib32-gamemode
	@$(MAKE) -f $(MAKEFILE_LIST) gpu-arch

gpu-arch:
ifeq ($(GPU),amd)
	@echo "🎮 Installing AMD GPU drivers..."
	sudo pacman -S --needed --noconfirm  vulkan-radeon lib32-vulkan-radeon 
		lib32-mesa-vdpau
else ifeq ($(GPU),nvidia)
	@echo "🎮 Installing NVIDIA GPU drivers..."
	sudo pacman -S --needed --noconfirm  nvidia-utils lib32-nvidia-utils  vulkan-icd-loader lib32-vulkan-icd-loader
else ifeq ($(GPU),intel)
	@echo "🎮 Installing Intel GPU drivers..."
	sudo pacman -S --needed --noconfirm  vulkan-intel lib32-vulkan-intel
else
	@:
endif

install-debian:
	@echo "[PKG] Installing for Debian/Ubuntu..."
	sudo dpkg --add-architecture i386 || true
	sudo apt update
	sudo apt install -y wine64 wine32 winetricks libvulkan1 libvulkan1:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 gamemode
ifeq ($(GPU),nvidia)
	sudo apt install -y nvidia-vulkan-icd nvidia-vulkan-icd:i386 || true
endif

install-fedora:
	@echo "[PKG] Installing for Fedora..."
	sudo dnf install -y wine winetricks vulkan-loader vulkan-loader.i686 mesa-vulkan-drivers mesa-vulkan-drivers.i686 gamemode
ifeq ($(GPU),nvidia)
	sudo dnf install -y xorg-x11-drv-nvidia-libs.i686 || true
endif

install-opensuse:
	@echo "[PKG] Installing for openSUSE..."
	sudo zypper install -y wine winetricks libvulkan1 libvulkan1-32bit gamemode

verify:
	@echo
	@echo "🔍 Verifying installation..."
	@if ! command -v wine >/dev/null; then \
		echo "[ERROR] Wine installation failed"; \
		exit 1; \
	fi
	@if ! command -v winetricks >/dev/null; then \
		echo "[ERROR] winetricks installation failed"; \
		exit 1; \
	fi
	@echo "[DONE] Wine version: $$(wine --version)"
	@echo "[DONE] winetricks installed"
	@if command -v vulkaninfo >/dev/null 2>&1; then \
		vk_ver=$$(vulkaninfo --summary 2>/dev/null | grep -i "instance version" | head -1 || echo "installed"); \
		echo "[DONE] Vulkan: $$vk_ver"; \
	fi

done:
	@echo
	@echo "╔══════════════════════════════════════╗"
	@echo "║   Wine Base Installation Complete    ║"
	@echo "╚══════════════════════════════════════╝"
	@echo


wine-prefix:
	@echo "╔════════════════════════════════════════╗"
	@echo "║   Wine Prefix Creator v1.1             ║"
	@echo "╚════════════════════════════════════════╝"
	@echo
	@echo "Prefix: $(PREFIX)"
	@echo "Name:   $(NAME)"
	@echo
	@if [[ -d "$(PREFIX)" ]]; then \
		echo "⚠️  Prefix already exists: $(PREFIX)"; \
		read -rp "Overwrite? [y/N] " response; \
		if [[ ! "$$response" =~ ^[Yy]$$ ]]; then \
			echo "Aborted."; \
			exit 0; \
		fi; \
		rm -rf "$(PREFIX)"; \
	fi
	@echo "[PREFIX] Creating Wine prefix..."
	@mkdir -p "$(PREFIX)"
	@export WINEPREFIX="$(PREFIX)"; \
	export WINEARCH=win64; \
	export WINEDLLOVERRIDES="mscoree,mshtml="; \
	wineboot --init >/dev/null 2>&1
	@echo "[DONE] Prefix initialized"
	@echo
	@echo "[FONT] Installing core fonts..."
	@WINEPREFIX="$(PREFIX)" winetricks -q corefonts >/dev/null 2>&1 || echo "⚠️  Font installation warning (non-critical)"
	@echo "[DONE] Fonts installed"
	@echo
	@echo "🎮 Detected GPU: $(GPU)"
	@vk_icd=""; \
	case "$(GPU)" in \
		intel) for p in /usr/share/vulkan/icd.d/intel_icd.x86_64.json /usr/share/vulkan/icd.d/intel_icd.json; do [[ -f "$$p" ]] && vk_icd="$$p" && break; done ;; \
		amd) for p in /usr/share/vulkan/icd.d/radeon_icd.x86_64.json /usr/share/vulkan/icd.d/radeon_icd.json; do [[ -f "$$p" ]] && vk_icd="$$p" && break; done ;; \
		nvidia) [[ -f /usr/share/vulkan/icd.d/nvidia_icd.json ]] && vk_icd="/usr/share/vulkan/icd.d/nvidia_icd.json" ;; \
	esac; \
	[[ -n "$$vk_icd" ]] && echo "[VULKAN] Vulkan ICD: $$vk_icd"; \
	cat > "$(PREFIX)/prefix-info.txt" <<-EOF
	Wine Prefix Configuration
	=========================
	Name:         $(NAME)
	Path:         $(PREFIX)
	Architecture: win64
	GPU:          $(GPU)
	Vulkan ICD:   $$vk_icd
	Created:      $$(date -u +"%Y-%m-%d %H:%M:%S UTC")
	Wine Version: $$(wine --version 2>/dev/null || echo "unknown")
	EOF
	cat > "$(PREFIX)/env.sh" <<-EOF
	#!/usr/bin/env bash
	# Base Wine environment — source this before running Wine
	export WINEPREFIX="$(PREFIX)"
	export WINEARCH=win64
	export WINEDEBUG=-all
	export WINE_GPU="$(GPU)"
	
	# Vulkan ICD
	[[ -n "$$vk_icd" ]] && export VK_ICD_FILENAMES="$$vk_icd"
	
	# ── Intel-specific fixes ───────────────────────────────────────────────────
	if [[ "$(GPU)" == "intel" ]]; then
	  # Expose full GL 4.6 / GLSL 460 so DXVK doesn't fall back to SW renderer
	  export MESA_GL_VERSION_OVERRIDE=4.6
	  export MESA_GLSL_VERSION_OVERRIDE=460
	  export mesa_glthread=true
	  export MESA_VK_WSI_PRESENT_MODE=mailbox
	  export INTEL_DEBUG=nofc
	fi
	EOF
	@chmod +x "$(PREFIX)/env.sh"
	@echo
	@echo "╔══════════════════════════════════════╗"
	@echo "║   Wine Prefix Created Successfully   ║"
	@echo "╚══════════════════════════════════════╝"
	@echo
	@echo "Prefix:      $(PREFIX)"
	@echo "Config:      $(PREFIX)/prefix-info.txt"
	@echo "Environment: $(PREFIX)/env.sh"


verify:
	@echo
	@echo "🔍 Verifying installation..."
	@if ! command -v wine >/dev/null; then \
		echo "[ERROR] Wine installation failed"; \
		exit 1; \
	fi
	@if ! command -v winetricks >/dev/null; then \
		echo "[Error] winetricks installation failed"; \
		exit 1; \
	fi
	@echo "[DONE] Wine version: $$(wine --version)"
	@echo "[DONE] winetricks installed"
	@if command -v vulkaninfo >/dev/null 2>&1; then \
		vk_ver=$$(vulkaninfo --summary 2>/dev/null | grep -i "instance version" | head -1 || echo "installed"); \
		echo "[DONE] Vulkan: $$vk_ver"; \
	fi

clean:
	@echo "Nothing to clean."

help:
	@echo "Targets:"
	@echo "  all      - detect, install, and verify (default)"
	@echo "  detect   - print detected package manager and GPU"
	@echo "  install  - install Wine + deps for the detected distro"
	@echo "  verify   - verify wine/winetricks/vulkan are present"
	@echo "  wine-prefix - create a Wine prefix (PREFIX=..., NAME=...)"
	@echo "  clean    - no-op"

