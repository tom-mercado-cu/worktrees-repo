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
OPEN_CURSOR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cursor)
            OPEN_CURSOR=true
            shift
            ;;
        -h|--help)
            echo "Usage: wt-multi-add [-c|--cursor]"
            echo ""
            echo "Add additional repositories to an existing multi-repo worktree workspace."
            echo ""
            echo "Options:"
            echo "  -c, --cursor    Automatically open workspace in Cursor when done"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "This command must be run from within an existing worktree directory"
            echo "that contains a .code-workspace file."
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     Git Worktree - Multi Add           ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required for workspace file parsing.${NC}"
    echo -e "Install with: ${CYAN}brew install jq${NC}"
    exit 1
fi

# Step 2: Workspace File Detection
WORKSPACE_FILE=""
WORKSPACE_DIR=""

# Check current directory for workspace files
shopt -s nullglob
workspace_files=(*.code-workspace)
shopt -u nullglob

if [ ${#workspace_files[@]} -eq 0 ]; then
    # Check parent directory
    shopt -s nullglob
    workspace_files=(../*.code-workspace)
    shopt -u nullglob

    if [ ${#workspace_files[@]} -gt 0 ]; then
        WORKSPACE_DIR="$(cd .. && pwd)"
    fi
else
    WORKSPACE_DIR="$(pwd)"
fi

if [ ${#workspace_files[@]} -eq 0 ]; then
    echo -e "${RED}No .code-workspace file found.${NC}"
    echo -e "Run this command from within an existing worktree directory,"
    echo -e "or use ${CYAN}wt-multi-new${NC} to create a new multi-repo workspace."
    exit 1
elif [ ${#workspace_files[@]} -eq 1 ]; then
    WORKSPACE_FILE="$WORKSPACE_DIR/$(basename "${workspace_files[0]}")"
else
    echo -e "${BLUE}Multiple workspace files found:${NC}"
    echo ""
    for i in "${!workspace_files[@]}"; do
        echo -e "  ${YELLOW}$((i+1))${NC}) $(basename "${workspace_files[$i]}")"
    done
    echo ""
    read -p "Select workspace file (1-${#workspace_files[@]}): " ws_selection
    if [[ "$ws_selection" =~ ^[0-9]+$ ]] && [ "$ws_selection" -ge 1 ] && [ "$ws_selection" -le "${#workspace_files[@]}" ]; then
        WORKSPACE_FILE="$WORKSPACE_DIR/$(basename "${workspace_files[$((ws_selection-1))]}")"
    else
        echo -e "${RED}Invalid selection. Exiting.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Found workspace: ${CYAN}$(basename "$WORKSPACE_FILE")${NC}"
echo ""

# Step 3: Parse Workspace File
EXISTING_REPOS=()
while IFS= read -r name; do
    if [ -n "$name" ]; then
        EXISTING_REPOS+=("$name")
    fi
done < <(jq -r '.folders[].name // .folders[].path | gsub("^\\./"; "")' "$WORKSPACE_FILE" 2>/dev/null)

if [ ${#EXISTING_REPOS[@]} -eq 0 ]; then
    echo -e "${RED}Could not parse workspace file or no folders found.${NC}"
    exit 1
fi

echo -e "${BLUE}Current repos in workspace:${NC}"
for repo in "${EXISTING_REPOS[@]}"; do
    echo -e "  ${CYAN}→${NC} $repo"
done
echo ""

# Infer branch name from workspace filename
WORKSPACE_BASENAME=$(basename "$WORKSPACE_FILE" .code-workspace)

# Try to detect actual branch from first existing worktree
FEATURE_DIR="$(dirname "$WORKSPACE_FILE")"
FIRST_REPO="${EXISTING_REPOS[0]}"
FIRST_WORKTREE="$FEATURE_DIR/$FIRST_REPO"

if [ -d "$FIRST_WORKTREE" ]; then
    BRANCH_NAME=$(cd "$FIRST_WORKTREE" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$BRANCH_NAME" ]; then
        echo -e "${BLUE}Detected branch:${NC} ${CYAN}$BRANCH_NAME${NC}"
    else
        BRANCH_NAME="$WORKSPACE_BASENAME"
        echo -e "${YELLOW}⚠${NC}  Could not detect branch, using workspace name: ${CYAN}$BRANCH_NAME${NC}"
    fi
else
    BRANCH_NAME="$WORKSPACE_BASENAME"
    echo -e "${YELLOW}⚠${NC}  Could not access existing worktree, using workspace name: ${CYAN}$BRANCH_NAME${NC}"
fi
echo ""

# Step 4: Detect Available Repositories
# Navigate to root directory (two levels up from worktrees/feature-dir/)
ROOT_DIR="$(cd "$FEATURE_DIR/../.." && pwd)"

declare -a AVAILABLE_REPOS=()
for dir in "$ROOT_DIR"/*/; do
    if [ -d "$dir/.git" ] || [ -f "$dir/.git" ]; then
        repo_name=$(basename "$dir")
        # Skip worktrees directory and repos already in workspace
        if [ "$repo_name" != "worktrees" ]; then
            is_existing=false
            for existing in "${EXISTING_REPOS[@]}"; do
                if [ "$repo_name" = "$existing" ]; then
                    is_existing=true
                    break
                fi
            done
            if [ "$is_existing" = false ]; then
                AVAILABLE_REPOS+=("$repo_name")
            fi
        fi
    fi
done

if [ ${#AVAILABLE_REPOS[@]} -eq 0 ]; then
    echo -e "${GREEN}All repos are already in this workspace.${NC}"
    exit 0
fi

# Step 5: Interactive Repository Selection
echo -e "${BLUE}Available repositories to add:${NC}"
echo ""

for i in "${!AVAILABLE_REPOS[@]}"; do
    echo -e "  ${YELLOW}$((i+1))${NC}) ${AVAILABLE_REPOS[$i]}"
done

echo ""
echo -e "${BOLD}Select repositories to add:${NC}"
echo -e "${CYAN}(Enter numbers separated by spaces, or 'all' for all repos)${NC}"
echo ""
read -p "Selection: " selection

declare -a SELECTED_REPOS=()
if [ "$selection" = "all" ] || [ "$selection" = "a" ]; then
    SELECTED_REPOS=("${AVAILABLE_REPOS[@]}")
else
    for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#AVAILABLE_REPOS[@]}" ]; then
            SELECTED_REPOS+=("${AVAILABLE_REPOS[$((num-1))]}")
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

# Step 6: Configuration Options
echo ""
echo -e "${BOLD}${BLUE}Configuration options:${NC}"
echo ""

read -p "$(echo -e "  Copy ${CYAN}.env${NC} files from original repos? [Y/n]: ")" COPY_ENV
COPY_ENV=${COPY_ENV:-Y}

read -p "$(echo -e "  Install dependencies? [Y/n]: ")" INSTALL_DEPS
INSTALL_DEPS=${INSTALL_DEPS:-Y}

if [ "$OPEN_CURSOR" = false ]; then
    read -p "$(echo -e "  Open workspace in Cursor when done? [Y/n]: ")" OPEN_CURSOR_INPUT
    OPEN_CURSOR_INPUT=${OPEN_CURSOR_INPUT:-Y}
    if [[ "$OPEN_CURSOR_INPUT" =~ ^[Yy]$ ]]; then
        OPEN_CURSOR=true
    fi
fi

# Step 7: Create Worktrees for Selected Repos
echo ""
echo -e "${BOLD}${BLUE}Creating worktrees...${NC}"
echo ""

declare -a NEWLY_ADDED=()

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
        echo -e "  ${CYAN}→${NC} Adding to workspace file only..."
        NEWLY_ADDED+=("$repo")
        continue
    fi

    # Get default branch
    DEFAULT_BRANCH=""
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    if [ -z "$DEFAULT_BRANCH" ] && git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
        DEFAULT_BRANCH="main"
    fi

    if [ -z "$DEFAULT_BRANCH" ] && git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
        DEFAULT_BRANCH="master"
    fi

    if [ -z "$DEFAULT_BRANCH" ]; then
        DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    fi

    if [ -z "$DEFAULT_BRANCH" ]; then
        DEFAULT_BRANCH="main"
    fi

    echo -e "  ${CYAN}→${NC} Base branch detected: ${DEFAULT_BRANCH}"

    if [ "$BRANCH_EXISTS" = true ]; then
        echo -e "  ${CYAN}→${NC} Creating worktree with existing branch..."
        git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    else
        echo -e "  ${CYAN}→${NC} Creating worktree with new branch '${BRANCH_NAME}' from '${DEFAULT_BRANCH}'..."
        if git show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH" 2>/dev/null; then
            git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "origin/$DEFAULT_BRANCH"
        else
            git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$DEFAULT_BRANCH"
        fi
    fi

    echo -e "  ${GREEN}✓${NC} Worktree created at: ${WORKTREE_PATH}"

    NEWLY_ADDED+=("$repo")

    # Copy .env file if it exists in the original repo
    if [[ "$COPY_ENV" =~ ^[Yy]$ ]] && [ -f "$REPO_PATH/.env" ]; then
        echo -e "  ${CYAN}→${NC} Copying .env file..."
        cp "$REPO_PATH/.env" "$WORKTREE_PATH/.env"
        echo -e "  ${GREEN}✓${NC} .env file copied"
    fi

    # Install dependencies if package.json exists
    if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]] && [ -f "$WORKTREE_PATH/package.json" ]; then
        cd "$WORKTREE_PATH"

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
            echo -e "  ${CYAN}→${NC} No lock file found, using npm to install dependencies..."
            npm install
        fi

        echo -e "  ${GREEN}✓${NC} Dependencies installed"
    fi
done

# Step 8: Update Workspace File
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}→${NC} Updating workspace file..."

# Add new repos to workspace file using jq
TEMP_FILE=$(mktemp)
cp "$WORKSPACE_FILE" "$TEMP_FILE"

for repo in "${NEWLY_ADDED[@]}"; do
    jq --arg name "$repo" --arg path "./$repo" \
        '.folders += [{"name": $name, "path": $path}]' \
        "$TEMP_FILE" > "${TEMP_FILE}.new" && mv "${TEMP_FILE}.new" "$TEMP_FILE"
done

# Validate JSON and write back
if jq . "$TEMP_FILE" > /dev/null 2>&1; then
    mv "$TEMP_FILE" "$WORKSPACE_FILE"
    echo -e "${GREEN}✓${NC} Workspace file updated"
else
    echo -e "${RED}Error: Generated invalid JSON. Workspace file not updated.${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Step 9: Final Output
echo ""
echo -e "${BOLD}${GREEN}✓ Successfully added ${#NEWLY_ADDED[@]} repo(s) to workspace!${NC}"
echo ""

echo -e "${BOLD}Newly added worktrees:${NC}"
for repo in "${NEWLY_ADDED[@]}"; do
    echo -e "  ${GREEN}→${NC} $repo"
done

echo ""

if [ "$OPEN_CURSOR" = true ]; then
    echo -e "${CYAN}→${NC} Opening workspace in Cursor..."
    cursor "$WORKSPACE_FILE"
else
    echo -e "${CYAN}To open the workspace in Cursor, run:${NC}"
    echo -e "  ${YELLOW}cursor \"$WORKSPACE_FILE\"${NC}"
fi

echo ""
echo -e "${GREEN}✓${NC} Done!"
echo ""
