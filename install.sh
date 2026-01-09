#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Parse arguments
AUTO_YES=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Get the directory where THIS script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   Git Worktree Tools - Installer       ║${NC}"
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
    if [ "$AUTO_YES" = true ]; then
        # In auto mode, create default .zshrc
        ZSHRC_FILE="$HOME/.zshrc"
        touch "$ZSHRC_FILE"
        echo -e "${GREEN}✓${NC} Created: ${CYAN}$ZSHRC_FILE${NC}"
    else
        echo -e "${YELLOW}Could not find .zshrc file automatically.${NC}"
        echo -e "${DIM}Searched in:${NC}"
        for candidate in "${ZSHRC_CANDIDATES[@]}"; do
            echo -e "  ${DIM}- $candidate${NC}"
        done
        echo ""
        
        # Offer to create default .zshrc
        DEFAULT_ZSHRC="$HOME/.zshrc"
        echo -e "Would you like to:"
        echo -e "  ${YELLOW}1${NC}) Create ${CYAN}$DEFAULT_ZSHRC${NC}"
        echo -e "  ${YELLOW}2${NC}) Enter a custom path"
        echo -e "  ${YELLOW}q${NC}) Cancel installation"
        echo ""
        read -p "Selection [1]: " ZSHRC_CHOICE
        ZSHRC_CHOICE=${ZSHRC_CHOICE:-1}
        
        case "$ZSHRC_CHOICE" in
            1)
                ZSHRC_FILE="$DEFAULT_ZSHRC"
                touch "$ZSHRC_FILE"
                echo -e "${GREEN}✓${NC} Created: ${CYAN}$ZSHRC_FILE${NC}"
                ;;
            2)
                read -p "Enter the path to your .zshrc file: " ZSHRC_FILE
                if [ ! -f "$ZSHRC_FILE" ]; then
                    read -p "$(echo -e "File doesn't exist. Create it? [Y/n]: ")" CREATE_IT
                    CREATE_IT=${CREATE_IT:-Y}
                    if [[ "$CREATE_IT" =~ ^[Yy]$ ]]; then
                        touch "$ZSHRC_FILE"
                        echo -e "${GREEN}✓${NC} Created: ${CYAN}$ZSHRC_FILE${NC}"
                    else
                        echo -e "${RED}Installation cancelled.${NC}"
                        exit 1
                    fi
                fi
                ;;
            q|Q)
                echo -e "${CYAN}Installation cancelled.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid selection.${NC}"
                exit 1
                ;;
        esac
        echo ""
    fi
fi

echo -e "${GREEN}Found zshrc:${NC} ${CYAN}$ZSHRC_FILE${NC}"
echo ""

# Define the aliases - using consistent naming with wt- prefix
ALIASES_BLOCK="
# Git Worktree management
# Single-repo commands
alias wt-new='$SCRIPT_DIR/wt-new.sh'
alias wt-existing='$SCRIPT_DIR/wt-existing.sh'

# Multi-repo commands
alias wt-multi-new='$SCRIPT_DIR/wt-multi-new.sh'

# Navigation & management
alias wt-list='source $SCRIPT_DIR/wt-list.sh'
alias wt-clean='$SCRIPT_DIR/wt-clean.sh'
alias wt-prune='$SCRIPT_DIR/wt-prune.sh'
alias wt-help='$SCRIPT_DIR/wt-help.sh'
alias wt-update='$SCRIPT_DIR/update.sh'"

# Check if aliases already exist
if grep -q "alias wt-new=" "$ZSHRC_FILE" || grep -q "alias wt-multi-new=" "$ZSHRC_FILE" || grep -q "alias wt-list=" "$ZSHRC_FILE" || grep -q "alias wt-update=" "$ZSHRC_FILE"; then
    echo -e "${YELLOW}⚠  Warning:${NC} Some worktree aliases already exist in your zshrc."
    echo -e "${CYAN}Please remove them manually before running this installer, or run wt-update.${NC}"
    echo ""
    echo -e "${DIM}Existing aliases found:${NC}"
    grep -E "alias wt-" "$ZSHRC_FILE" | while read -r line; do
        echo -e "  ${DIM}$line${NC}"
    done
    echo ""
    exit 1
fi

# Also check for old aliases
if grep -q "alias wt=" "$ZSHRC_FILE" || grep -q "alias wtnew=" "$ZSHRC_FILE" || grep -q "alias wtrm=" "$ZSHRC_FILE"; then
    echo -e "${YELLOW}⚠  Warning:${NC} Old worktree aliases (wt, wtnew, wtrm) found in your zshrc."
    echo -e "${CYAN}Please remove them manually before running this installer.${NC}"
    echo ""
    echo -e "${DIM}Old aliases found:${NC}"
    grep -E "alias (wt|wtnew|wtrm)=" "$ZSHRC_FILE" | while read -r line; do
        echo -e "  ${DIM}$line${NC}"
    done
    echo ""
    exit 1
fi

# Show what we're going to do
echo -e "${BOLD}${BLUE}This installer will add the following aliases to your zshrc:${NC}"
echo ""
echo -e "  ${BOLD}Single-Repo:${NC}"
echo -e "    ${YELLOW}wt-new${NC}        → Create worktree with new branch"
echo -e "    ${YELLOW}wt-existing${NC}   → Create worktree for existing branch"
echo ""
echo -e "  ${BOLD}Multi-Repo:${NC}"
echo -e "    ${YELLOW}wt-multi-new${NC}  → Create worktrees across multiple repos"
echo ""
echo -e "  ${BOLD}Navigation & Management:${NC}"
echo -e "    ${YELLOW}wt-list${NC}       → Navigate to an existing worktree"
echo -e "    ${YELLOW}wt-clean${NC}      → Remove existing worktrees"
echo -e "    ${YELLOW}wt-prune${NC}      → Clean up orphaned references"
echo -e "    ${YELLOW}wt-help${NC}       → Show help"
echo -e "    ${YELLOW}wt-update${NC}     → Update to latest version"
echo ""

if [ "$AUTO_YES" = false ]; then
    echo -e "${DIM}The following lines will be added to: $ZSHRC_FILE${NC}"
    echo -e "${DIM}─────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}$ALIASES_BLOCK${NC}"
    echo -e "${DIM}─────────────────────────────────────────────────────${NC}"
    echo ""

    read -p "$(echo -e ${BOLD}Do you want to proceed? [y/N]:${NC} )" CONFIRM

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Installation cancelled.${NC}"
        exit 0
    fi
fi

# Add aliases to zshrc
echo "$ALIASES_BLOCK" >> "$ZSHRC_FILE"

echo ""
echo -e "${GREEN}✓${NC} Aliases added successfully!"
echo ""
echo -e "${BOLD}${BLUE}Next steps:${NC}"
echo ""
echo -e "  1. Reload your shell configuration:"
echo -e "     ${YELLOW}source $ZSHRC_FILE${NC}"
echo ""
echo -e "  2. Try the commands:"
echo -e "     ${YELLOW}wt-help${NC}       - to see all available commands"
echo -e "     ${YELLOW}wt-new${NC}        - to create a single-repo worktree"
echo -e "     ${YELLOW}wt-multi-new${NC}  - to create multi-repo worktrees"
echo -e "     ${YELLOW}wt-list${NC}       - to navigate to a worktree"
echo -e "     ${YELLOW}wt-clean${NC}      - to remove worktrees"
echo ""
echo -e "${DIM}─────────────────────────────────────────────────────${NC}"
echo -e "${BOLD}${CYAN}Important notes:${NC}"
echo ""
echo -e "  • You can modify these aliases anytime by editing:"
echo -e "    ${CYAN}$ZSHRC_FILE${NC}"
echo ""
echo -e "  • If you move this directory (${CYAN}$SCRIPT_DIR${NC})"
echo -e "    you must update the aliases paths accordingly."
echo ""
echo -e "  • Single-repo commands (wt-new, wt-existing) work from inside a git repo."
echo -e "  • Multi-repo commands work from a directory containing multiple repos."
echo -e "${DIM}─────────────────────────────────────────────────────${NC}"
echo ""
