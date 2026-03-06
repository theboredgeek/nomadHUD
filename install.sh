#!/usr/bin/env bash

# Define colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting nomadHUD installation on CachyOS...${NC}"

# 1. Directory Check
# Ensures the script is being run from the actual repo location
if [[ "$PWD" != "$HOME/.dotfiles/nomadHUD" ]]; then
    echo -e "${RED}❌ Error: Please run this script from ~/.dotfiles/nomadHUD${NC}"
    exit 1
fi

# 2. Update system and install all tracked dependencies
echo -e "${YELLOW}📦 Installing all dependencies...${NC}"
sudo pacman -S --needed \
    stow git hyprland kitty rofi swaync waypaper yazi dolphin \
    nm-connection-editor network-manager-applet \
    hyprpolkitagent xdg-desktop-portal-hyprland qt6-wayland \
    brightnessctl pamixer quickshell qt6-declarative qt6-svg \
    mpv mesa

# 3. Cleanup existing vanilla configs
# This prevents Stow from failing or accidentally "adopting" the wrong files
echo -e "${YELLOW}🧹 Removing default/vanilla configs to prevent conflicts...${NC}"
rm -rf ~/.config/hypr ~/.config/kitty ~/.config/rofi ~/.config/swaync \
       ~/.config/waypaper ~/.config/yazi ~/.config/dolphinrc ~/.config/quickshell

# 4. Ensure the parent config directory exists
mkdir -p "$HOME/.config"

# 5. Use Stow to link
echo -e "${YELLOW}🔗 Linking nomadHUD with GNU Stow...${NC}"
cd "$HOME/.dotfiles" || { echo -e "${RED}❌ Error: ~/.dotfiles directory not found!${NC}"; exit 1; }

# Stow nomadHUD package into the home directory
stow -v nomadHUD

# 6. Finalizing
echo -e "${GREEN}✅ nomadHUD is now linked!${NC}"
echo -e "${YELLOW}👉 Restart Hyprland or run 'hyprctl reload' to activate the HUD.${NC}"
