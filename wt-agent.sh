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

# Get script directory (where the template lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/AGENTS.template.md"

# Get current directory
CURRENT_DIR=$(pwd)
FEATURE_NAME=$(basename "$CURRENT_DIR")

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Git Worktree - Agent Context       ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Error: Template file not found at $TEMPLATE_FILE${NC}"
    exit 1
fi

# Check if we're in a worktree directory (should contain repo subdirectories with .git files)
REPOS=()
for dir in "$CURRENT_DIR"/*/; do
    if [ -d "$dir" ]; then
        if [ -f "$dir/.git" ] || [ -d "$dir/.git" ]; then
            repo_name=$(basename "$dir")
            REPOS+=("$repo_name")
        fi
    fi
done

if [ ${#REPOS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No git worktrees found in current directory.${NC}"
    echo -e "${CYAN}Make sure you're inside a worktree feature directory.${NC}"
    echo ""
    echo -e "${DIM}Expected structure:${NC}"
    echo -e "${DIM}  worktrees/${NC}"
    echo -e "${DIM}    └── feature-branch-name/  ${CYAN}← Run wt-agent here${NC}"
    echo -e "${DIM}        ├── repo-1/${NC}"
    echo -e "${DIM}        └── repo-2/${NC}"
    exit 1
fi

echo -e "${BOLD}Feature:${NC} ${CYAN}$FEATURE_NAME${NC}"
echo ""
echo -e "${BOLD}Repositories in this worktree:${NC}"
for repo in "${REPOS[@]}"; do
    # Get branch name from repo
    branch_name=""
    if [ -f "$CURRENT_DIR/$repo/.git" ]; then
        branch_name=$(cd "$CURRENT_DIR/$repo" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
    fi
    echo -e "  ${GREEN}→${NC} $repo ${DIM}($branch_name)${NC}"
done
echo ""

# Check if AGENTS.md already exists
if [ -f "$CURRENT_DIR/AGENTS.md" ]; then
    echo -e "${YELLOW}⚠${NC}  AGENTS.md already exists."
    read -p "$(echo -e "Overwrite? [y/N]: ")" OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Cancelled.${NC}"
        exit 0
    fi
    echo ""
fi

# Get description from user
echo -e "${BOLD}Describe what you're working on:${NC}"
echo -e "${DIM}(Brief description of the feature, fix, or refactor)${NC}"
echo ""
read -p "> " DESCRIPTION

if [ -z "$DESCRIPTION" ]; then
    echo -e "${RED}Description cannot be empty.${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}→${NC} Generating AGENTS.md from template..."

# Get branch name (use first repo's branch as reference)
BRANCH_NAME=""
if [ ${#REPOS[@]} -gt 0 ]; then
    BRANCH_NAME=$(cd "$CURRENT_DIR/${REPOS[0]}" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Build repos list for markdown (bullet list with branches)
REPOS_LIST=""
for repo in "${REPOS[@]}"; do
    branch=$(cd "$CURRENT_DIR/$repo" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
    REPOS_LIST="${REPOS_LIST}- \`${repo}/\` - Branch: \`${branch}\`
"
done

# Build repos tree (for the directory structure visualization)
REPOS_TREE=""
for repo in "${REPOS[@]}"; do
    REPOS_TREE="${REPOS_TREE}├── ${repo}/
"
done

# Get timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# Read template and replace placeholders
CONTENT=$(cat "$TEMPLATE_FILE")

# Escape special characters in DESCRIPTION for sed
DESCRIPTION_ESCAPED=$(printf '%s\n' "$DESCRIPTION" | sed 's/[&/\]/\\&/g')

# Replace placeholders
CONTENT="${CONTENT//\{\{FEATURE_NAME\}\}/$FEATURE_NAME}"
CONTENT="${CONTENT//\{\{BRANCH_NAME\}\}/$BRANCH_NAME}"
CONTENT="${CONTENT//\{\{DESCRIPTION\}\}/$DESCRIPTION_ESCAPED}"
CONTENT="${CONTENT//\{\{TIMESTAMP\}\}/$TIMESTAMP}"

# For multiline replacements, we need to handle differently
# Create a temp file for the content
TEMP_FILE=$(mktemp)
echo "$CONTENT" > "$TEMP_FILE"

# Replace REPOS_LIST (multiline)
REPOS_LIST_ESCAPED=$(printf '%s' "$REPOS_LIST" | sed 's/[&/\]/\\&/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|{{REPOS_LIST}}|$REPOS_LIST_ESCAPED|g" "$TEMP_FILE"
else
    sed -i "s|{{REPOS_LIST}}|$REPOS_LIST_ESCAPED|g" "$TEMP_FILE"
fi

# Replace REPOS_TREE (multiline)  
REPOS_TREE_ESCAPED=$(printf '%s' "$REPOS_TREE" | sed 's/[&/\]/\\&/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|{{REPOS_TREE}}|$REPOS_TREE_ESCAPED|g" "$TEMP_FILE"
else
    sed -i "s|{{REPOS_TREE}}|$REPOS_TREE_ESCAPED|g" "$TEMP_FILE"
fi

# Move temp file to final destination
mv "$TEMP_FILE" "$CURRENT_DIR/AGENTS.md"

echo -e "${GREEN}✓${NC} AGENTS.md created"
echo ""
echo -e "${BOLD}${GREEN}✓ Agent context ready!${NC}"
echo ""
echo -e "${CYAN}The AGENTS.md file provides context for AI assistants about:${NC}"
echo -e "  • What you're working on"
echo -e "  • Which repos are available"
echo -e "  • The worktree structure"
echo ""
echo -e "${DIM}Tip: You can customize the template at:${NC}"
echo -e "${DIM}$TEMPLATE_FILE${NC}"
echo ""
