# IDEA: wt-multi-add Command

## Summary

Add a new command `wt-multi-add` that allows users to add additional repos to an existing multi-repo worktree workspace.

## Problem

After creating a multi-repo worktree with `wt-multi-new`, users sometimes need to add more repos to the workspace. Currently this requires manual worktree creation and workspace file editing.

## Requirements

- Run from within an existing worktree directory
- Detect the `.code-workspace` file automatically
- Parse workspace to find current repos and branch name
- Present interactive multi-select of repos NOT already in workspace
- Create worktrees for selected repos on the same branch
- Update `.code-workspace` file with new folder entries
- Copy `.env` files from main repos to new worktrees
- Install dependencies (npm/bundle/etc.) in new worktrees
- Support `-c` flag to reopen workspace in Cursor
- Update `README.md` with documentation for the new command
- Update `install.sh` to include the new command in installation

## Edge Cases

- **No workspace found**: Error with message directing user to run from worktree or use `wt-multi-new`
- **All repos already added**: Exit with message "All repos are already in this workspace"

## Implementation Notes

- Reuse worktree creation logic from `wt-multi-new.sh` (lines 139-242)
- Reuse dependency installation patterns from `wt-multi-new.sh`
- Workspace JSON parsing can use `jq` for reliability

## Out of Scope

- Removing repos from workspace (separate command if needed)
- Command-line repo arguments (interactive only)
