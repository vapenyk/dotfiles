# pkg — Declarative Package Manager for Arch Linux

`pkg` is a single-file, declarative package manager wrapper for Arch Linux. Instead of running `pacman`, `paru`, `flatpak`, and `uv` by hand, you describe your entire system in TOML files and let `pkg` keep it in sync — idempotently, with automatic backend bootstrapping and lifecycle hook scripts.

**Requires:** Python 3.11+ · **Platform:** Arch Linux

---

## Table of Contents

- [Why pkg](#why-pkg)
- [Quick Start](#quick-start)
- [File Layout](#file-layout)
- [Commands](#commands)
- [Configuration Reference](#configuration-reference)
  - [backends.toml](#backendstoml)
  - [Package Group Files](#package-group-files)
  - [Package Entries](#package-entries)
- [Hook Scripts](#hook-scripts)
- [Backend Bootstrap System](#backend-bootstrap-system)
- [Environment Variables](#environment-variables)
- [Database](#database)
- [Typical Workflows](#typical-workflows)
- [Tips and Caveats](#tips-and-caveats)

---

## Why pkg

Most Arch users manage packages from several sources: pacman for official packages, paru/yay for AUR, flatpak for sandboxed GUI apps, uv for Python CLI tools. `pkg` treats all of these as interchangeable *backends* and lets you declare what you want in plain TOML files that you can check into version control alongside your dotfiles.

Key properties:

- **Declarative.** Your TOML files are the source of truth. `pkg sync` makes reality match them.
- **Idempotent.** Running `pkg sync` twice is safe — already-installed packages are detected via live system queries, not just the database.
- **Safe prune.** `pkg prune` only touches packages that `pkg` itself installed. Anything you installed manually is never removed.
- **Smart bootstrap.** Missing backends (paru, flatpak, uv) are automatically installed before `pkg` tries to use them.
- **Self-contained.** The entire tool is a single Python file with no third-party dependencies beyond `tomllib` (built into Python 3.11+).

---

## Quick Start

```bash
# 1. Generate default config files
pkg init

# 2. Review and edit what gets installed
$EDITOR ~/.config/pkg/packages/base.toml
$EDITOR ~/.config/pkg/packages/flatpak.toml

# 3. Preview what will happen (read-only, no changes)
pkg diff

# 4. Install everything
pkg sync
```

That's it. On subsequent runs, `pkg sync` is safe to re-run at any time — it only installs what is missing.

---

## File Layout

After `pkg init`, your config directory looks like this:

```
~/.config/pkg/
├── backends.toml          ← backend definitions (pacman, paru, flatpak, uv)
├── packages/              ← one file per group
│   ├── base.toml
│   └── flatpak.toml
└── scripts/               ← lifecycle hook scripts
    ├── before-sync.sh
    ├── after-sync.sh
    └── bootstrap-paru.sh

~/.local/share/pkg/
└── installed.db           ← SQLite, tracks what pkg itself installed
```

Both directories can be overridden via environment variables (see [Environment Variables](#environment-variables)).

---

## Commands

### `pkg init`

Creates the default config files and example scripts. Safe to re-run — it will not overwrite existing files unless you pass `--force`.

```bash
pkg init           # create default files, skip existing
pkg init --force   # overwrite everything
```

What gets created:

- `~/.config/pkg/backends.toml` — four pre-configured backends (pacman, paru, flatpak, uv)
- `~/.config/pkg/packages/base.toml` — example base packages group
- `~/.config/pkg/packages/flatpak.toml` — example Flatpak apps group
- `~/.config/pkg/scripts/before-sync.sh` — example pre-sync hook
- `~/.config/pkg/scripts/after-sync.sh` — example post-sync hook
- `~/.config/pkg/scripts/bootstrap-paru.sh` — example AUR bootstrap script
- `~/.local/share/pkg/installed.db` — empty SQLite database

**Flags:**

| Flag | Description |
|------|-------------|
| `--force` | Overwrite existing config files |

---

### `pkg sync`

The main command. Installs all packages defined in your `packages/*.toml` files. Groups are processed in priority order (lowest number first).

```bash
pkg sync                          # install everything
pkg sync base wayland             # only these groups
pkg sync --exclude apps flatpak   # all groups except these
pkg sync base --exclude tools     # combine: only base, skipping tools
pkg sync --skip-errors            # continue past individual install failures
pkg sync --strict-hooks           # abort if any hook script fails
```

**What sync does, step by step:**

1. Runs `before-sync.sh` hook (if it exists)
2. Checks which backends are needed and bootstraps any that are missing
3. For each group in priority order:
   - Runs `before-{backend}.sh` hook
   - Queries the live system for currently installed packages
   - Installs anything missing, records each install in the database
   - Runs any per-package `after_install` hooks
   - Runs `after-{backend}.sh` hook
4. Runs `after-sync.sh` hook
5. Prints a summary: N installed, M already up to date

**Flags:**

| Flag | Description |
|------|-------------|
| `GROUP ...` | Positional — process only these groups by name |
| `--exclude GROUP`, `-x GROUP` | Skip these groups (accepts multiple values) |
| `--skip-errors` | On install failure, log and continue to next package |
| `--strict-hooks` | Abort the entire sync if any hook script exits non-zero |

---

### `pkg diff`

Read-only preview of what `sync` would do. Compares your TOML config against the database. Makes no changes to your system.

```bash
pkg diff                   # diff everything
pkg diff wayland           # diff a specific group
pkg diff --exclude flatpak # diff all except one group
```

Output shows two sections:

- **Will install** — packages in config but not yet in the database
- **Not in config anymore** — packages in the database but removed from config (candidates for `prune`)

The "not in config" section is only shown when not filtering by group, to avoid false positives when you're only looking at a subset of your config.

**Flags:** same group filtering as `sync` (`GROUP ...` and `--exclude`).

---

### `pkg prune`

Finds packages that `pkg` installed (tracked in the database) which no longer appear in your config. Asks interactively before removing each one.

```bash
pkg prune                  # check all groups
pkg prune base             # only look for orphans in the base group
pkg prune --exclude dev    # check everything except dev group
```

**Important:** `prune` is completely safe with respect to packages you installed manually outside of `pkg`. It only considers packages that exist in its own database — it will never touch anything else.

The interactive prompt for each orphaned package:

```
  - [pacman] some-old-package
  - [flatpak] io.example.OldApp

  Remove [pacman] some-old-package? [y/N]
```

If the backend for a package is no longer defined in `backends.toml`, `prune` removes it from the database only (it cannot uninstall it, but warns you).

**Flags:** same group filtering as `sync`.

---

### `pkg groups`

Lists all available package groups from `packages/*.toml`, sorted by priority.

```bash
pkg groups
```

Example output:

```
Available groups
──────────────────────────────────────────

  base  priority=10  42 packages  [pacman, paru, uv]
    CLI tools, editors, shell utilities

  wayland  priority=20  18 packages  [pacman, paru]
    niri compositor, DMS shell, display tools

  flatpak  priority=40  12 packages  [flatpak]
    GUI apps from Flathub
```

---

### `pkg status`

Gives an overview of the entire system: backend health, package install progress per group, hook scripts, and all relevant paths.

```bash
pkg status
```

Example output:

```
Backends
──────────────────────────────────────────
  [pacman]                       ✓ available   Official Arch repos
  [paru]                         ✓ available   AUR helper (wraps pacman)  (smart bootstrap)
  [flatpak]                      ✗ missing     Flatpak universal packages
  [uv]                           ✓ available   Python CLI tools via uv

Package groups
──────────────────────────────────────────
  base                 42/42  installed  priority=10
  flatpak              0/12   installed  priority=40  GUI apps from Flathub

Hook scripts
──────────────────────────────────────────
  before-sync.sh                      ✓
  after-sync.sh                       ✓
  bootstrap-paru.sh                   ✓

Paths
──────────────────────────────────────────
  Config:   /home/user/.config/pkg
  Packages: /home/user/.config/pkg/packages
  Scripts:  /home/user/.config/pkg/scripts
  Database: /home/user/.local/share/pkg/installed.db
```

Backends marked with `(smart bootstrap)` have `install_self_try` or `install_self_script` configured and will be installed automatically when needed.

---

### `pkg list`

Lists all packages tracked in the database, grouped by backend.

```bash
pkg list
```

Example output:

```
Installed packages (from database)
──────────────────────────────────────────

  pacman  (38)
    • bat
    • btop
    • git
    ...

  flatpak  (12)
    • io.anytype.anytype
    • md.obsidian.Obsidian
    ...

  Total: 50 packages across 2 backends
```

---

## Configuration Reference

### `backends.toml`

Located at `~/.config/pkg/backends.toml`. Defines every package manager backend that `pkg` can use.

```toml
[backends.pacman]
description         = "Official Arch repos"
check_cmd           = ["which", "pacman"]
install_self        = []
install_pkg         = ["sudo", "pacman", "-S", "--noconfirm", "--needed"]
remove_pkg          = ["sudo", "pacman", "-Rns", "--noconfirm"]
list_installed      = ["pacman", "-Qq"]
list_strip_version  = false
```

**All available fields:**

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Human-readable label shown in `pkg status` |
| `check_cmd` | list of strings | Command that exits 0 if the backend is already installed. Omit or leave empty to skip the check (e.g. pacman is always present on Arch). |
| `install_self` | list of strings | Command to install the backend itself. Simple — no fallback. |
| `install_self_try` | list of strings | Try this command first. If it fails (non-zero exit), fall through to `install_self_script`. Useful when a tool is in official repos on some distros (CachyOS) but needs AUR on others. |
| `install_self_script` | string | Filename of a script in `scripts/` to run if `install_self_try` fails. Use this for AUR-only or complex installs. |
| `after_install_self` | list of lists | Commands to run once immediately after the backend is successfully installed. Example: adding the Flathub remote right after flatpak is installed. |
| `install_pkg` | list of strings | Command prefix for installing a package. The package name is appended automatically. |
| `remove_pkg` | list of strings | Command prefix for removing a package. The package name is appended automatically. |
| `list_installed` | list of strings | Command that prints installed package names, one per line. Used by `sync` to detect what's already there without relying on the database alone. |
| `list_strip_version` | bool | Set to `true` if `list_installed` output is `"name version"` per line (e.g. `uv tool list`). `pkg` will strip the version before comparing. |

**Bootstrap priority.** When a backend is missing, `pkg` tries strategies in this order:

1. `install_self_try` — runs the command, on success stops here
2. `install_self_script` — runs `scripts/<name>.sh` (only if step 1 failed)
3. `install_self` — legacy direct command, no fallback

You can use `install_self_try` + `install_self_script` together (the recommended pattern for paru), or just `install_self` alone (simpler, for backends always available in official repos).

---

### Package Group Files

Each file in `~/.config/pkg/packages/` defines one group. The filename stem becomes the group name (`wayland.toml` → group `wayland`).

```toml
# ~/.config/pkg/packages/wayland.toml

[group]
display     = "Wayland Stack"
description = "niri compositor, DMS shell, display tools"
priority    = 20

[pacman]
packages = [
  "niri",
  "waybar",
  "swww",
]

[paru]
packages = [
  "some-aur-package",
]
```

**`[group]` metadata** (all optional):

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `display` | string | group name | Human-readable label shown in `pkg groups` and `pkg status` |
| `description` | string | `""` | Short description shown below the group name |
| `priority` | integer | `50` | Install order — lower number = installed first. Groups with the same priority are sorted alphabetically. |

**Backend sections** — any key other than `[group]` is treated as a backend name. The section must match a key in `backends.toml`. A group can have packages for multiple backends in the same file.

---

### Package Entries

Inside a backend section, each entry in `packages = [...]` can be either a plain string or a table with hooks.

**Simple form** — just the package name:

```toml
[pacman]
packages = [
  "git",
  "neovim",
  "btop",
]
```

**Extended form** — with an `after_install` hook:

```toml
[pacman]
packages = [
  "git",
  { name = "sddm", hooks = { after_install = ["sudo", "systemctl", "enable", "sddm"] } },
  { name = "swayidle", hooks = { after_install = ["systemctl", "--user", "enable", "swayidle"] } },
]
```

The `after_install` hook runs once, immediately after the package is installed. It is a best-effort operation — a non-zero exit from the hook is logged but does not stop the sync. Both forms can be mixed freely in the same list.

**Note:** per-package hooks run only once, at install time. For operations that should run on every sync, use [hook scripts](#hook-scripts) instead.

---

## Hook Scripts

Scripts in `~/.config/pkg/scripts/` are executed on every matching `pkg sync`. They are shell scripts that you write and maintain — `pkg init` creates examples you can edit.

**Naming convention:**

| Script name | When it runs |
|-------------|-------------|
| `before-sync.sh` | Before the entire sync starts |
| `after-sync.sh` | After the entire sync completes |
| `before-{backend}.sh` | Before processing each backend's packages (e.g. `before-paru.sh`) |
| `after-{backend}.sh` | After all packages for a backend are done (e.g. `after-flatpak.sh`) |

Scripts must be executable (`chmod +x`). If a script exists but is not executable, `pkg` will print a warning and skip it.

**Environment variables** available inside every hook script:

| Variable | Value |
|----------|-------|
| `PKG_EVENT` | The event name, e.g. `"before-sync"`, `"after-flatpak"` |
| `PKG_CONFIG_DIR` | Path to the config directory (e.g. `~/.config/pkg`) |
| `PKG_DATA_DIR` | Path to the data directory (e.g. `~/.local/share/pkg`) |

**Example — `before-sync.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Pull dotfiles before installing new packages
cd ~/dotfiles && git pull --ff-only

# Check for pending system updates
checkupdates || true
```

**Example — `after-sync.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Re-apply dotfiles with stow
cd ~/dotfiles && stow --restow --ignore='.git' .

# Desktop notification
notify-send "pkg sync" "All packages installed" --icon=package-x-generic
```

**Failure behavior** — by default, a failing hook prints a warning and continues. Pass `--strict-hooks` to `pkg sync` to abort on any hook failure:

```bash
pkg sync --strict-hooks
```

---

## Backend Bootstrap System

One of `pkg`'s core features is that it never tries to use a backend that isn't installed. Before processing any group, `pkg` checks which backends are needed and ensures they are all ready.

**Example: paru on stock Arch Linux**

The default `backends.toml` configures paru with two strategies:

```toml
[backends.paru]
install_self_try    = ["sudo", "pacman", "-S", "--noconfirm", "--needed", "paru"]
install_self_script = "bootstrap-paru.sh"
```

When paru is missing, `pkg` will:

1. Try `pacman -S paru` — this works on CachyOS where paru is in official repos
2. If that fails, run `scripts/bootstrap-paru.sh` — which clones from AUR and builds with `makepkg`

The generated `bootstrap-paru.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

git clone --depth=1 https://aur.archlinux.org/paru.git "$tmpdir"
cd "$tmpdir"
makepkg -si --noconfirm
```

**Example: flatpak with post-install hook**

```toml
[backends.flatpak]
install_self        = ["sudo", "pacman", "-S", "--noconfirm", "--needed", "flatpak"]
after_install_self  = [
  ["flatpak", "remote-add", "--if-not-exists", "flathub",
   "https://dl.flathub.org/repo/flathub.flatpakrepo"],
]
```

After flatpak is installed, `pkg` immediately adds the Flathub remote so subsequent `flatpak install` calls work without any manual step.

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PKG_CONFIG_DIR` | `~/.config/pkg` | Override the config directory. Useful for testing or multiple profiles. |
| `PKG_DATA_DIR` | `~/.local/share/pkg` | Override the data directory where the database lives. |

Example — use a separate profile for a minimal install:

```bash
PKG_CONFIG_DIR=~/.config/pkg-minimal pkg sync
```

---

## Database

`pkg` maintains a SQLite database at `~/.local/share/pkg/installed.db` that records every package it has installed.

**Schema:**

```sql
CREATE TABLE installed (
    backend      TEXT NOT NULL,
    package      TEXT NOT NULL,
    group_name   TEXT NOT NULL DEFAULT '',
    installed_at TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (backend, package)
);
```

The database is the source of truth for `prune` — it is how `pkg` knows which packages it installed vs. which were installed by the user manually. You can inspect it directly with any SQLite client:

```bash
sqlite3 ~/.local/share/pkg/installed.db "SELECT * FROM installed ORDER BY installed_at DESC LIMIT 20;"
```

The database is created and migrated automatically on every `pkg` invocation — you never need to manage it manually.

---

## Typical Workflows

### Initial setup on a fresh Arch install

```bash
# Install pkg itself
install -Dm755 pkg.py ~/.local/bin/pkg

# Generate defaults, then customize
pkg init
$EDITOR ~/.config/pkg/backends.toml
$EDITOR ~/.config/pkg/packages/base.toml

# Preview before touching anything
pkg diff

# Install everything (backends bootstrapped automatically)
pkg sync
```

### Adding a new package

1. Open the appropriate group file: `$EDITOR ~/.config/pkg/packages/base.toml`
2. Add the package name to the right backend section
3. Run `pkg sync` or `pkg diff` first to preview

### Removing a package

1. Delete the line from the group file
2. Run `pkg diff` to confirm it shows up as "not in config anymore"
3. Run `pkg prune` to interactively remove it

### Syncing only part of your config

```bash
pkg sync wayland          # only the wayland group
pkg sync --exclude flatpak  # everything except flatpak
pkg diff base             # preview only base group
```

### Re-installing a package that was manually removed

Just run `pkg sync`. Because `pkg` checks the live system state (not only the database), a manually removed package will appear as missing and be reinstalled automatically.

### Checking system health

```bash
pkg status    # backend availability, install progress, hook scripts
pkg list      # all tracked packages grouped by backend
```

### Keeping config in version control

Because the entire config is plain text TOML files, you can track them in your dotfiles repo:

```bash
cd ~/dotfiles
ln -s ~/.config/pkg pkg
git add pkg/
git commit -m "add pkg config"
```

On a new machine: clone your dotfiles, symlink or stow the config, run `pkg sync`.

---

## Tips and Caveats

**`pkg sync` is idempotent** — it is safe to run on every login or from a cron job. It will detect what is already installed via live system queries and skip those packages, so only genuinely missing packages trigger an install.

**Group priority controls install order.** If group B depends on a tool from group A (e.g. `uv` installed by `base` before `uv` packages in another group), give group A a lower priority number. The default is 50; `base.toml` uses priority 10.

**Backends that share a `list_installed` command** (e.g. both `pacman` and `paru` use `pacman -Qq`) will correctly detect packages installed by either one.

**The `--skip-errors` flag** is useful when syncing a fresh system where some AUR packages might temporarily fail to build. Without it, `pkg sync` aborts on the first install failure.

**Hook scripts are always run**, even if all packages are already installed. Use them for operations that should happen on every sync (pulling dotfiles, stowing configs, etc.).

**ANSI colors** are automatically disabled when output is piped or redirected, so `pkg sync | tee install.log` works cleanly.

**Adding a custom backend** — any tool that can install, remove, and list packages can be used as a backend. Add a `[backends.mytool]` section to `backends.toml` and create a matching section in your package group files.
