#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get the directory where the script is located (or current directory)
ROOT_DIR="${1:-$(pwd)}"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Git Worktree Prune                 ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Cleaning up orphaned worktree references...${NC}"
echo ""

# Find all directories that are git repositories
REPOS_FOUND=0
REPOS_PRUNED=0

for dir in "$ROOT_DIR"/*/; do
    if [ -d "$dir/.git" ] || [ -f "$dir/.git" ]; then
        repo_name=$(basename "$dir")
        # Skip the worktrees directory itself
        if [ "$repo_name" != "worktrees" ]; then
            REPOS_FOUND=$((REPOS_FOUND + 1))
            
            cd "$dir"
            
            # Check if there are any stale worktrees
            stale_count=$(git worktree list --porcelain 2>/dev/null | grep -c "^worktree" || echo 0)
            
            echo -e "  ${CYAN}→${NC} Pruning: ${BOLD}$repo_name${NC}"
            
            # Run git worktree prune
            if git worktree prune 2>/dev/null; then
                # Check if anything was actually pruned by comparing before/after
                new_count=$(git worktree list --porcelain 2>/dev/null | grep -c "^worktree" || echo 0)
                if [ "$stale_count" != "$new_count" ]; then
                    echo -e "    ${GREEN}✓${NC} Pruned stale references"
                    REPOS_PRUNED=$((REPOS_PRUNED + 1))
                else
                    echo -e "    ${GREEN}✓${NC} Already clean"
                fi
            else
                echo -e "    ${YELLOW}⚠${NC}  Could not prune"
            fi
            
            cd - > /dev/null
        fi
    fi
done

if [ $REPOS_FOUND -eq 0 ]; then
    echo -e "${YELLOW}No git repositories found in $ROOT_DIR${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}${GREEN}✓ Prune complete!${NC}"
echo -e "  Repositories checked: ${CYAN}$REPOS_FOUND${NC}"
echo ""
