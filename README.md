# Git Worktree Tools 🌿

Simple git worktree management tools, designed for working with AI coding assistants (Cursor, etc).

## ⚡ Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/tom-mercado-cu/worktrees-repo/refs/heads/main/remote-install.sh | bash
```

Or manually:

```bash
git clone https://github.com/tom-mercado-cu/worktrees-repo.git ~/.wt-tools
cd ~/.wt-tools
./install.sh
source ~/.zshrc
```

## 📦 Commands

### Single-Repo

```bash
# Create worktree with new branch (from inside the repo)
wt-new feature/my-branch -c

# Create worktree specifying the repo (from anywhere)
wt-new admin-front feature/my-branch -c

# Checkout existing branch
wt-existing feature/existing-branch -c
wt-existing admin-front feature/existing-branch -c
```

### Multi-Repo

```bash
# Create worktrees across multiple repos (fullstack)
wt-multi-new -c
```

### Navigation & Management

```bash
wt-list      # List and navigate to worktrees
wt-clean     # Remove worktrees
wt-prune     # Clean up orphaned references
wt-help      # Show help
```

## 🎯 Flags

| Flag             | Description                   |
| ---------------- | ----------------------------- |
| `-c`, `--cursor` | Open in Cursor after creation |

## 📂 Directory Structure

```
your-project/
├── repo-1/                      ← Main repos
├── repo-2/
└── worktrees/
    └── feature-branch-name/
        ├── repo-1/              ← Worktrees
        ├── repo-2/
        └── feature-branch-name.code-workspace
```

## ✨ Features

- ✅ Automatic `.env` file copying
- ✅ Dependency installation (detects pnpm/yarn/npm)
- ✅ Auto-detection of default branch (main/master)
- ✅ `.code-workspace` generation for multi-repo
- ✅ Branch cleanup when removing worktrees
- ✅ Cursor integration

## 🔄 Update

```bash
cd ~/.wt-tools && git pull
source ~/.zshrc
```

## 🗑️ Uninstall

1. Remove the aliases from your `~/.zshrc` (search for "Git Worktree management")
2. Delete the directory: `rm -rf ~/.wt-tools`

## 💡 Usage Examples

### Daily work (single-repo)

```bash
# Start a feature
cd ~/projects/my-app
wt-new feature/GTT-1234-auth -c

# ... work with Cursor/AI ...

# When done, clean up
wt-clean
```

### Fullstack feature (multi-repo)

```bash
# From directory containing front + back
cd ~/projects
wt-multi-new -c
# Select repos, enter branch name
# Cursor opens with unified workspace
```

### PR Review

```bash
wt-existing subscription-front pr/fix-bug -c
# Review, approve, close
wt-clean
```
