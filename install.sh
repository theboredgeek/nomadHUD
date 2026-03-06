#!/usr/bin/env bash

# Define colors for output
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting nomadHUD installation...${NC}"

# 1. Install Dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
sudo pacman -S --needed stow git hyprland waybar kitty rofi

# 2. Prepare the target directory
# If ~/.config/hypr exists and isn't a symlink, back it up
if [ -d "$HOME/.config/hypr" ] && [ ! -L "$HOME/.config/hypr" ]; then
    echo -e "${YELLOW}💾 Backing up existing hypr config to ~/.config/hypr.backup${NC}"
    mv "$HOME/.config/hypr" "$HOME/.config/hypr.backup"
fi

# 3. Use Stow to link
echo -e "${YELLOW}🔗 Linking nomadHUD with GNU Stow...${NC}"
cd "$HOME/.dotfiles"
stow nomadHUD

echo -e "${YELLOW}✅ nomadHUD is now linked! Restart Hyprland (Super+M) to see changes.${NC}"
