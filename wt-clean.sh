#!/bin/bash

set -e

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
WORKTREES_DIR="$ROOT_DIR/worktrees"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Git Worktree Removal Manager       ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if worktrees directory exists
if [ ! -d "$WORKTREES_DIR" ]; then
    echo -e "${RED}No worktrees directory found at $WORKTREES_DIR${NC}"
    exit 1
fi

# Find all feature directories (branch directories containing worktrees)
# Structure: worktrees/<branch-name>/<repo>/
declare -a FEATURES=()
declare -a FEATURE_REPOS=()

for feature_dir in "$WORKTREES_DIR"/*/; do
    if [ -d "$feature_dir" ]; then
        feature_name=$(basename "$feature_dir")
        
        # Check if this directory contains any git worktrees
        repos_in_feature=""
        has_worktrees=false
        
        for repo_dir in "$feature_dir"/*/; do
            if [ -d "$repo_dir" ]; then
                # Check if it's a git worktree (has .git file)
                if [ -f "$repo_dir/.git" ]; then
                    has_worktrees=true
                    repo_name=$(basename "$repo_dir")
                    if [ -n "$repos_in_feature" ]; then
                        repos_in_feature="$repos_in_feature, $repo_name"
                    else
                        repos_in_feature="$repo_name"
                    fi
                fi
            fi
        done
        
        if [ "$has_worktrees" = true ]; then
            FEATURES+=("$feature_name")
            FEATURE_REPOS+=("$repos_in_feature")
        fi
    fi
done

if [ ${#FEATURES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No worktree features found in $WORKTREES_DIR${NC}"
    exit 0
fi

echo -e "${BLUE}Found ${#FEATURES[@]} feature worktrees:${NC}"
echo ""

# Display features with numbers
for i in "${!FEATURES[@]}"; do
    echo -e "  ${YELLOW}$((i+1))${NC}) ${FEATURES[$i]}"
    echo -e "      ${CYAN}repos: ${FEATURE_REPOS[$i]}${NC}"
done

echo ""
echo -e "${BOLD}Select features to remove:${NC}"
echo -e "${CYAN}(Enter numbers separated by spaces, or 'all' for all features)${NC}"
echo ""
read -p "Selection: " selection

# Parse selection
declare -a SELECTED_FEATURES=()

if [ "$selection" = "all" ] || [ "$selection" = "a" ]; then
    SELECTED_FEATURES=("${FEATURES[@]}")
else
    for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#FEATURES[@]}" ]; then
            SELECTED_FEATURES+=("${FEATURES[$((num-1))]}")
        else
            echo -e "${RED}Invalid selection: $num${NC}"
        fi
    done
fi

if [ ${#SELECTED_FEATURES[@]} -eq 0 ]; then
    echo -e "${RED}No features selected. Exiting.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚠ Warning: The following features will be removed:${NC}"
for feature in "${SELECTED_FEATURES[@]}"; do
    echo -e "  ${RED}✗${NC} $feature"
done

echo ""
read -p "$(echo -e ${BOLD}Are you sure? [y/N]:${NC} )" confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BOLD}${BLUE}Removing worktrees...${NC}"
echo ""

# Track which branches to potentially delete
declare -a BRANCHES_TO_DELETE=()

# Remove worktrees for each selected feature
for feature in "${SELECTED_FEATURES[@]}"; do
    FEATURE_DIR="$WORKTREES_DIR/$feature"
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Removing feature: ${CYAN}$feature${NC}"
    
    # Process each repo worktree in this feature
    for repo_dir in "$FEATURE_DIR"/*/; do
        if [ -d "$repo_dir" ] && [ -f "$repo_dir/.git" ]; then
            repo_name=$(basename "$repo_dir")
            REPO_PATH="$ROOT_DIR/$repo_name"
            
            echo -e "  ${CYAN}→${NC} Processing repo: $repo_name"
    
    # Get the branch name before removing
    BRANCH_NAME=""
            cd "$repo_dir"
        BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        cd - > /dev/null
    
    # Try to remove using git worktree remove from the parent repo
    if [ -d "$REPO_PATH" ]; then
        cd "$REPO_PATH"
        
                if git worktree remove "$repo_dir" --force 2>/dev/null; then
                    echo -e "    ${GREEN}✓${NC} Worktree removed"
        else
            # Fallback: remove directory manually and prune
                    echo -e "    ${YELLOW}⚠${NC}  Git worktree remove failed, cleaning up manually..."
                    rm -rf "$repo_dir"
            git worktree prune
                    echo -e "    ${GREEN}✓${NC} Worktree cleaned up"
        fi
        
                # Track branch for potential deletion
        if [ -n "$BRANCH_NAME" ] && [ "$BRANCH_NAME" != "HEAD" ]; then
                    # Check if we already have this branch in the list
                    branch_entry="$repo_name:$BRANCH_NAME"
                    if [[ ! " ${BRANCHES_TO_DELETE[*]} " =~ " ${branch_entry} " ]]; then
                        BRANCHES_TO_DELETE+=("$branch_entry")
                    fi
        fi
        
        cd - > /dev/null
    else
        # Parent repo not found, just remove the directory
                echo -e "    ${YELLOW}⚠${NC}  Parent repo not found, removing directory..."
                rm -rf "$repo_dir"
                echo -e "    ${GREEN}✓${NC} Directory removed"
            fi
    fi
done

    # Remove workspace file if exists
    WORKSPACE_FILE="$FEATURE_DIR/${feature}.code-workspace"
    if [ -f "$WORKSPACE_FILE" ]; then
        echo -e "  ${CYAN}→${NC} Removing workspace file..."
        rm -f "$WORKSPACE_FILE"
        echo -e "    ${GREEN}✓${NC} Workspace file removed"
    fi
    
    # Remove the feature directory if empty
    if [ -d "$FEATURE_DIR" ]; then
        rmdir "$FEATURE_DIR" 2>/dev/null && echo -e "  ${GREEN}✓${NC} Feature directory removed" || true
    fi
done

# Ask about deleting branches
if [ ${#BRANCHES_TO_DELETE[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Would you like to also delete the associated branches?${NC}"
    echo ""
    
    for entry in "${BRANCHES_TO_DELETE[@]}"; do
        repo="${entry%%:*}"
        branch="${entry#*:}"
        echo -e "  ${CYAN}→${NC} $repo: ${YELLOW}$branch${NC}"
    done
    
    echo ""
    read -p "$(echo -e ${BOLD}Delete branches? [y/N]:${NC} )" delete_branches
    
    if [ "$delete_branches" = "y" ] || [ "$delete_branches" = "Y" ]; then
        for entry in "${BRANCHES_TO_DELETE[@]}"; do
            repo="${entry%%:*}"
            branch="${entry#*:}"
            REPO_PATH="$ROOT_DIR/$repo"
            
            if [ -d "$REPO_PATH" ]; then
                cd "$REPO_PATH"
                echo -e "  ${CYAN}→${NC} Deleting branch '$branch' in $repo..."
                if git branch -D "$branch" 2>/dev/null; then
                    echo -e "  ${GREEN}✓${NC} Branch deleted"
                else
                    echo -e "  ${YELLOW}⚠${NC}  Could not delete branch (may be checked out elsewhere)"
                fi
                cd - > /dev/null
            fi
        done
    fi
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}${GREEN}✓ Cleanup complete!${NC}"
echo ""
