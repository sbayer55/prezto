#!/usr/bin/env zsh

# Script to install development tools using preferred package manager
# ------------------------------------------------------------------

# Define the list of packages to install
readonly PACKAGES=(
  "midnight-commander:Visual file manager with Norton Commander interface"
  "wget:Internet file retriever"
  "git-delta:Syntax-highlighting pager for git and diff output"
  "fd:Simple, fast and user-friendly alternative to find"
  "eza:Modern alternative to ls with more features and better defaults"
  "bat:Cat clone with syntax highlighting and Git integration"
  "ollama:Run large language models locally"
  "fish:User-friendly command-line shell"
  "tree:Display directories as trees"
  "htop:Interactive process viewer"
  "gnupg:GNU Privacy Guard: free implementation of the OpenPGP standard"
  "neovim:Hyperextensible Vim-based text editor"
  "ripgrep:Fast, recursive grep alternative"
  "jq:Lightweight and flexible command-line JSON processor"
  "fzf:Command-line fuzzy finder"
  "zoxide:Smarter cd command with learning capabilities"
  "btop:Resource monitor with responsive UI"
  "bottom:Graphical process/system monitor similar to top"
  "atuin:Magical shell history"
  "zsh-autosuggestions:Fish-like autosuggestions for zsh"
)

# Package name mappings for different package managers
# No mappings - using same package names across all package managers

# Set colors for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to detect available package managers
detect_package_managers() {
  local available_managers=()
  
  if command_exists brew; then
    available_managers+=("brew:Homebrew")
  fi
  
  if command_exists cargo; then
    available_managers+=("cargo:Rust Cargo")
  fi
  
  if command_exists apt || command_exists apt-get; then
    available_managers+=("apt:APT (Debian/Ubuntu)")
  fi
  
  if command_exists dnf; then
    available_managers+=("dnf:DNF (Fedora/RHEL)")
  fi
  
  if command_exists pacman; then
    available_managers+=("pacman:Pacman (Arch Linux)")
  fi
  
  if command_exists zypper; then
    available_managers+=("zypper:Zypper (openSUSE)")
  fi
  
  if command_exists apk; then
    available_managers+=("apk:APK (Alpine Linux)")
  fi
  
  echo "${available_managers[@]}"
}

# Function to install with Homebrew
install_with_brew() {
  echo -e "${BLUE}Installing packages with Homebrew...${NC}"
  
  # Disable analytics
  brew analytics off
  
  # Check for updates
  echo -e "${BLUE}Updating Homebrew...${NC}"
  brew update
  
  local success_count=0
  local failed_packages=()
  local skipped_packages=()
  
  for package_info in "${PACKAGES[@]}"; do
    local package_name="${package_info%%:*}"
    
    echo -e "\n${YELLOW}Processing $package_name...${NC}"
    
    if brew list "$package_name" &>/dev/null; then
      echo -e "${GREEN}$package_name is already installed. Skipping.${NC}"
      skipped_packages+=("$package_name")
      ((success_count++))  # Count as success since it's already installed
    else
      echo -e "${BLUE}Installing $package_name...${NC}"
      if brew install "$package_name"; then
        echo -e "${GREEN}Successfully installed $package_name.${NC}"
        ((success_count++))
      else
        echo -e "${RED}Failed to install $package_name.${NC}"
        failed_packages+=("$package_name")
      fi
    fi
  done
  
  # Print installation summary
  echo -e "\n${GREEN}Installation summary:${NC}"
  echo -e "${BLUE}Total packages processed: ${#PACKAGES[@]}${NC}"
  echo -e "${GREEN}Successfully installed: $success_count${NC}"
  echo -e "${CYAN}Already installed (skipped): ${#skipped_packages[@]}${NC}"
  
  if ((${#skipped_packages[@]} > 0)); then
    echo -e "${CYAN}Skipped packages: ${skipped_packages[*]}${NC}"
  fi
  
  if ((${#failed_packages[@]} > 0)); then
    echo -e "${RED}Failed installations: ${#failed_packages[@]}${NC}"
    echo -e "${RED}Failed packages: ${failed_packages[*]}${NC}"
  fi
}

# Function to install with Cargo
install_with_cargo() {
  local packages=("$@")
  local success_count=0
  local failed_packages=()
  local skipped_packages=()
  
  echo -e "${BLUE}Installing packages with Cargo...${NC}"
  
  for package in "${packages[@]}"; do
    echo -e "\n${YELLOW}Processing $package...${NC}"
    
    if cargo install --list | grep -q "^$package "; then
      echo -e "${GREEN}$package is already installed. Skipping.${NC}"
      skipped_packages+=("$package")
      ((success_count++))  # Count as success since it's already installed
    else
      echo -e "${BLUE}Installing $package...${NC}"
      if cargo install "$package"; then
        echo -e "${GREEN}Successfully installed $package.${NC}"
        ((success_count++))
      else
        echo -e "${RED}Failed to install $package.${NC}"
        failed_packages+=("$package")
      fi
    fi
  done
  
  # Print installation summary
  if ((${#packages[@]} > 0)); then
    echo -e "\n${GREEN}Cargo installation summary:${NC}"
    echo -e "${BLUE}Total packages processed: ${#packages[@]}${NC}"
    echo -e "${GREEN}Successfully installed: $success_count${NC}"
    echo -e "${CYAN}Already installed (skipped): ${#skipped_packages[@]}${NC}"
    
    if ((${#skipped_packages[@]} > 0)); then
      echo -e "${CYAN}Skipped packages: ${skipped_packages[*]}${NC}"
    }
    
    if ((${#failed_packages[@]} > 0)); then
      echo -e "${RED}Failed installations: ${#failed_packages[@]}${NC}"
      echo -e "${RED}Failed packages: ${failed_packages[*]}${NC}"
    fi
  fi
}

# Function to install with native Linux package manager
install_with_native() {
  local package_manager=$1
  local all_packages=()
  local failed_packages=()
  local success_count=0
  
  echo -e "${BLUE}Installing packages with $package_manager...${NC}"
  
  case "$package_manager" in
    apt)
      # Update package lists
      sudo apt update
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        
        # Check if already installed
        if dpkg -l | grep -q "^ii.*$package_name "; then
          echo -e "${GREEN}$package_name is already installed. Skipping.${NC}"
          skipped_packages+=("$package_name")
          ((success_count++))
          continue
        fi
        
        # Try to install individual packages so we can track success/failure
        echo -e "\n${YELLOW}Installing $package_name with apt...${NC}"
        if sudo apt install -y "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with apt.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    dnf)
      # Update package lists
      sudo dnf check-update
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        
        echo -e "\n${YELLOW}Installing $package_name with dnf...${NC}"
        if sudo dnf install -y "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with dnf.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    pacman)
      # Update package lists
      sudo pacman -Sy
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        
        echo -e "\n${YELLOW}Installing $package_name with pacman...${NC}"
        if sudo pacman -S --needed --noconfirm "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with pacman.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    zypper)
      # Update package lists
      sudo zypper refresh
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        
        echo -e "\n${YELLOW}Installing $package_name with zypper...${NC}"
        if sudo zypper install -y "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with zypper.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    apk)
      # Update package lists
      sudo apk update
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        
        echo -e "\n${YELLOW}Installing $package_name with apk...${NC}"
        if sudo apk add "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with apk.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
  esac
  
  echo -e "\n${GREEN}Installation with $package_manager completed.${NC}"
  echo -e "${BLUE}Total packages processed: ${#PACKAGES[@]}${NC}"
  echo -e "${GREEN}Successfully installed: $success_count${NC}"
  
  if ((${#failed_packages[@]} > 0)); then
    echo -e "${RED}Failed installations: ${#failed_packages[@]}${NC}"
    echo -e "${RED}Failed packages: ${failed_packages[*]}${NC}"
  fi
  
  # Offer to try installing failed packages with Cargo if available
  if ((${#failed_packages[@]} > 0)) && command_exists cargo; then
    echo -e "\n${YELLOW}Some packages failed to install with $package_manager.${NC}"
    echo -e "${YELLOW}Would you like to try installing these packages with Cargo? [Y/n]${NC}"
    echo -e "${BLUE}Packages: ${failed_packages[*]}${NC}"
    read -r USE_CARGO_FALLBACK
    
    if [[ -z "$USE_CARGO_FALLBACK" || "$USE_CARGO_FALLBACK" =~ ^[Yy]$ ]]; then
      install_with_cargo "${failed_packages[@]}"
    else
      echo -e "${BLUE}Skipping Cargo fallback installation.${NC}"
    fi
  fi
}

# Function to display usage tips
display_usage_tips() {
  # Tool-specific tips
  declare -A TOOL_TIPS
  TOOL_TIPS=(
    ["eza"]="$(cat << EOF
${YELLOW}eza (modern ls replacement):${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  alias ls='eza'
  alias ll='eza -la'
  alias lt='eza --tree'
EOF
    )"
    
    ["bat"]="$(cat << EOF
${YELLOW}bat (better cat with syntax highlighting):${NC}
${CYAN}Usage examples:${NC}
  bat file.txt               ${BLUE}# View file with syntax highlighting${NC}
  bat -p file.txt            ${BLUE}# Plain mode without decorations${NC}
  bat -A file.txt            ${BLUE}# Show invisible characters${NC}
EOF
    )"
    
    ["neovim"]="$(cat << EOF
${YELLOW}neovim (improved vim editor):${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  alias vim='nvim'
  alias vi='nvim'
${CYAN}Basic usage:${NC}
  nvim file.txt              ${BLUE}# Edit a file${NC}
EOF
    )"
    
    ["fzf"]="$(cat << EOF
${YELLOW}fzf (fuzzy finder):${NC}
${CYAN}Usage examples:${NC}
  fzf                        ${BLUE}# Start interactive finder${NC}
  vim \$(fzf)                ${BLUE}# Open selected file in vim${NC}
  history | fzf              ${BLUE}# Search command history${NC}
EOF
    )"
    
    ["ripgrep"]="$(cat << EOF
${YELLOW}ripgrep (faster grep):${NC}
${CYAN}Usage examples:${NC}
  rg pattern                 ${BLUE}# Search for pattern in current directory${NC}
  rg -i pattern              ${BLUE}# Case insensitive search${NC}
  rg -t py pattern           ${BLUE}# Search only Python files${NC}
EOF
    )"
    
    ["zoxide"]="$(cat << EOF
${YELLOW}zoxide (smarter cd command):${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  eval "\$(zoxide init zsh)"
${CYAN}Usage:${NC}
  z directory                ${BLUE}# Jump to a directory${NC}
  zi directory               ${BLUE}# Interactive selection${NC}
EOF
    )"
    
    ["atuin"]="$(cat << EOF
${YELLOW}atuin (shell history manager):${NC}
${CYAN}Setup:${NC}
  atuin init zsh > ~/.atuin.zsh
  echo 'source ~/.atuin.zsh' >> ~/.zshrc
${CYAN}Usage:${NC}
  Ctrl+r                     ${BLUE}# Search history${NC}
EOF
    )"
    
    ["git-delta"]="$(cat << EOF
${YELLOW}git-delta (improved git diff):${NC}
${CYAN}Add to your ~/.gitconfig:${NC}
  [core]
      pager = delta
  [interactive]
      diffFilter = delta --color-only
  [delta]
      navigate = true
      light = false
      side-by-side = true
EOF
    )"
    
    ["fd"]="$(cat << EOF
${YELLOW}fd (alternative to find):${NC}
${CYAN}Usage examples:${NC}
  fd pattern                 ${BLUE}# Find files/dirs matching pattern${NC}
  fd -t f pattern            ${BLUE}# Find only files${NC}
  fd -e md                   ${BLUE}# Find only markdown files${NC}
EOF
    )"
    
    ["midnight-commander"]="$(cat << EOF
${YELLOW}midnight-commander (file manager):${NC}
${CYAN}Usage:${NC}
  mc                         ${BLUE}# Start Midnight Commander${NC}
  F9                         ${BLUE}# Access menu bar${NC}
  F5                         ${BLUE}# Copy files${NC}
EOF
    )"
    
    ["zsh-autosuggestions"]="$(cat << EOF
${YELLOW}zsh-autosuggestions:${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  # or if installed with Homebrew:
  source \$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF
    )"
  )
  
  # Display tips for commonly installed tools
  echo -e "\n${BLUE}===== Tool Usage Tips =====${NC}"
  
  for tool in eza bat neovim fzf ripgrep zoxide atuin git-delta fd midnight-commander zsh-autosuggestions; do
    if command_exists "$tool" || [[ "$tool" == "zsh-autosuggestions" ]]; then
      echo -e "\n${TOOL_TIPS[$tool]}"
    fi
  done
  
  echo -e "\n${GREEN}Remember to restart your shell after making configuration changes!${NC}"
}

# Main script

# Detect available package managers
available_managers=($(detect_package_managers))

if ((${#available_managers[@]} == 0)); then
  echo -e "${RED}No supported package managers found.${NC}"
  echo -e "${YELLOW}Please install at least one of: Homebrew, Cargo, or a supported Linux package manager.${NC}"
  exit 1
fi

# Display available package managers
echo -e "${BLUE}Available package managers:${NC}"
for i in "${!available_managers[@]}"; do
  manager_info="${available_managers[$i]}"
  manager_name="${manager_info%%:*}"
  manager_desc="${manager_info#*:}"
  echo -e "${CYAN}[$((i+1))] $manager_name${NC}: $manager_desc"
done

# Ask user to select a package manager
echo -e "\n${YELLOW}Which package manager would you like to use? (Enter number)${NC}"
read -r MANAGER_CHOICE

if ! [[ "$MANAGER_CHOICE" =~ ^[0-9]+$ ]] || ((MANAGER_CHOICE < 1 || MANAGER_CHOICE > ${#available_managers[@]})); then
  echo -e "${RED}Invalid selection. Exiting.${NC}"
  exit 1
fi

# Get selected package manager
selected_manager="${available_managers[$((MANAGER_CHOICE-1))]}"
manager_name="${selected_manager%%:*}"
manager_desc="${selected_manager#*:}"

echo -e "${GREEN}Using $manager_desc ($manager_name) as the package manager.${NC}"

# List packages that will be installed
echo -e "\n${YELLOW}Would you like to install the following tools using $manager_name?${NC}"

for package_info in "${PACKAGES[@]}"; do
  package_name="${package_info%%:*}"
  package_desc="${package_info#*:}"
  echo -e "  - ${BLUE}${package_name}${NC}: ${package_desc}"
done

echo -e "${YELLOW}Install these packages? [Y/n]${NC}"
read -r INSTALL_TOOLS

if [[ -z "$INSTALL_TOOLS" || "$INSTALL_TOOLS" =~ ^[Yy]$ ]]; then
  case "$manager_name" in
    brew)
      install_with_brew
      ;;
    cargo)
      # Extract just the package names for all packages
      cargo_packages=()
      for package_info in "${PACKAGES[@]}"; do
        package_name="${package_info%%:*}"
        cargo_packages+=("$package_name")
      done
      
      install_with_cargo "${cargo_packages[@]}"
      ;;
    apt|dnf|pacman|zypper|apk)
      install_with_native "$manager_name"
      ;;
    *)
      echo -e "${RED}Unsupported package manager: $manager_name. Exiting.${NC}"
      exit 1
      ;;
  esac
  
  # Display usage tips
  display_usage_tips
else
  echo -e "${BLUE}Installation cancelled. Exiting.${NC}"
fi

exit 0