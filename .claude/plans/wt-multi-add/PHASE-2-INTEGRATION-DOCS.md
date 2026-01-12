# Phase 2: Integration and Documentation

## Objective

Integrate the new `wt-multi-add` command into the existing toolchain by updating installation scripts, help documentation, and README with usage examples. Validate the end-to-end flow to ensure seamless user experience.

## Prerequisites

- Phase 1 must be complete (wt-multi-add.sh script implemented and tested)
- `wt-multi-add.sh` script exists and is executable
- Script successfully adds repos to existing workspaces
- Workspace file updates function correctly

## Estimated Skills

| Category | Sub-Skill | Reason |
|----------|-----------|--------|
| `documentation` | `technical-writing` | Need to write clear command documentation, usage examples, and update README |
| `bash-scripting` | `shell-automation` | Update install.sh alias definitions and wt-help.sh command reference |

## Implementation Steps

### Step 0: Validate Prerequisites

- [x] Verify `wt-multi-add.sh` script exists in the repository root
- [x] Verify the script is executable: `test -x wt-multi-add.sh && echo "OK" || echo "FAIL"`
- [x] If not executable, run: `chmod +x wt-multi-add.sh`

### Step 1: Update Installation Script

- [x] Open `install.sh` file
- [x] Locate the ALIASES_BLOCK section (search for "Multi-repo commands" comment)
- [x] Add new alias entry under "Multi-repo commands" section, after the `wt-multi-new` alias: `alias wt-multi-add='$SCRIPT_DIR/wt-multi-add.sh'`
- [x] Ensure placement is after `wt-multi-new` for logical grouping
- [x] Verify the alias uses consistent formatting with existing aliases

### Step 2: Update Help Documentation

- [x] Open `wt-help.sh` file
- [x] Locate the "Multi-Repo Commands" section (search for "Multi-Repo Commands" header)
- [x] Add new command entry after the `wt-multi-new` entry:
  ```
  echo -e "  ${YELLOW}wt-multi-add${NC} ${DIM}[directory] [-c]${NC}"
  echo -e "      Add additional repos to existing workspace"
  echo -e "      ${DIM}Options: -c, --cursor  Reopen workspace in Cursor after adding${NC}"
  echo ""
  ```
- [x] Update the installation preview section in `install.sh` (search for "Commands that will be available" section) to list the new `wt-multi-add` command

### Step 3: Update README Documentation

- [x] Open `README.md` file
- [x] Locate "Multi-Repo Commands" section in the command reference table (search for "Multi-Repo Commands" header)
- [x] Add new table row for `wt-multi-add` after the `wt-multi-new` entry:
  ```markdown
  | `wt-multi-add [dir] [-c]` | Add repos to existing workspace | `wt-multi-add -c` |
  ```
- [x] Locate "Multi-Repo Workflow" section (search for "## Multi-Repo Workflow" heading)
- [x] Add new subsection after the multi-repo workflow explanation, titled "### Adding Repos to Existing Workspace"
- [x] Write usage example:
  ```markdown
  ### Adding Repos to Existing Workspace

  If you've created a multi-repo workspace and need to add more repos:

  ```bash
  # From within the worktree directory
  cd worktrees/feature-GTT-1234-auth
  wt-multi-add -c

  # Interactive menu shows only repos NOT already in workspace
  # Select additional repos
  # Workspace reopens with new repos included
  ```

  **What happens:**

  1. Detects existing `.code-workspace` file
  2. Determines branch name from workspace context
  3. Shows repos not yet added to workspace
  4. Creates worktrees on same branch as existing repos
  5. Updates workspace file with new folder entries
  6. Reopens in Cursor (if `-c` flag)
  ```
- [x] Add entry to Table of Contents linking to "Adding Repos to Existing Workspace" section
- [x] Update "Features" section if needed to mention incremental workspace building

### Step 4: Add Example Use Case

- [x] In README.md "Real-World Examples" section (search for "## Real-World Examples" heading), add "Example 6: Incrementally Building Workspace" after Example 5
- [x] Write example scenario:
  ```markdown
  ### Example 6: Incrementally Building Workspace

  ```bash
  # Start with just frontend
  cd ~/projects
  wt-multi-new -c
  # Select: 1 (subscription-front only)
  # Branch: feature/GTT-1234-payments

  # Work on frontend
  # ... realize you need backend too ...

  # Add backend to existing workspace
  cd worktrees/feature-GTT-1234-payments
  wt-multi-add -c
  # Select: subscription-back
  # Workspace reopens with both repos

  # Continue working with full stack context
  # Both repos on same branch, unified workspace
  ```
  ```

### Step 5: Validate End-to-End Flow

- [ ] Test installation: Run `./install.sh` or `./update.sh -y` to verify alias is added
- [ ] Reload shell: `source ~/.zshrc`
- [ ] Verify alias exists: `alias | grep wt-multi-add`
- [ ] Test help command: Run `wt-help` and verify `wt-multi-add` appears in Multi-Repo section
- [ ] Create test workspace: `wt-multi-new` with 1 repo selected
- [ ] Test add command: `wt-multi-add` from within workspace directory
- [ ] Verify workspace update: Check `.code-workspace` file contains new repo
- [ ] Test `-c` flag: Verify Cursor reopens with updated workspace
- [ ] Test error cases: Run from non-workspace directory, verify helpful error message

### Step 6: Document Edge Cases

- [x] Locate the "Troubleshooting" section in README.md (search for "## Troubleshooting" heading)
- [x] Add entry for "wt-multi-add: No workspace file found"
- [x] Add entry for "wt-multi-add: All repos already in workspace"
- [x] Document solution steps for each edge case

## Files to Create/Modify

- `install.sh` - Add `wt-multi-add` alias in ALIASES_BLOCK after `wt-multi-new` and update installation preview section
- `wt-help.sh` - Add `wt-multi-add` command documentation in Multi-Repo Commands section after `wt-multi-new` entry
- `README.md` - Add command to Multi-Repo Commands table, add "Adding Repos to Existing Workspace" section under Multi-Repo Workflow, add Example 6 after Example 5, add troubleshooting entries

## Validation

- [ ] Run `./install.sh -y` completes without errors
- [ ] Run `source ~/.zshrc` and `wt-multi-add` alias exists
- [ ] Run `wt-help` and `wt-multi-add` appears in correct section with description
- [ ] Create test multi-repo workspace with `wt-multi-new` (1 repo)
- [ ] Run `wt-multi-add -c` from workspace directory successfully adds second repo
- [ ] Verify `.code-workspace` file is valid JSON and contains both repos
- [ ] Verify Cursor reopens with updated workspace when `-c` flag used
- [ ] README.md renders correctly with new sections and examples
- [ ] All hyperlinks in README.md Table of Contents work correctly

## Notes

### Installation Script Patterns

Follow existing alias format:
```bash
alias wt-multi-add='$SCRIPT_DIR/wt-multi-add.sh'
```

Ensure the new alias is included in both:
1. The ALIASES_BLOCK variable that gets written to `.zshrc`
2. The installation preview shown to users

### Help Documentation Format

Use consistent color coding:
- `${YELLOW}` for command names
- `${DIM}` for optional arguments and descriptions
- `${NC}` to reset colors

Follow the pattern: command name, arguments, description, then options with additional detail.

### README Structure

Maintain existing documentation style:
- Use emojis for section headers (already present)
- Keep code blocks with bash syntax highlighting
- Include "What happens" explanations for multi-step processes
- Link examples to real-world scenarios
- Keep command reference table format consistent

### Testing Notes

Test both "happy path" and edge cases:
- Happy path: Start with 1 repo, add 1 more
- Edge case: Try to run from non-workspace directory
- Edge case: All repos already added
- Edge case: Workspace file is malformed or missing

Verify `-c` flag behavior:
- Cursor must reopen workspace (not just open directory)
- Workspace should reflect new repos immediately

### Cross-Reference

Ensure consistency across all three files:
- Command name: `wt-multi-add`
- Description: "Add repos to existing workspace" or similar
- Flags: `-c, --cursor` for Cursor integration
- Directory argument: `[directory]` optional parameter
