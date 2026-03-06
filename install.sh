#!/usr/bin/env bash

# Define colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting nomadHUD installation on CachyOS...${NC}"

# 1. Directory Check
if [[ "$PWD" != "$HOME/.dotfiles/nomadHUD" ]]; then
    echo -e "${RED}❌ Error: Please run this script from ~/.dotfiles/nomadHUD${NC}"
    exit 1
fi

# 2. Update system and install dependencies
# We switch to quickshell-git to resolve SIGSEGV issues on CachyOS/Arch
echo -e "${YELLOW}📦 Installing all dependencies (switching to quickshell-git)...${NC}"

# Install standard packages first
sudo pacman -S --needed \
    stow git hyprland kitty rofi swaync waypaper yazi dolphin \
    nm-connection-editor network-manager-applet \
    hyprpolkitagent xdg-desktop-portal-hyprland qt6-wayland \
    brightnessctl pamixer qt6-declarative qt6-svg mpv mesa jq

# Use yay to install/rebuild the git version of quickshell
if command -v yay &> /dev/null; then
    yay -S --needed quickshell-git
else
    echo -e "${RED}⚠️  yay not found. Please install quickshell-git manually.${NC}"
fi

# 3. Cleanup existing vanilla configs and Quickshell cache
echo -e "${YELLOW}🧹 Cleaning up configs and engine cache...${NC}"
rm -rf ~/.config/hypr ~/.config/kitty ~/.config/rofi ~/.config/swaync \
       ~/.config/waypaper ~/.config/yazi ~/.config/dolphinrc ~/.config/quickshell
rm -rf ~/.cache/quickshell/*

# 4. Ensure the parent config directory exists
mkdir -p "$HOME/.config"

# 5. Use Stow to link
echo -e "${YELLOW}🔗 Linking nomadHUD with GNU Stow...${NC}"
cd "$HOME/.dotfiles" || { echo -e "${RED}❌ Error: ~/.dotfiles directory not found!${NC}"; exit 1; }

stow -v nomadHUD

# 6. Finalizing
echo -e "${GREEN}✅ nomadHUD is now linked and Quickshell-git is installed!${NC}"
echo -e "${YELLOW}👉 Run 'quickshell -c ~/.config/quickshell' to test.${NC}"
