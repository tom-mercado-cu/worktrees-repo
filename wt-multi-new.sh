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
ROOT_DIR=""
OPEN_CURSOR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cursor)
            OPEN_CURSOR=true
            shift
            ;;
        *)
            if [ -z "$ROOT_DIR" ]; then
                ROOT_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Default to current directory if not specified
ROOT_DIR="${ROOT_DIR:-$(pwd)}"
WORKTREES_DIR="$ROOT_DIR/worktrees"

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Git Worktree - Multi Repo          ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Find all directories that are git repositories
declare -a REPOS=()
for dir in "$ROOT_DIR"/*/; do
    if [ -d "$dir/.git" ] || [ -f "$dir/.git" ]; then
        repo_name=$(basename "$dir")
        # Skip the worktrees directory itself
        if [ "$repo_name" != "worktrees" ]; then
            REPOS+=("$repo_name")
        fi
    fi
done

if [ ${#REPOS[@]} -eq 0 ]; then
    echo -e "${RED}No git repositories found in $ROOT_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}Found ${#REPOS[@]} git repositories:${NC}"
echo ""

# Display repos with numbers
for i in "${!REPOS[@]}"; do
    echo -e "  ${YELLOW}$((i+1))${NC}) ${REPOS[$i]}"
done

echo ""
echo -e "${BOLD}Select repositories to create worktrees for:${NC}"
echo -e "${CYAN}(Enter numbers separated by spaces, or 'all' for all repos)${NC}"
echo ""
read -p "Selection: " selection

# Parse selection
declare -a SELECTED_REPOS=()
if [ "$selection" = "all" ] || [ "$selection" = "a" ]; then
    SELECTED_REPOS=("${REPOS[@]}")
else
    for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#REPOS[@]}" ]; then
            SELECTED_REPOS+=("${REPOS[$((num-1))]}")
        else
            echo -e "${RED}Invalid selection: $num${NC}"
        fi
    done
fi

if [ ${#SELECTED_REPOS[@]} -eq 0 ]; then
    echo -e "${RED}No repositories selected. Exiting.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Selected repositories:${NC}"
for repo in "${SELECTED_REPOS[@]}"; do
    echo -e "  ${CYAN}→${NC} $repo"
done

# Get branch name
echo ""
read -p "$(echo -e ${BOLD}Enter branch name:${NC} )" BRANCH_NAME

if [ -z "$BRANCH_NAME" ]; then
    echo -e "${RED}Branch name cannot be empty. Exiting.${NC}"
    exit 1
fi

# Sanitize branch name for directory (replace / with -)
BRANCH_DIR_NAME=$(echo "$BRANCH_NAME" | sed 's/\//-/g')

# Ask user preferences
echo ""
echo -e "${BOLD}${BLUE}Configuration options:${NC}"
echo ""

read -p "$(echo -e "  Copy ${CYAN}.env${NC} files from original repos? [Y/n]: ")" COPY_ENV
COPY_ENV=${COPY_ENV:-Y}

read -p "$(echo -e "  Install dependencies? [Y/n]: ")" INSTALL_DEPS
INSTALL_DEPS=${INSTALL_DEPS:-Y}

# Ask about Cursor if not already set via flag
if [ "$OPEN_CURSOR" = false ]; then
    read -p "$(echo -e "  Open workspace in Cursor when done? [Y/n]: ")" OPEN_CURSOR_INPUT
    OPEN_CURSOR_INPUT=${OPEN_CURSOR_INPUT:-Y}
    if [[ "$OPEN_CURSOR_INPUT" =~ ^[Yy]$ ]]; then
        OPEN_CURSOR=true
    fi
fi

# Create feature directory inside worktrees
FEATURE_DIR="$WORKTREES_DIR/$BRANCH_DIR_NAME"
mkdir -p "$FEATURE_DIR"

echo ""
echo -e "${BOLD}${BLUE}Creating worktrees...${NC}"
echo ""

# Create worktrees for each selected repo
for repo in "${SELECTED_REPOS[@]}"; do
    REPO_PATH="$ROOT_DIR/$repo"
    WORKTREE_PATH="$FEATURE_DIR/$repo"
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Processing: ${CYAN}$repo${NC}"
    
    cd "$REPO_PATH"
    
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
    
    # Check if worktree already exists
    if [ -d "$WORKTREE_PATH" ]; then
        echo -e "  ${YELLOW}⚠${NC}  Worktree already exists at ${WORKTREE_PATH}"
        echo -e "  ${CYAN}→${NC} Skipping..."
        continue
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
    
    echo -e "  ${GREEN}✓${NC} Worktree created at: ${WORKTREE_PATH}"
    
    # Copy .env file if it exists in the original repo
    if [[ "$COPY_ENV" =~ ^[Yy]$ ]] && [ -f "$REPO_PATH/.env" ]; then
        echo -e "  ${CYAN}→${NC} Copying .env file..."
        cp "$REPO_PATH/.env" "$WORKTREE_PATH/.env"
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
done

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}${GREEN}✓ All worktrees created successfully!${NC}"
echo ""

# Generate .code-workspace file
WORKSPACE_FILE="$FEATURE_DIR/${BRANCH_DIR_NAME}.code-workspace"

echo -e "${CYAN}→${NC} Generating workspace file..."

# Start building the workspace JSON
WORKSPACE_JSON='{\n\t"folders": ['

FIRST=true
for repo in "${SELECTED_REPOS[@]}"; do
    WORKTREE_PATH="$FEATURE_DIR/$repo"
    if [ -d "$WORKTREE_PATH" ]; then
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            WORKSPACE_JSON="$WORKSPACE_JSON,"
        fi
        WORKSPACE_JSON="$WORKSPACE_JSON\n\t\t{\n\t\t\t\"name\": \"${repo}\",\n\t\t\t\"path\": \"./${repo}\"\n\t\t}"
    fi
done

WORKSPACE_JSON="$WORKSPACE_JSON\n\t],\n\t\"settings\": {}\n}"

# Write workspace file
echo -e "$WORKSPACE_JSON" > "$WORKSPACE_FILE"

echo -e "${GREEN}✓${NC} Workspace file created: ${CYAN}${WORKSPACE_FILE}${NC}"

echo ""
echo -e "${BOLD}Feature directory:${NC} ${CYAN}$FEATURE_DIR${NC}"
echo ""
echo -e "${BOLD}Created worktrees:${NC}"
for repo in "${SELECTED_REPOS[@]}"; do
    WORKTREE_PATH="$FEATURE_DIR/$repo"
    if [ -d "$WORKTREE_PATH" ]; then
        echo -e "  ${GREEN}→${NC} $repo"
    fi
done

echo ""

# Open workspace in Cursor
if [ "$OPEN_CURSOR" = true ]; then
    echo -e "${CYAN}→${NC} Opening workspace in Cursor..."
    cursor "$WORKSPACE_FILE"
else
    echo -e "${CYAN}To open the workspace in Cursor later, run:${NC}"
    echo -e "  ${YELLOW}cursor \"$WORKSPACE_FILE\"${NC}"
fi

echo ""
echo -e "${GREEN}✓${NC} Done!"
echo ""
