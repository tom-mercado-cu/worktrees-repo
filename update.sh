#!/bin/bash

# Update script for Git Worktree Tools
# Removes old installation and reinstalls from latest

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

INSTALL_DIR="${WT_TOOLS_DIR:-$HOME/.wt-tools}"
REPO_URL="${WT_TOOLS_REPO:-https://github.com/tom-mercado-cu/worktrees-repo.git}"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   Git Worktree Tools - Update          ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Find .zshrc file
ZSHRC_CANDIDATES=(
    "$HOME/.zshrc"
    "$HOME/.zprezto/runcoms/zshrc"
    "${ZDOTDIR:-$HOME}/.zshrc"
)

ZSHRC_FILE=""
for candidate in "${ZSHRC_CANDIDATES[@]}"; do
    if [ -f "$candidate" ]; then
        ZSHRC_FILE="$candidate"
        break
    fi
done

if [ -z "$ZSHRC_FILE" ]; then
    echo -e "${RED}Could not find .zshrc file.${NC}"
    exit 1
fi

# Resolve symlink to real file
if [ -L "$ZSHRC_FILE" ]; then
    REAL_ZSHRC_FILE=$(readlink -f "$ZSHRC_FILE" 2>/dev/null || readlink "$ZSHRC_FILE")
    echo -e "${CYAN}→${NC} Found zshrc: ${DIM}$ZSHRC_FILE${NC} → ${DIM}$REAL_ZSHRC_FILE${NC}"
    ZSHRC_FILE="$REAL_ZSHRC_FILE"
else
    echo -e "${CYAN}→${NC} Found zshrc: ${DIM}$ZSHRC_FILE${NC}"
fi
echo ""

# Step 1: Remove wt-* aliases from .zshrc
echo -e "${BOLD}Step 1:${NC} Removing old aliases from zshrc..."

# Create backup
cp "$ZSHRC_FILE" "$ZSHRC_FILE.bak.$(date +%Y%m%d%H%M%S)"
echo -e "  ${GREEN}✓${NC} Backup created"

# Remove the Git Worktree management block
# This removes from "# Git Worktree management" to the next blank line or end of related aliases
if grep -q "# Git Worktree management" "$ZSHRC_FILE"; then
    # Use sed to remove the block
    # macOS sed requires slightly different syntax
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/# Git Worktree management/,/^[^#a]*$/d' "$ZSHRC_FILE"
    else
        sed -i '/# Git Worktree management/,/^[^#a]*$/d' "$ZSHRC_FILE"
    fi
    echo -e "  ${GREEN}✓${NC} Removed alias block"
else
    echo -e "  ${YELLOW}⚠${NC}  No alias block found (might be already removed)"
fi

# Also remove any stray wt- aliases that might be outside the block
if grep -q "alias wt-" "$ZSHRC_FILE"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^alias wt-/d' "$ZSHRC_FILE"
    else
        sed -i '/^alias wt-/d' "$ZSHRC_FILE"
    fi
    echo -e "  ${GREEN}✓${NC} Removed stray aliases"
fi

# Remove old-style aliases (wt, wtnew, wtrm) if they exist
if grep -q "alias wt=" "$ZSHRC_FILE" || grep -q "alias wtnew=" "$ZSHRC_FILE" || grep -q "alias wtrm=" "$ZSHRC_FILE"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^alias wt=/d' "$ZSHRC_FILE"
        sed -i '' '/^alias wtnew=/d' "$ZSHRC_FILE"
        sed -i '' '/^alias wtrm=/d' "$ZSHRC_FILE"
    else
        sed -i '/^alias wt=/d' "$ZSHRC_FILE"
        sed -i '/^alias wtnew=/d' "$ZSHRC_FILE"
        sed -i '/^alias wtrm=/d' "$ZSHRC_FILE"
    fi
    echo -e "  ${GREEN}✓${NC} Removed old-style aliases"
fi

echo ""

# Step 2: Remove old installation directory
echo -e "${BOLD}Step 2:${NC} Removing old installation..."

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "  ${GREEN}✓${NC} Removed $INSTALL_DIR"
else
    echo -e "  ${YELLOW}⚠${NC}  Directory not found (might be already removed)"
fi

echo ""

# Step 3: Clone fresh copy
echo -e "${BOLD}Step 3:${NC} Cloning latest version..."

git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
echo -e "  ${GREEN}✓${NC} Cloned to $INSTALL_DIR"

echo ""

# Step 4: Make scripts executable
echo -e "${BOLD}Step 4:${NC} Setting permissions..."

chmod +x "$INSTALL_DIR"/*.sh
echo -e "  ${GREEN}✓${NC} Scripts are executable"

echo ""

# Step 5: Run installer
echo -e "${BOLD}Step 5:${NC} Running installer..."
echo ""

cd "$INSTALL_DIR"
./install.sh -y

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}${GREEN}✓ Update complete!${NC}"
echo ""
echo -e "${CYAN}Reload your shell to apply changes:${NC}"
echo -e "  ${YELLOW}source $ZSHRC_FILE${NC}"
echo ""
