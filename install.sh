#!/usr/bin/env bash

# Define colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting nomadHUD installation on CachyOS...${NC}"

# 1. Update system and install all tracked dependencies
echo -e "${YELLOW}📦 Installing all dependencies...${NC}"
sudo pacman -S --needed \
    stow git hyprland kitty rofi swaync waypaper yazi dolphin \
    nm-connection-editor network-manager-applet \
    hyprpolkitagent xdg-desktop-portal-hyprland qt6-wayland \
    brightnessctl pamixer \
    quickshell qt6-declarative qt6-svg  # Added Quickshell dependencies

# 2. Cleanup existing vanilla configs
# This prevents Stow from failing or accidentally "adopting" the wrong files
echo -e "${YELLOW}🧹 Removing default/vanilla configs to prevent conflicts...${NC}"
rm -rf ~/.config/hypr ~/.config/kitty ~/.config/rofi ~/.config/swaync ~/.config/waypaper ~/.config/yazi ~/.config/dolphinrc ~/.config/quickshell

# 3. Ensure the parent directory exists
mkdir -p "$HOME/.config"

# 4. Use Stow to link
echo -e "${YELLOW}🔗 Linking nomadHUD with GNU Stow...${NC}"
cd "$HOME/.dotfiles" || { echo -e "${RED}❌ Error: ~/.dotfiles directory not found!${NC}"; exit 1; }

stow -v nomadHUD

# 5. Finalizing
echo -e "${GREEN}✅ nomadHUD is now linked!${NC}"
echo -e "${YELLOW}👉 If you are on a new account, run 'hyprctl reload' or restart Hyprland.${NC}"
