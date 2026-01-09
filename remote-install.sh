#!/bin/bash

# Remote installer for Git Worktree Tools
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/wt-tools/main/remote-install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
INSTALL_DIR="${WT_TOOLS_DIR:-$HOME/.wt-tools}"
REPO_URL="${WT_TOOLS_REPO:-https://github.com/tom-mercado-cu/worktrees-repo.git}"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   Git Worktree Tools - Remote Install  ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed.${NC}"
    exit 1
fi

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠${NC}  wt-tools is already installed at ${CYAN}$INSTALL_DIR${NC}"
    echo ""
    read -p "$(echo -e "Do you want to update it? [y/N]: ")" UPDATE
    if [[ "$UPDATE" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}→${NC} Updating..."
        cd "$INSTALL_DIR"
        git pull origin main
        echo -e "${GREEN}✓${NC} Updated!"
        echo ""
        echo -e "${CYAN}Reload your shell to apply changes:${NC}"
        echo -e "  ${YELLOW}source ~/.zshrc${NC}"
        exit 0
    else
        echo -e "${CYAN}Installation cancelled.${NC}"
        exit 0
    fi
fi

# Clone the repository
echo -e "${CYAN}→${NC} Cloning wt-tools to ${CYAN}$INSTALL_DIR${NC}..."
git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"

# Make scripts executable
chmod +x "$INSTALL_DIR"/*.sh

# Run the local installer with auto-yes flag
echo ""
cd "$INSTALL_DIR"
./install.sh -y

echo ""
echo -e "${GREEN}✓${NC} Installation complete!"
echo ""
echo -e "${BOLD}${CYAN}To update later, run:${NC}"
echo -e "  ${YELLOW}cd $INSTALL_DIR && git pull${NC}"
echo ""
