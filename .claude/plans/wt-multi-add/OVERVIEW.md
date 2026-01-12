# Plan: wt-multi-add Command

## Summary

Add a new `wt-multi-add` command that allows users to add additional repositories to an existing multi-repo worktree workspace, complementing the existing `wt-multi-new` command.

## Context

### Problem Statement

After creating a multi-repo worktree with `wt-multi-new`, users sometimes need to add more repos to the workspace. Currently this requires:
1. Manually creating worktrees with `git worktree add`
2. Manually editing the `.code-workspace` JSON file
3. Manually copying `.env` files
4. Manually installing dependencies

### Solution

Create `wt-multi-add` command that automates adding repos to an existing multi-repo workspace by:
- Auto-detecting the `.code-workspace` file in current directory or parent
- Parsing workspace to determine current repos and branch name
- Presenting interactive selection of repos NOT already in workspace
- Creating worktrees on the same branch used by existing repos
- Updating the workspace file with new folder entries
- Handling `.env` copying and dependency installation

## Requirements Summary

| ID | Requirement | Priority |
|----|-------------|----------|
| R1 | Run from within existing worktree directory | Must |
| R2 | Auto-detect `.code-workspace` file | Must |
| R3 | Parse workspace JSON for current repos and infer branch | Must |
| R4 | Interactive multi-select of available repos | Must |
| R5 | Create worktrees on same branch as existing | Must |
| R6 | Update `.code-workspace` with new folder entries | Must |
| R7 | Copy `.env` files from main repos | Should |
| R8 | Install dependencies (npm/yarn/pnpm) | Should |
| R9 | Support `-c` flag to reopen in Cursor | Should |
| R10 | Handle "no workspace found" edge case | Must |
| R11 | Handle "all repos already added" edge case | Must |
| R12 | Update README.md documentation | Must |
| R13 | Update install.sh with new alias | Must |
| R14 | Update wt-help.sh with command info | Must |

## Technical Approach

### Workspace Detection Strategy

1. Check current directory for `*.code-workspace` files
2. If not found, check parent directory (user may be inside a repo subdirectory)
3. Extract branch name from workspace file name (format: `{branch-dir-name}.code-workspace`)
4. Parse JSON using `jq` for reliability

### Branch Detection

The workspace filename follows pattern `{branch-dir-name}.code-workspace` where `branch-dir-name` is the sanitized branch name (slashes replaced with dashes). Use this to determine the branch for new worktrees.

### Available Repos Detection

1. Navigate to root directory (two levels up from worktrees/feature-dir/)
2. Find all git repositories (directories with `.git`)
3. Exclude repos already in workspace folders array
4. Exclude the `worktrees` directory itself

### Reusable Code from wt-multi-new.sh

- Lines 139-242: Worktree creation loop with git operations
- Lines 213-218: `.env` file copying logic
- Lines 220-241: Dependency installation with package manager detection
- Lines 250-274: Workspace JSON structure (for updating)

## Phases

| Phase | Name | Description | Dependencies | Status |
|-------|------|-------------|--------------|--------|
| 1 | Core Script Implementation | Create wt-multi-add.sh with workspace detection, repo selection, worktree creation, and workspace update | None | pending |
| 2 | Integration and Documentation | Update install.sh, wt-help.sh, README.md, and test end-to-end flow | Phase 1 | pending |

## Dependencies

### External Tools
- `jq` - JSON parsing for workspace file manipulation
- `git` - Worktree creation and branch operations
- `gum` - Interactive multi-select for repo selection (existing project dependency)

### Skills
- None required from `.claude/skills/`

### Cross-Project Dependencies
- None

## Success Criteria

1. User can run `wt-multi-add` from within a worktree feature directory
2. Command correctly identifies repos not yet in workspace
3. New worktrees are created on the same branch as existing repos
4. Workspace file is updated with new folder entries (valid JSON)
5. `.env` files are copied when present
6. Dependencies are installed based on lock file detection
7. `-c` flag reopens the workspace in Cursor
8. Edge cases display appropriate error messages
9. All documentation is updated consistently

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Branch name inference from workspace filename may fail for complex branch names | Medium | Fall back to checking branch of first existing worktree |
| jq not installed on user system | Low | Provide fallback using grep/sed or prompt user to install jq |
| Workspace JSON structure changes | Low | Use standard VS Code workspace format, validate JSON before writing |

## References

- IDEA file: `.claude/plans/wt-multi-add-IDEA.md`
- Existing multi-repo command: `wt-multi-new.sh`
- Workspace file format: VS Code multi-root workspace specification
