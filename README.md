# Git Worktree Tools 🌿

> The ultimate guide for using git worktrees with AI coding assistants - single repo AND multi-repo workflows

---

## 📖 Table of Contents

1. [Why Git Worktrees?](#-why-git-worktrees)
2. [Installation](#-installation)
3. [Single-Repo Workflow](#-single-repo-workflow)
4. [Multi-Repo Workflow](#-multi-repo-workflow)
5. [Command Reference](#-command-reference)
6. [Real-World Examples](#-real-world-examples)
7. [Pro Tips](#-pro-tips)
8. [Troubleshooting](#-troubleshooting)

---

## 🎯 Why Git Worktrees?

### The Problem

- Working with AI assistants on multiple tasks simultaneously
- Need to review PRs while working on features
- Want to avoid accidental changes to the wrong branch
- Tired of stashing/unstashing or losing context
- Working on fullstack features across multiple repos

### The Solution

Git worktrees let you have **multiple branches checked out simultaneously** in different directories, all linked to the same repository (or multiple repositories).

### Benefits

- ✅ **Isolate AI agent work** - Each task in its own workspace
- ✅ **Work in parallel** - Multiple branches, no switching
- ✅ **Review without interruption** - Check PRs while keeping your work intact
- ✅ **Faster builds** - No branch switching overhead
- ✅ **Error-proof** - AI can't accidentally touch other branches
- ✅ **Cursor integration** - One command to create + open
- ✅ **Multi-repo support** - Work on front + back simultaneously
- ✅ **Auto-setup** - Copies `.env`, installs dependencies automatically

---

## 📦 Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/tom-mercado-cu/worktrees-repo/refs/heads/main/remote-install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/tom-mercado-cu/worktrees-repo.git ~/.wt-tools
cd ~/.wt-tools
./install.sh
source ~/.zshrc
```

### Verify Installation

```bash
wt-help
```

---

## 🔨 Single-Repo Workflow

> Use this for: Daily development, single-service features, PR reviews, experiments

### Quick Start

```bash
# From inside any repo
wt-new feature/GTT-1234-my-feature -c

# Or from a directory containing repos
wt-new subscription-front feature/GTT-1234-my-feature -c

# Cursor opens automatically!
```

### Create New Worktree

```bash
# From inside the repo
wt-new feature/branch-name

# From inside the repo + open Cursor
wt-new feature/branch-name -c

# From outside, specifying repo name
wt-new admin-front feature/branch-name -c
```

**What happens:**

1. Fetches latest from remote
2. Creates new branch from default branch (main/master)
3. Asks to copy `.env` file (if exists)
4. Asks to install dependencies (detects pnpm/yarn/npm)
5. Opens in Cursor (if `-c` flag)

### Checkout Existing Branch

```bash
# From inside the repo
wt-existing feature/existing-branch -c

# From outside, specifying repo name
wt-existing subscription-back feature/existing-branch -c
```

**Bonus:** Shows recent remote branches to help you pick:

```
Recent remote branches:
  origin/feature/GTT-1234-auth
  origin/feature/GTT-1235-payments
  origin/bugfix/GTT-1236-fix
```

### Navigate & Manage

```bash
# List all worktrees and navigate interactively
wt-list

# Remove worktrees (interactive, with branch cleanup option)
wt-clean

# Clean orphaned references across all repos
wt-prune
```

### Directory Structure

```
~/projects/
├── subscription-front/              # Main repo
├── subscription-back/               # Main repo
│
└── worktrees/                       # All worktrees live here
    ├── feature-GTT-1234-auth/
    │   ├── subscription-front/      # Worktree
    │   ├── subscription-back/       # Worktree
    │   └── feature-GTT-1234-auth.code-workspace
    │
    └── bugfix-GTT-5678-fix/
        └── subscription-front/      # Single-repo worktree
```

---

## 🔀 Multi-Repo Workflow

> Use this for: Fullstack features, coordinated changes, hotfixes across services

### Quick Start

```bash
# From directory containing your repos
wt-multi-new -c

# Interactive menu appears
# Select repos, enter branch name
# Cursor opens with unified workspace!
```

### When to Use Multi-Repo

**✅ Use multi-repo when:**

- Building fullstack features (front + back)
- Making coordinated changes across services
- Hotfixes that affect multiple repos
- Need unified workspace for related work

**❌ Use single-repo when:**

- Only working on frontend OR backend
- Quick fixes in one service
- PR reviews
- Daily isolated development

### Interactive Flow

```bash
wt-multi-new -c
```

**You'll see:**

```
╔════════════════════════════════════════╗
║     Git Worktree - Multi Repo          ║
╚════════════════════════════════════════╝

Found 3 git repositories:
  1) subscription-front
  2) subscription-back
  3) cx-tools-service

Select repositories to create worktrees for:
(Enter numbers separated by spaces, or 'all' for all repos)

Selection: 1 2

Selected repositories:
  → subscription-front
  → subscription-back

Enter branch name: feature/GTT-1234-auth

Configuration options:
  Copy .env files from original repos? [Y/n]:
  Install dependencies? [Y/n]:
  Open workspace in Cursor when done? [Y/n]:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Processing: subscription-front
  → Fetching latest from remote...
  → Base branch detected: main
  → Creating worktree with new branch 'feature/GTT-1234-auth' from 'main'...
  ✓ Worktree created
  → Copying .env file...
  ✓ .env file copied
  → Detected pnpm, installing dependencies...
  ✓ Dependencies installed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Processing: subscription-back
  → Fetching latest from remote...
  → Base branch detected: master
  → Creating worktree with new branch 'feature/GTT-1234-auth' from 'master'...
  ✓ Worktree created
  → Copying .env file...
  ✓ .env file copied

✓ All worktrees created successfully!
✓ Workspace file created

→ Opening workspace in Cursor...
✓ Done!
```

### Workspace Files

The multi-repo workflow automatically creates `.code-workspace` files:

```json
{
  "folders": [
    { "name": "subscription-front", "path": "./subscription-front" },
    { "name": "subscription-back", "path": "./subscription-back" }
  ],
  "settings": {}
}
```

**Benefits:**

- Single Cursor window for all repos
- Unified search across codebase
- Shared terminal
- AI sees full context

### Adding Repos to Existing Workspace

If you've created a multi-repo workspace and need to add more repos later:

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

---

## 📋 Command Reference

### Single-Repo Commands

| Command                            | Description                     | Example                     |
| ---------------------------------- | ------------------------------- | --------------------------- |
| `wt-new [repo] <branch> [-c]`      | Create worktree with new branch | `wt-new feature/auth -c`    |
| `wt-existing [repo] <branch> [-c]` | Checkout existing branch        | `wt-existing hotfix/bug -c` |

### Multi-Repo Commands

| Command                   | Description                       | Example            |
| ------------------------- | --------------------------------- | ------------------ |
| `wt-multi-new [dir] [-c]` | Create worktrees across repos     | `wt-multi-new -c`  |
| `wt-multi-add [-c]`       | Add repos to existing workspace   | `wt-multi-add -c`  |

### Navigation & Management

| Command     | Description                                         |
| ----------- | --------------------------------------------------- |
| `wt-list`   | List worktrees and navigate interactively           |
| `wt-clean`  | Remove worktrees (interactive, with branch cleanup) |
| `wt-prune`  | Clean orphaned references in all repos              |
| `wt-help`   | Show help                                           |
| `wt-update` | Update to latest version                            |

### Flags

| Flag             | Description                   |
| ---------------- | ----------------------------- |
| `-c`, `--cursor` | Open in Cursor after creation |

---

## 🌟 Real-World Examples

### Example 1: Daily Feature Development

```bash
# Morning: Start new feature
cd ~/projects/subscription-front
wt-new feature/GTT-8901-dark-mode -c

# Work with Claude/Cursor
# ... implement dark mode ...

# Commit and push
git add .
git commit -m "feat: add dark mode"
git push origin feature/GTT-8901-dark-mode

# Afternoon: Urgent PR review comes in
wt-existing pr/urgent-fix -c
# Review in separate Cursor window
# Approve PR

# Back to your feature via wt-list
wt-list
# Select your feature worktree

# Next day: Feature merged, clean up
wt-clean
# Select the feature, confirm deletion
# Answer 'y' to delete branch
```

### Example 2: Fullstack Feature (Multi-Repo)

```bash
# From your projects directory
cd ~/projects
wt-multi-new -c
# Select: 1 2 (front + back)
# Branch: feature/GTT-9001-user-settings

# Workspace opens with both repos in same window

# Backend first
cd worktrees/feature-GTT-9001-user-settings/subscription-back
# ... implement API ...
git commit -am "feat(api): user settings endpoint"
git push

# Frontend integration (same workspace!)
cd ../subscription-front
# ... integrate API ...
git commit -am "feat(ui): settings page"
git push

# Create linked PRs
# After merge:
wt-clean
```

### Example 3: Quick PR Review

```bash
# Review a colleague's PR without leaving your work
wt-existing subscription-front feature/colleague-feature -c

# Review in Cursor
# Leave comments, approve

# Clean up
wt-clean
# Select the PR worktree
# Answer 'n' to keep their branch
```

### Example 4: Experiment Without Risk

```bash
# Try risky refactor
wt-new experiment/new-architecture -c

# Experiment fails
wt-clean
# Select experiment worktree
# Answer 'y' to delete branch

# No harm done to main codebase!
```

### Example 5: Working on Multiple Features

```bash
# Start feature A
wt-new feature/GTT-1001-feature-a -c

# Need to switch to feature B
wt-new feature/GTT-1002-feature-b -c

# Switch between them using wt-list
wt-list
# Select the one you want to work on
```

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

---

## 💡 Pro Tips

### Cursor Integration

```bash
# Always use -c flag for instant editor
wt-new feature/x -c           # Opens immediately
wt-existing branch -c         # Opens immediately
wt-multi-new -c              # Opens workspace immediately
```

### Branch Naming

**Good naming conventions:**

```bash
feature/GTT-1234-descriptive-name
bugfix/GTT-5678-issue-description
hotfix/critical-bug-name
experiment/new-idea
pr/colleague-feature          # For PR reviews
```

**Benefits:**

- Easy to identify purpose
- Links to tickets automatically
- Consistent across team
- Easier cleanup

### Multi-Repo Best Practices

1. **Keep branch names identical** across repos

   ```bash
   # Front: feature/GTT-1234-auth
   # Back:  feature/GTT-1234-auth
   ```

2. **Create PRs together**

   - Link PRs in descriptions
   - Merge at the same time

3. **Use workspace files**

   - Opens all repos in one window
   - Shared context for AI

4. **Clean up together**
   - Use `wt-clean` to remove all at once

### AI Assistant Tips

1. **Isolated context**

   ```bash
   wt-new ai-feature-1 -c    # Agent 1
   wt-new ai-feature-2 -c    # Agent 2
   # Both work independently
   ```

2. **Safe experiments**

   ```bash
   wt-new experiment/ai-suggestion -c
   # Try it, delete if bad
   ```

3. **Full-stack context**
   ```bash
   wt-multi-new -c
   # AI sees both front + back
   # Better suggestions
   ```

### Weekly Cleanup Routine

```bash
# See all worktrees
wt-list

# Clean up old ones
wt-clean
# Select multiple by number (e.g., "1 3 5")
# Or "all" to remove everything

# Prune any orphaned references
wt-prune
```

---

## 🆘 Troubleshooting

### "fatal: 'branch' is already used by worktree"

**Problem:** Branch is checked out somewhere else

**Solution:**

```bash
wt-list                  # Find where it's checked out
wt-clean                 # Remove old worktree
wt-new branch -c         # Create new one
```

### "No such worktree"

**Problem:** Directory deleted manually

**Solution:**

```bash
wt-prune    # Clean up references
```

### "Not inside a git repository"

**Problem:** Running single-repo command from wrong directory

**Solution:**

```bash
# Either cd into a repo first
cd ~/projects/subscription-front
wt-new feature/x -c

# Or specify the repo name
wt-new subscription-front feature/x -c
```

### "Repository 'x' not found in current directory"

**Problem:** Repo name typo or wrong directory

**Solution:**

```bash
# Make sure you're in the parent directory containing repos
cd ~/projects
ls  # Verify repo names

wt-new correct-repo-name feature/x -c
```

### Cursor not opening

**Problem:** Cursor not in PATH

**Solution:**

```bash
# Check if cursor is installed
which cursor

# If not found, open Cursor and install shell command:
# Cursor → Command Palette → "Shell Command: Install 'cursor' command"

# Or use without -c flag and open manually
wt-new feature/x
cursor path/to/worktree
```

### wt-multi-add: No workspace file found

**Problem:** Running `wt-multi-add` from wrong directory

**Solution:**

```bash
# Must run from within a worktree directory containing a .code-workspace file
cd worktrees/feature-branch-name
wt-multi-add -c

# Or use wt-multi-new to create a new workspace first
wt-multi-new -c
```

### wt-multi-add: All repos already in workspace

**Problem:** All available repos are already added to the workspace

**Solution:**

```bash
# This is expected - nothing to add!
# If you need to work with different repos, create a new workspace:
wt-multi-new -c
```

### Can't remove worktree (in use)

**Problem:** Terminal or editor open in that directory

**Solution:**

```bash
# Close all terminals/editors in that worktree
# Then run wt-clean again

# The script will force-remove if needed
```

### Node modules issues

**Problem:** Dependencies different between worktrees

**Solution:**

```bash
# Each worktree is independent
# Re-install deps if needed
cd worktrees/feature-x/repo-name
rm -rf node_modules
pnpm install  # or npm/yarn
```

---

## 🎓 Quick Decision Tree

```
Need to work on code?
│
├─ Single service?
│  │
│  ├─ New branch? → wt-new feature/x -c
│  ├─ Existing branch? → wt-existing branch -c
│  └─ PR review? → wt-existing pr-branch -c
│
└─ Multiple services (front + back)?
   │
   ├─ New workspace? → wt-multi-new -c
   └─ Add to existing? → wt-multi-add -c

Need to clean up?
│
└─ Always → wt-clean (handles single and multi)

Need to navigate?
│
└─ Always → wt-list

Need help?
│
└─ wt-help
```

---

## ✨ Features

- ✅ Automatic `.env` file copying
- ✅ Dependency installation (detects pnpm/yarn/npm)
- ✅ Auto-detection of default branch (main/master)
- ✅ Auto-fetch before creating worktrees
- ✅ `.code-workspace` generation for multi-repo
- ✅ Incremental workspace building (add repos anytime)
- ✅ Branch cleanup on worktree removal
- ✅ Cursor integration with `-c` flag
- ✅ Works from inside or outside repos
- ✅ Interactive menus for easy management

---

## 🔄 Update

```bash
~/.wt-tools/update.sh
source ~/.zshrc
```

This will:

1. Remove old aliases from your `.zshrc`
2. Delete the old installation
3. Clone the latest version
4. Run the installer again

## 🗑️ Uninstall

1. Remove the aliases from your `~/.zshrc` (search for "Git Worktree management")
2. Delete the directory: `rm -rf ~/.wt-tools`

---

## 📚 Resources

- [Official Git Worktree Docs](https://git-scm.com/docs/git-worktree)
- [Cursor Editor](https://cursor.sh/)

---

## 🎯 Summary

**Single-Repo Workflow:**

- Fast, simple, daily development
- Perfect for AI assistants
- One command: `wt-new feature/x -c`

**Multi-Repo Workflow:**

- Fullstack features
- Coordinated changes
- Unified workspace: `wt-multi-new -c`

**Golden Rules:**

1. One worktree = one task
2. Clean up after merging
3. Use `-c` flag for instant Cursor
4. Run `wt-help` when stuck

---

**Questions?** Run `wt-help` or check this guide!
