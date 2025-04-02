#!/usr/bin/zsh

# Script to download and install JetBrains Mono Nerd Font on Pop!_OS
# ----------------------------------------------------------------------

# Set variables
readonly FONT_NAME="JetBrainsMono"
readonly TEMP_DIR=$(mktemp -d)
readonly FONT_VERSION="3.1.1" # Update this if a newer version is available
readonly DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip"
readonly FONT_DIR="$HOME/.local/share/fonts/${FONT_NAME}"
readonly SYSTEM_FONT_DIR="/usr/local/share/fonts/${FONT_NAME}"

# Output colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# Function to clean up on exit
function cleanup() {
  echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
  rm -rf "$TEMP_DIR"
  echo -e "${GREEN}Done.${NC}"
}

# Register the cleanup function to be called on exit
trap cleanup EXIT

# Check if unzip is installed
if ! command -v unzip > /dev/null; then
  echo -e "${YELLOW}The 'unzip' utility is required but not installed.${NC}"
  echo -e "${YELLOW}Installing unzip...${NC}"
  
  if sudo apt-get update && sudo apt-get install -y unzip; then
    echo -e "${GREEN}Successfully installed unzip.${NC}"
  else
    echo -e "${RED}Failed to install unzip. Please install it manually and try again.${NC}"
    exit 1
  fi
fi

# Check if curl is installed
if ! command -v curl > /dev/null; then
  echo -e "${YELLOW}The 'curl' utility is required but not installed.${NC}"
  echo -e "${YELLOW}Installing curl...${NC}"
  
  if sudo apt-get update && sudo apt-get install -y curl; then
    echo -e "${GREEN}Successfully installed curl.${NC}"
  else
    echo -e "${RED}Failed to install curl. Please install it manually and try again.${NC}"
    exit 1
  fi
fi

# Create font directories if they don't exist
echo -e "${YELLOW}Creating font directories if they don't exist...${NC}"
mkdir -p "$FONT_DIR"

# Download the font
echo -e "${YELLOW}Downloading JetBrains Mono Nerd Font v${FONT_VERSION}...${NC}"
if curl -L --progress-bar "$DOWNLOAD_URL" -o "$TEMP_DIR/${FONT_NAME}.zip"; then
  echo -e "${GREEN}Download completed successfully.${NC}"
else
  echo -e "${RED}Failed to download the font. Please check your internet connection and try again.${NC}"
  exit 1
fi

# Extract the font files
echo -e "${YELLOW}Extracting font files...${NC}"
if unzip -q "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR/extracted"; then
  echo -e "${GREEN}Extraction completed successfully.${NC}"
else
  echo -e "${RED}Failed to extract the font files.${NC}"
  exit 1
fi

# Copy font files to user fonts directory
echo -e "${YELLOW}Installing fonts to user directory...${NC}"
cp -f "$TEMP_DIR/extracted"/*.ttf "$FONT_DIR/"

# Ask user if they want to install system-wide
echo -e "${YELLOW}Do you want to install the fonts system-wide? (requires sudo) [y/N]${NC}"
read -r INSTALL_SYSTEM_WIDE

if [[ "$INSTALL_SYSTEM_WIDE" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Installing fonts system-wide...${NC}"
  
  if sudo mkdir -p "$SYSTEM_FONT_DIR"; then
    if sudo cp -f "$TEMP_DIR/extracted"/*.ttf "$SYSTEM_FONT_DIR/"; then
      echo -e "${GREEN}System-wide installation completed successfully.${NC}"
      sudo chmod 644 "$SYSTEM_FONT_DIR"/*.ttf
    else
      echo -e "${RED}Failed to copy font files to system directory.${NC}"
    fi
  else
    echo -e "${RED}Failed to create system font directory.${NC}"
  fi
fi

# Update font cache
echo -e "${YELLOW}Updating font cache...${NC}"
if fc-cache -f; then
  echo -e "${GREEN}Font cache updated successfully.${NC}"
else
  echo -e "${RED}Failed to update font cache.${NC}"
fi

# Verify installation
echo -e "${YELLOW}Verifying font installation...${NC}"
if fc-list | grep -i "$FONT_NAME"; then
  echo -e "${GREEN}JetBrains Mono Nerd Font has been successfully installed!${NC}"
  echo -e "${GREEN}Font name to use in Alacritty: 'JetBrains Mono Nerd Font'${NC}"
else
  echo -e "${RED}Font verification failed. The font may not have been installed correctly.${NC}"
  echo -e "${YELLOW}You might need to restart your system for the changes to take effect.${NC}"
fi

exit 0