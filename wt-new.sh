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

# Parse arguments
BRANCH_NAME=""
OPEN_CURSOR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cursor)
            OPEN_CURSOR=true
            shift
            ;;
        *)
            if [ -z "$BRANCH_NAME" ]; then
                BRANCH_NAME="$1"
            fi
            shift
            ;;
    esac
done

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo -e "${RED}Error: Not inside a git repository${NC}"
    exit 1
fi

# Get repo root and name
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")

# Determine parent directory structure
# If we're in a worktree, find the main repo's parent
PARENT_DIR=$(dirname "$REPO_ROOT")
WORKTREES_DIR="$PARENT_DIR/worktrees"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Git Worktree - Single Repo         ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# If no branch name provided, ask for it
if [ -z "$BRANCH_NAME" ]; then
    echo -e "${BOLD}Current repo:${NC} ${CYAN}$REPO_NAME${NC}"
    echo ""
    read -p "$(echo -e ${BOLD}Enter branch name:${NC} )" BRANCH_NAME
    
    if [ -z "$BRANCH_NAME" ]; then
        echo -e "${RED}Branch name cannot be empty. Exiting.${NC}"
        exit 1
    fi
fi

# Sanitize branch name for directory (replace / with -)
BRANCH_DIR_NAME=$(echo "$BRANCH_NAME" | sed 's/\//-/g')

# Create feature directory inside worktrees
FEATURE_DIR="$WORKTREES_DIR/$BRANCH_DIR_NAME"
WORKTREE_PATH="$FEATURE_DIR/$REPO_NAME"

echo -e "${BOLD}Creating worktree:${NC}"
echo -e "  ${CYAN}→${NC} Branch: ${YELLOW}$BRANCH_NAME${NC}"
echo -e "  ${CYAN}→${NC} Path: ${YELLOW}$WORKTREE_PATH${NC}"
echo ""

# Check if worktree already exists
if [ -d "$WORKTREE_PATH" ]; then
    echo -e "${YELLOW}⚠${NC}  Worktree already exists at ${WORKTREE_PATH}"
    echo -e "${CYAN}Tip: Use 'wt-list' to navigate to it, or 'wt-clean' to remove it first.${NC}"
    exit 1
fi

# Ask user preferences
echo -e "${BOLD}${BLUE}Configuration options:${NC}"
echo ""

# Check if .env exists before asking
if [ -f "$REPO_ROOT/.env" ]; then
    read -p "$(echo -e "  Copy ${CYAN}.env${NC} file? [Y/n]: ")" COPY_ENV
    COPY_ENV=${COPY_ENV:-Y}
else
    COPY_ENV="n"
fi

# Check if package.json exists before asking
if [ -f "$REPO_ROOT/package.json" ]; then
    read -p "$(echo -e "  Install dependencies? [Y/n]: ")" INSTALL_DEPS
    INSTALL_DEPS=${INSTALL_DEPS:-Y}
else
    INSTALL_DEPS="n"
fi

# Ask about Cursor if not already set via flag
if [ "$OPEN_CURSOR" = false ]; then
    read -p "$(echo -e "  Open in Cursor when done? [Y/n]: ")" OPEN_CURSOR_INPUT
    OPEN_CURSOR_INPUT=${OPEN_CURSOR_INPUT:-Y}
    if [[ "$OPEN_CURSOR_INPUT" =~ ^[Yy]$ ]]; then
        OPEN_CURSOR=true
    fi
fi

# Create the feature directory
mkdir -p "$FEATURE_DIR"

echo ""
echo -e "${BOLD}${BLUE}Creating worktree...${NC}"
echo ""

# Fetch latest from remote
echo -e "  ${CYAN}→${NC} Fetching latest from remote..."
git fetch --all --quiet 2>/dev/null || true

# Check if branch already exists locally
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo -e "  ${YELLOW}⚠${NC}  Branch '${BRANCH_NAME}' already exists locally"
    BRANCH_EXISTS=true
else
    BRANCH_EXISTS=false
fi

# Get default branch (try multiple methods)
DEFAULT_BRANCH=""

# Method 1: Try symbolic-ref
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

# Method 2: Check if origin/main exists
if [ -z "$DEFAULT_BRANCH" ] && git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
    DEFAULT_BRANCH="main"
fi

# Method 3: Check if origin/master exists
if [ -z "$DEFAULT_BRANCH" ] && git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
    DEFAULT_BRANCH="master"
fi

# Method 4: Get the current branch as fallback
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Final fallback
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH="main"
fi

echo -e "  ${CYAN}→${NC} Base branch detected: ${DEFAULT_BRANCH}"

if [ "$BRANCH_EXISTS" = true ]; then
    # Create worktree with existing branch
    echo -e "  ${CYAN}→${NC} Creating worktree with existing branch..."
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
else
    # Create new branch from default branch and add worktree
    echo -e "  ${CYAN}→${NC} Creating worktree with new branch '${BRANCH_NAME}' from '${DEFAULT_BRANCH}'..."
    
    # Try with origin/ prefix first, then without
    if git show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH" 2>/dev/null; then
        git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "origin/$DEFAULT_BRANCH"
    else
        git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$DEFAULT_BRANCH"
    fi
fi

echo -e "  ${GREEN}✓${NC} Worktree created"

# Copy .env file if it exists in the original repo
if [[ "$COPY_ENV" =~ ^[Yy]$ ]] && [ -f "$REPO_ROOT/.env" ]; then
    echo -e "  ${CYAN}→${NC} Copying .env file..."
    cp "$REPO_ROOT/.env" "$WORKTREE_PATH/.env"
    echo -e "  ${GREEN}✓${NC} .env file copied"
fi

# Install dependencies if package.json exists
if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]] && [ -f "$WORKTREE_PATH/package.json" ]; then
    cd "$WORKTREE_PATH"
    
    # Detect package manager by lock file
    if [ -f "pnpm-lock.yaml" ]; then
        echo -e "  ${CYAN}→${NC} Detected pnpm, installing dependencies..."
        pnpm install
    elif [ -f "yarn.lock" ]; then
        echo -e "  ${CYAN}→${NC} Detected yarn, installing dependencies..."
        yarn install
    elif [ -f "package-lock.json" ]; then
        echo -e "  ${CYAN}→${NC} Detected npm, installing dependencies..."
        npm install
    else
        # Default to npm if no lock file found
        echo -e "  ${CYAN}→${NC} No lock file found, using npm to install dependencies..."
        npm install
    fi
    
    echo -e "  ${GREEN}✓${NC} Dependencies installed"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}${GREEN}✓ Worktree created successfully!${NC}"
echo ""
echo -e "${BOLD}Location:${NC} ${CYAN}$WORKTREE_PATH${NC}"
echo ""

# Open in Cursor
if [ "$OPEN_CURSOR" = true ]; then
    echo -e "${CYAN}→${NC} Opening in Cursor..."
    cursor "$WORKTREE_PATH"
else
    echo -e "${CYAN}To open in Cursor:${NC}"
    echo -e "  ${YELLOW}cursor \"$WORKTREE_PATH\"${NC}"
fi

echo ""
echo -e "${GREEN}✓${NC} Done!"
echo ""
