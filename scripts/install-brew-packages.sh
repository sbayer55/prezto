#!/usr/bin/env zsh

# Script to check if Homebrew is installed and install essential tools
# -------------------------------------------------------------------

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

# Set colors for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Main script

echo -e "${BLUE}Checking if Homebrew is installed...${NC}"

if ! command_exists brew; then
  echo -e "${RED}Homebrew is not installed on your system.${NC}"
  echo -e "${YELLOW}Would you like to install Homebrew? [y/N]${NC}"
  read -r INSTALL_BREW
  
  if [[ "$INSTALL_BREW" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Check if installation was successful
    if ! command_exists brew; then
      echo -e "${RED}Failed to install Homebrew. Please install it manually:${NC}"
      echo -e "${BLUE}https://brew.sh${NC}"
      exit 1
    else
      echo -e "${GREEN}Homebrew has been successfully installed!${NC}"
      
      # Set up Homebrew in current shell
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        echo -e "${YELLOW}Setting up Homebrew in your current shell...${NC}"
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        # Linux
        echo -e "${YELLOW}Setting up Homebrew in your current shell...${NC}"
        if [[ -d /home/linuxbrew/.linuxbrew ]]; then
          eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -d "$HOME/.linuxbrew" ]]; then
          eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        else
          echo -e "${RED}Unable to find Homebrew installation directory.${NC}"
          echo -e "${YELLOW}You may need to set up the Homebrew environment manually.${NC}"
        fi
      fi
    fi
  else
    echo -e "${BLUE}Homebrew installation skipped. Exiting.${NC}"
    exit 0
  fi
fi

# At this point, Homebrew should be installed
echo -e "${GREEN}Homebrew is installed on your system.${NC}"
echo -e "${BLUE}Homebrew version: $(brew --version | head -1)${NC}"

# Ask if the user wants to install tools
echo -e "${YELLOW}Would you like to install the following tools using Homebrew?${NC}"
for package_info in "${PACKAGES[@]}"; do
  package_name="${package_info%%:*}"
  package_desc="${package_info#*:}"
  echo -e "  - ${BLUE}${package_name}${NC}: ${package_desc}"
done

echo -e "${YELLOW}Install these packages? [Y/n]${NC}"
read -r INSTALL_TOOLS

if [[ -z "$INSTALL_TOOLS" || "$INSTALL_TOOLS" =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}Installing tools...${NC}"
  
  # Disable analytics
  brew analytics off
  
  # Check for updates
  echo -e "${BLUE}Updating Homebrew...${NC}"
  brew update
  
  # Extract package names from the PACKAGES array
  tools=()
  for package_info in "${PACKAGES[@]}"; do
    package_name="${package_info%%:*}"
    tools+=("$package_name")
  done
  
  for tool in "${tools[@]}"; do
    if brew list "$tool" &>/dev/null; then
      echo -e "${YELLOW}$tool is already installed. Would you like to upgrade it? [Y/n]${NC}"
      read -r UPGRADE_TOOL
      
      if [[ -z "$UPGRADE_TOOL" || "$UPGRADE_TOOL" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Upgrading $tool...${NC}"
        if brew upgrade "$tool"; then
          echo -e "${GREEN}Successfully upgraded $tool.${NC}"
        else
          echo -e "${RED}Failed to upgrade $tool.${NC}"
        fi
      else
        echo -e "${BLUE}Skipping upgrade for $tool.${NC}"
      fi
    else
      echo -e "${BLUE}Installing $tool...${NC}"
      if brew install "$tool"; then
        echo -e "${GREEN}Successfully installed $tool.${NC}"
      else
        echo -e "${RED}Failed to install $tool.${NC}"
      fi
    fi
  done
  
  # Print installation summary
  echo -e "\n${GREEN}Installation summary:${NC}"
  
  for tool in "${tools[@]}"; do
    if brew list "$tool" &>/dev/null; then
      echo -e "${BLUE}$tool:${NC} ${GREEN}Installed${NC} ($(brew info "$tool" --json | jq -r '.[0].installed[0].version'))"
    else
      echo -e "${BLUE}$tool:${NC} ${RED}Not installed${NC}"
    fi
  done
  
  # Display usage tips
  echo -e "\n${BLUE}===== Tool Usage Tips =====${NC}"
  
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
  )
  
  # Display tips for installed tools
  for tool in "${tools[@]}"; do
    if brew list "$tool" &>/dev/null && [[ -n "${TOOL_TIPS[$tool]}" ]]; then
      echo -e "\n${TOOL_TIPS[$tool]}"
    fi
  done
  
  echo -e "\n${GREEN}Remember to restart your shell after making configuration changes!${NC}"
  
else
  echo -e "${BLUE}Tool installation skipped. Exiting.${NC}"
fi

exit 0
