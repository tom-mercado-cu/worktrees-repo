# Git Worktree Tools 🌿

Herramientas para gestionar git worktrees de forma simple, diseñadas para trabajar con AI coding assistants (Cursor, etc).

## ⚡ Instalación Rápida

```bash
curl -fsSL https://raw.githubusercontent.com/tom-mercado-cu/worktrees-repo/main/remote-install.sh | bash
```

O manualmente:

```bash
git clone https://github.com/tom-mercado-cu/worktrees-repo.git ~/.wt-tools
cd ~/.wt-tools
./install.sh
source ~/.zshrc
```

## 📦 Comandos

### Single-Repo

```bash
# Crear worktree con nueva branch (desde dentro del repo)
wt-new feature/my-branch -c

# Crear worktree especificando el repo (desde cualquier lugar)
wt-new admin-front feature/my-branch -c

# Checkout de branch existente
wt-existing feature/existing-branch -c
wt-existing admin-front feature/existing-branch -c
```

### Multi-Repo

```bash
# Crear worktrees en múltiples repos (fullstack)
wt-multi-new -c
```

### Navegación y Gestión

```bash
wt-list      # Listar y navegar a worktrees
wt-clean     # Eliminar worktrees
wt-prune     # Limpiar referencias huérfanas
wt-help      # Mostrar ayuda
```

## 🎯 Flags

| Flag | Descripción |
|------|-------------|
| `-c`, `--cursor` | Abrir en Cursor después de crear |

## 📂 Estructura de Directorios

```
tu-proyecto/
├── repo-1/                      ← Repos principales
├── repo-2/
└── worktrees/
    └── feature-branch-name/
        ├── repo-1/              ← Worktrees
        ├── repo-2/
        └── feature-branch-name.code-workspace
```

## ✨ Features

- ✅ Copia automática de `.env`
- ✅ Instalación de dependencias (detecta pnpm/yarn/npm)
- ✅ Auto-detección de branch default (main/master)
- ✅ Generación de `.code-workspace` para multi-repo
- ✅ Limpieza de branches al eliminar worktrees
- ✅ Integración con Cursor

## 🔄 Actualizar

```bash
cd ~/.wt-tools && git pull
source ~/.zshrc
```

## 🗑️ Desinstalar

1. Eliminar los aliases de tu `~/.zshrc` (buscar "Git Worktree management")
2. Eliminar el directorio: `rm -rf ~/.wt-tools`

## 💡 Ejemplos de Uso

### Trabajo diario (single-repo)

```bash
# Empezar feature
cd ~/projects/my-app
wt-new feature/GTT-1234-auth -c

# ... trabajar con Cursor/AI ...

# Al terminar, limpiar
wt-clean
```

### Fullstack feature (multi-repo)

```bash
# Desde directorio con front + back
cd ~/projects
wt-multi-new -c
# Seleccionar repos, ingresar branch name
# Se abre Cursor con workspace unificado
```

### Review de PR

```bash
wt-existing subscription-front pr/fix-bug -c
# Revisar, aprobar, cerrar
wt-clean
```
