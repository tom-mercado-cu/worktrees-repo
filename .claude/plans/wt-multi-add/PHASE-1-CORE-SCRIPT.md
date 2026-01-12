# Phase 1: Core Script Implementation

## Objective

Create the `wt-multi-add.sh` script that enables users to add additional repositories to an existing multi-repo worktree workspace. The script must auto-detect the workspace file, parse it to determine current repos and branch, present interactive repo selection, create worktrees on the same branch, and update the workspace JSON file with new folder entries.

## Prerequisites

- `jq` must be installed for JSON parsing
- `git` must be available for worktree operations
- User must have an existing multi-repo workspace created by `wt-multi-new`
- Access to root directory containing main repository clones

## Estimated Skills

| Category | Sub-Skill | Reason |
|----------|-----------|--------|
| `bash-scripting` | N/A | Core script logic, argument parsing, control flow, string manipulation |
| `git-worktrees` | N/A | Creating worktrees, branch detection, handling existing branches |
| `json-parsing` | N/A | Parsing .code-workspace file with jq, updating JSON structure |

## Implementation Steps

### Step 1: Create Script File and Argument Parsing

- [ ] Create `wt-multi-add.sh` in repository root
- [ ] Add shebang, `set -e`, and color definitions (reuse from wt-multi-new.sh lines 1-12)
- [ ] Parse `-c|--cursor` flag to set `OPEN_CURSOR` variable
- [ ] Add header banner output for visual consistency

### Step 2: Workspace File Detection

- [ ] Check current directory for `*.code-workspace` files using glob pattern
- [ ] If not found, check parent directory (handle case where user is in repo subdirectory)
- [ ] If multiple workspace files found, prompt user to select one
- [ ] If no workspace file found, display error and exit with message "No .code-workspace file found"
- [ ] Extract workspace filename for later reference

### Step 3: Parse Workspace File

- [ ] Use `jq` to extract folders array from workspace JSON
- [ ] Parse folder names from `folders[].name` or `folders[].path` fields
- [ ] Store existing repo names in array `EXISTING_REPOS`
- [ ] Infer branch name from workspace filename (remove `.code-workspace` extension)
- [ ] Convert sanitized branch dir name back to branch name (replace `-` with `/` where appropriate)

### Step 4: Detect Available Repositories

- [ ] Determine root directory by navigating two levels up from workspace location (worktrees/feature-dir/)
- [ ] Find all directories with `.git` in root directory
- [ ] Filter out repos already in `EXISTING_REPOS` array
- [ ] Filter out `worktrees` directory itself
- [ ] Store available repos in `AVAILABLE_REPOS` array
- [ ] If no available repos, display "All repos are already in workspace" and exit

### Step 5: Interactive Repository Selection

- [ ] Display numbered list of available repositories
- [ ] Prompt user with "Select repositories to add: (Enter numbers separated by spaces, or 'all')"
- [ ] Parse user selection (handle 'all', 'a', or space-separated numbers)
- [ ] Validate selection indices are within bounds
- [ ] Store selected repos in `SELECTED_REPOS` array
- [ ] Display selected repos for confirmation

### Step 6: Configuration Options

- [ ] Prompt for copying `.env` files (default Y)
- [ ] Prompt for installing dependencies (default Y)
- [ ] Prompt for opening in Cursor if not set via `-c` flag (default Y)

### Step 7: Create Worktrees for Selected Repos

- [ ] Determine feature directory from workspace file location
- [ ] Loop through `SELECTED_REPOS` array
- [ ] For each repo, change to repo path in root directory
- [ ] Fetch latest from remote with `git fetch --all`
- [ ] Check if branch already exists locally with `git show-ref`
- [ ] Detect default branch using methods from wt-multi-new.sh (lines 167-191)
- [ ] Create worktree using appropriate git command based on branch existence
- [ ] Copy `.env` file if option enabled and file exists (lines 213-218 pattern)
- [ ] Install dependencies if option enabled and `package.json` exists (lines 220-241 pattern)
- [ ] Display progress with colored output for each repo

### Step 8: Update Workspace File

- [ ] Use `jq` to read existing workspace JSON
- [ ] For each newly created worktree, add folder object to folders array
- [ ] Each folder object format: `{"name": "repo-name", "path": "./repo-name"}`
- [ ] Preserve existing settings and other workspace properties
- [ ] Write updated JSON back to workspace file with proper formatting
- [ ] Validate JSON structure after writing

### Step 9: Final Output and Cursor Integration

- [ ] Display success message with count of repos added
- [ ] List newly added worktrees with paths
- [ ] If `OPEN_CURSOR` is true, execute `cursor "$WORKSPACE_FILE"`
- [ ] Otherwise, display command to open workspace manually
- [ ] Display "Done!" completion message

## Files to Create/Modify

- `wt-multi-add.sh` - New script implementing all workspace detection, parsing, worktree creation, and workspace update logic

## Validation

- [ ] Run `wt-multi-add` from within an existing multi-repo worktree directory
- [ ] Verify script detects the `.code-workspace` file correctly
- [ ] Confirm only repos NOT in workspace are listed for selection
- [ ] Create worktrees and verify they use the same branch as existing repos
- [ ] Check that workspace JSON is valid and contains new folder entries with `jq . workspace.code-workspace`
- [ ] Verify `.env` files are copied when present
- [ ] Confirm dependencies are installed based on detected lock files
- [ ] Test `-c` flag reopens workspace in Cursor
- [ ] Test edge cases: no workspace file, all repos already added, invalid selections
- [ ] Run `bash -n wt-multi-add.sh` to check for syntax errors

## Notes

### Branch Name Inference

The workspace filename uses sanitized branch names where `/` is replaced with `-`. To convert back:
- Simple feature branches: `feature-auth` → `feature-auth` (no conversion needed)
- Nested branches: `feature-GTT-1234-auth` could be `feature/GTT-1234-auth` or `feature-GTT-1234-auth`
- **Mitigation**: If branch detection fails, check the actual branch of first existing worktree as fallback

### Workspace JSON Manipulation

Use `jq` for all JSON operations to ensure validity:
```bash
# Read folders array
jq -r '.folders[].name' workspace.code-workspace

# Add new folder (example)
jq '.folders += [{"name": "new-repo", "path": "./new-repo"}]' workspace.code-workspace
```

### Error Handling

- If `jq` is not installed, display error: "jq is required for workspace file parsing. Install with: brew install jq"
- If root directory detection fails, prompt user for root directory path
- If git operations fail, skip repo and continue with others (non-fatal)

### Code Reuse

Reuse patterns from `wt-multi-new.sh`:
- Color definitions and formatting (lines 6-12)
- Worktree creation logic (lines 139-209)
- `.env` copying (lines 213-218)
- Dependency installation (lines 220-241)
- Default branch detection (lines 167-191)
