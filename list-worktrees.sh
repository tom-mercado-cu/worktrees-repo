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

# Get the directory where the script is located (or current directory)
ROOT_DIR="${1:-$(pwd)}"
WORKTREES_DIR="$ROOT_DIR/worktrees"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Git Worktree Navigator             ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if worktrees directory exists
if [ ! -d "$WORKTREES_DIR" ]; then
    echo -e "${RED}No worktrees directory found at $WORKTREES_DIR${NC}"
    echo -e "${CYAN}Tip: Use worktrees.sh to create worktrees first.${NC}"
    return 1 2>/dev/null || exit 1
fi

# Find all worktrees (feature directories containing repos)
WORKTREE_PATHS=()
WORKTREE_NAMES=()
WORKTREE_REPOS=()
COUNT=0

for feature_dir in "$WORKTREES_DIR"/*/; do
    if [ -d "$feature_dir" ]; then
        feature_name=$(basename "$feature_dir")
        
        # Count repos in this worktree
        repo_list=""
        repo_count=0
        for repo_dir in "$feature_dir"/*/; do
            if [ -d "$repo_dir" ]; then
                repo_name=$(basename "$repo_dir")
                # Verify it's actually a git worktree
                if [ -f "$repo_dir/.git" ] || [ -d "$repo_dir/.git" ]; then
                    if [ -n "$repo_list" ]; then
                        repo_list="$repo_list, $repo_name"
                    else
                        repo_list="$repo_name"
                    fi
                    repo_count=$((repo_count + 1))
                fi
            fi
        done
        
        # Only add if there are repos
        if [ $repo_count -gt 0 ]; then
            COUNT=$((COUNT + 1))
            WORKTREE_PATHS[$COUNT]="$feature_dir"
            WORKTREE_NAMES[$COUNT]="$feature_name"
            WORKTREE_REPOS[$COUNT]="$repo_list"
        fi
    fi
done

if [ $COUNT -eq 0 ]; then
    echo -e "${RED}No worktrees found in $WORKTREES_DIR${NC}"
    echo -e "${CYAN}Tip: Use worktrees.sh to create worktrees first.${NC}"
    return 1 2>/dev/null || exit 1
fi

echo -e "${BLUE}Found ${COUNT} worktree(s):${NC}"
echo ""

# Display worktrees with their repos
i=1
while [ $i -le $COUNT ]; do
    echo -e "  ${YELLOW}$i${NC}) ${BOLD}${WORKTREE_NAMES[$i]}${NC}"
    echo -e "     ${DIM}repos: ${WORKTREE_REPOS[$i]}${NC}"
    echo ""
    i=$((i + 1))
done

echo -e "${BOLD}Select a worktree to navigate to:${NC}"
echo -e "${CYAN}(Enter number, or 'q' to quit)${NC}"
echo ""
read "selection?Selection: "

# Handle quit
if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
    echo -e "${CYAN}Bye!${NC}"
    return 0 2>/dev/null || exit 0
fi

# Validate selection
if ! echo "$selection" | grep -qE '^[0-9]+$' || [ "$selection" -lt 1 ] || [ "$selection" -gt "$COUNT" ]; then
    echo -e "${RED}Invalid selection: $selection${NC}"
    return 1 2>/dev/null || exit 1
fi

# Get selected worktree
SELECTED_PATH="${WORKTREE_PATHS[$selection]}"
SELECTED_NAME="${WORKTREE_NAMES[$selection]}"

# Remove trailing slash if present
SELECTED_PATH="${SELECTED_PATH%/}"

echo ""
echo -e "${GREEN}✓${NC} Navigating to: ${CYAN}$SELECTED_NAME${NC}"
echo ""

cd "$SELECTED_PATH"
