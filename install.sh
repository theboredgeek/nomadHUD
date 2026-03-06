#!/usr/bin/env bash

# Define colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting nomadHUD installation on CachyOS...${NC}"

# 1. Update system and install all tracked dependencies
echo -e "${YELLOW}📦 Installing all dependencies...${NC}"
sudo pacman -S --needed \
    stow git hyprland kitty rofi swaync waypaper yazi dolphin \
    nm-connection-editor network-manager-applet \
    hyprpolkitagent xdg-desktop-portal-hyprland qt6-wayland \
    brightnessctl pamixer # Common utilities for bars/shells

# 2. Ensure the parent directory exists (for fresh clones)
mkdir -p "$HOME/.config"

# 3. Use Stow to link
# We use --adopt to handle any default configs CachyOS might have generated
echo -e "${YELLOW}🔗 Linking nomadHUD with GNU Stow...${NC}"
cd "$HOME/.dotfiles"
stow --adopt nomadHUD

# 4. Finalizing
echo -e "${GREEN}✅ nomadHUD is now linked and dependencies are installed!${NC}"
echo -e "${YELLOW}👉 Remember to check your hyprland.conf for 'exec-once' lines.${NC}"
