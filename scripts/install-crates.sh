#!/usr/bin/zsh

# Script to check if Cargo is installed and install useful crates
# --------------------------------------------------------------

# Set colors for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Define crates to install
readonly CRATES=(
  "atuin:Shell history management tool"
  "eza:Modern replacement for ls"
  "git-delta:Syntax-highlighting pager for git and diff output"
)

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to validate cargo installation
validate_cargo() {
  if ! command_exists cargo; then
    echo -e "${RED}Cargo is required but not found in PATH.${NC}"
    echo -e "${YELLOW}Please install Rust and Cargo first:${NC}"
    echo -e "${BLUE}https://www.rust-lang.org/tools/install${NC}"
    return 1
  fi
  return 0
}

# Function to check if a crate is already installed
is_crate_installed() {
  local crate_name=$1
  cargo install --list | grep -q "^$crate_name"
  return $?
}

# Function to print crate information
print_crates_info() {
  echo -e "${BLUE}Available crates for installation:${NC}\n"
  
  local index=1
  for crate_info in "${CRATES[@]}"; do
    local crate_name="${crate_info%%:*}"
    local crate_desc="${crate_info#*:}"
    
    if is_crate_installed "$crate_name"; then
      echo -e "${GREEN}[$index] $crate_name${NC} - $crate_desc ${YELLOW}[Already installed]${NC}"
    else
      echo -e "${CYAN}[$index] $crate_name${NC} - $crate_desc"
    fi
    
    ((index++))
  done
  echo
}

# Function to install a crate
install_crate() {
  local crate_name=$1
  
  if is_crate_installed "$crate_name"; then
    echo -e "${YELLOW}$crate_name is already installed. Would you like to update it? [y/N]${NC}"
    read -r UPDATE_CRATE
    
    if [[ "$UPDATE_CRATE" =~ ^[Yy]$ ]]; then
      echo -e "${BLUE}Updating $crate_name...${NC}"
      if cargo install "$crate_name" --force; then
        echo -e "${GREEN}Successfully updated $crate_name.${NC}"
      else
        echo -e "${RED}Failed to update $crate_name.${NC}"
        return 1
      fi
    else
      echo -e "${BLUE}Skipping update for $crate_name.${NC}"
    fi
  else
    echo -e "${BLUE}Installing $crate_name...${NC}"
    if cargo install "$crate_name"; then
      echo -e "${GREEN}Successfully installed $crate_name.${NC}"
    else
      echo -e "${RED}Failed to install $crate_name.${NC}"
      return 1
    fi
  fi
  
  return 0
}

# Function to install all selected crates
install_all_crates() {
  local installed_count=0
  local failed_crates=()
  
  for crate_info in "${CRATES[@]}"; do
    local crate_name="${crate_info%%:*}"
    
    echo -e "\n${YELLOW}Processing $crate_name...${NC}"
    if install_crate "$crate_name"; then
      ((installed_count++))
    else
      failed_crates+=("$crate_name")
    fi
  done
  
  echo
  echo -e "${GREEN}Installation summary:${NC}"
  echo -e "${BLUE}Total crates processed: ${#CRATES[@]}${NC}"
  echo -e "${GREEN}Successfully installed/updated: $installed_count${NC}"
  
  if ((${#failed_crates[@]} > 0)); then
    echo -e "${RED}Failed installations: ${#failed_crates[@]}${NC}"
    echo -e "${RED}Failed crates: ${failed_crates[*]}${NC}"
  fi
}

# Function to install selected crates
install_selected_crates() {
  local selected_indices=($@)
  local installed_count=0
  local failed_crates=()
  
  for index in "${selected_indices[@]}"; do
    # Validate index
    if ! [[ "$index" =~ ^[0-9]+$ ]] || ((index < 1 || index > ${#CRATES[@]})); then
      echo -e "${RED}Invalid selection: $index. Skipping.${NC}"
      continue
    fi
    
    local crate_info="${CRATES[$index-1]}"
    local crate_name="${crate_info%%:*}"
    
    echo -e "\n${YELLOW}Processing $crate_name...${NC}"
    if install_crate "$crate_name"; then
      ((installed_count++))
    else
      failed_crates+=("$crate_name")
    fi
  done
  
  echo
  echo -e "${GREEN}Installation summary:${NC}"
  echo -e "${BLUE}Total crates selected: ${#selected_indices[@]}${NC}"
  echo -e "${GREEN}Successfully installed/updated: $installed_count${NC}"
  
  if ((${#failed_crates[@]} > 0)); then
    echo -e "${RED}Failed installations: ${#failed_crates[@]}${NC}"
    echo -e "${RED}Failed crates: ${failed_crates[*]}${NC}"
  fi
}

# Function to display post-installation information
display_post_install_info() {
  echo -e "\n${BLUE}===== Post-Installation Information =====${NC}"
  
  # Atuin setup info
  if is_crate_installed "atuin"; then
    echo -e "\n${YELLOW}Atuin Setup:${NC}"
    echo -e "${CYAN}To set up atuin, run:${NC}"
    echo -e "  atuin register      ${BLUE}# Create a new account${NC}"
    echo -e "  # or"
    echo -e "  atuin login         ${BLUE}# Login to existing account${NC}"
    echo -e "${CYAN}Then add to your ~/.zshrc:${NC}"
    echo -e "  eval \"\$(atuin init zsh)\""
  fi
  
  # Eza setup info
  if is_crate_installed "eza"; then
    echo -e "\n${YELLOW}Eza Setup:${NC}"
    echo -e "${CYAN}Add to your ~/.zshrc:${NC}"
    echo -e "  alias ls='eza'"
    echo -e "  alias ll='eza -la'"
    echo -e "  alias lt='eza --tree'"
  fi
  
  # Git-delta setup info
  if is_crate_installed "git-delta"; then
    echo -e "\n${YELLOW}Git-delta Setup:${NC}"
    echo -e "${CYAN}Add to your ~/.gitconfig:${NC}"
    echo -e "  [core]"
    echo -e "      pager = delta"
    echo -e "  [interactive]"
    echo -e "      diffFilter = delta --color-only"
    echo -e "  [delta]"
    echo -e "      navigate = true"
    echo -e "      light = false"
    echo -e "      side-by-side = true"
    echo -e "  [merge]"
    echo -e "      conflictstyle = diff3"
    echo -e "  [diff]"
    echo -e "      colorMoved = default"
  fi
  
  echo -e "\n${GREEN}Remember to restart your shell after making configuration changes!${NC}"
}

# Main script execution starts here

# Check if cargo is installed
echo -e "${BLUE}Checking if Cargo is installed...${NC}"

if ! validate_cargo; then
  exit 1
fi

echo -e "${GREEN}Cargo is installed.${NC}"
echo -e "${BLUE}Cargo version: $(cargo --version)${NC}\n"

# Ask user if they want to install crates
echo -e "${YELLOW}Would you like to install additional useful Cargo crates? [y/N]${NC}"
read -r INSTALL_CRATES

if [[ ! "$INSTALL_CRATES" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}No crates will be installed. Exiting.${NC}"
  exit 0
fi

# Display available crates
print_crates_info

# Ask installation method
echo -e "${YELLOW}Installation options:${NC}"
echo -e "${CYAN}[1] Install all crates${NC}"
echo -e "${CYAN}[2] Select specific crates to install${NC}"
echo -e "${CYAN}[3] Cancel installation${NC}"
echo -e "${YELLOW}Enter your choice [1-3]:${NC}"
read -r INSTALL_CHOICE

case "$INSTALL_CHOICE" in
  1)
    install_all_crates
    display_post_install_info
    ;;
  2)
    echo -e "${YELLOW}Enter the numbers of the crates you want to install (space-separated):${NC}"
    read -r -A SELECTED_INDICES
    if ((${#SELECTED_INDICES[@]} > 0)); then
      install_selected_crates "${SELECTED_INDICES[@]}"
      display_post_install_info
    else
      echo -e "${BLUE}No crates selected. Exiting.${NC}"
    fi
    ;;
  *)
    echo -e "${BLUE}Installation cancelled. Exiting.${NC}"
    ;;
esac

exit 0
