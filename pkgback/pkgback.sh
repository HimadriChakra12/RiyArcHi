#!/bin/bash
# setup.sh - Quick setup for pkgback

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     pkgback - Auto Package Tracker        ║${NC}"
echo -e "${BLUE}║            Setup Script                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Detect shell
SHELL_RC=""
SHELL_NAME=""

if [[ -n "$BASH_VERSION" ]]; then
    SHELL_NAME="bash"
    SHELL_RC="$HOME/.bashrc"
elif [[ -n "$ZSH_VERSION" ]]; then
    SHELL_NAME="zsh"
    SHELL_RC="$HOME/.zshrc"
else
    echo -e "${RED}Could not detect shell. Using .bashrc${NC}"
    SHELL_NAME="bash"
    SHELL_RC="$HOME/.bashrc"
fi

echo -e "${GREEN}Detected shell: $SHELL_NAME${NC}"
echo -e "${BLUE}Config file: $SHELL_RC${NC}"
echo ""

# Copy pkgback to user directory
PKGBACK_INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$PKGBACK_INSTALL_DIR"

echo -e "${BLUE}Installing pkgback...${NC}"
cp pkgback "$PKGBACK_INSTALL_DIR/pkgback"
chmod +x "$PKGBACK_INSTALL_DIR/pkgback"
echo -e "${GREEN}✓ Copied to: $PKGBACK_INSTALL_DIR/pkgback${NC}"
echo ""

# Check if already in rc file
if grep -q "source.*pkgback" "$SHELL_RC" 2>/dev/null; then
    echo -e "${YELLOW}pkgback is already in your $SHELL_RC${NC}"
    echo "Do you want to update it? [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Remove old lines
        sed -i '/source.*pkgback/d' "$SHELL_RC"
    else
        echo "Skipping $SHELL_RC modification"
        exit 0
    fi
fi

# Add to rc file
echo -e "${BLUE}Adding to $SHELL_RC...${NC}"

cat >> "$SHELL_RC" << 'EOF'

# pkgback - Automatic package tracking
if [[ -f "$HOME/.local/bin/pkgback" ]]; then
    source "$HOME/.local/bin/pkgback"
fi
EOF

echo -e "${GREEN}✓ Added source line to $SHELL_RC${NC}"
echo ""

# Install helper tools
echo -e "${BLUE}Installing helper tools...${NC}"

# Install installation-viewer if available
if [[ -f "installation-viewer" ]]; then
    cp installation-viewer "$PKGBACK_INSTALL_DIR/pkgback-view"
    chmod +x "$PKGBACK_INSTALL_DIR/pkgback-view"
    echo -e "${GREEN}✓ Installed pkgback-view${NC}"
fi

# Install pkg-analyzer if available
if [[ -f "pkg-analyzer" ]]; then
    cp pkg-analyzer "$PKGBACK_INSTALL_DIR/pkgback-analyze"
    chmod +x "$PKGBACK_INSTALL_DIR/pkgback-analyze"
    echo -e "${GREEN}✓ Installed pkgback-analyze${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Setup Complete! ✓                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Reload your shell to activate:${NC}"
echo -e "  ${BLUE}source $SHELL_RC${NC}"
echo -e "  or just open a new terminal"
echo ""
echo -e "${BLUE}After reloading, just use your package manager normally:${NC}"
echo -e "  ${GREEN}yay -S firefox${NC}           # Automatically tracked!"
echo -e "  ${GREEN}paru -S neovim${NC}          # Automatically tracked!"
echo -e "  ${GREEN}pacman -S git${NC}           # Automatically tracked!"
echo ""
echo -e "${BLUE}Commands:${NC}"
echo -e "  ${GREEN}pkgback status${NC}          # Check status"
echo -e "  ${GREEN}pkgback list${NC}            # List recent installations"
echo -e "  ${GREEN}pkgback export${NC}          # Export package list"
echo -e "  ${GREEN}pkgback help${NC}            # Show all commands"
echo ""
echo -e "${BLUE}Tracked files location:${NC}"
echo -e "  ~/.local/share/pkgback/"
echo ""
