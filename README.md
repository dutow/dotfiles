# Dotfiles

Configuration management for quickly setting up new Linux installations using **Ansible** for package management and **Dotbot** for symlinking configuration files.

Everything is specific to how I want to set things up, but the generic structure can be useful for others.

## Supported platforms

| OS                         | Console | WSL | Desktop |
|----------------------------|---------|-----|---------|
| Ubuntu LTS (22.04, 24.04)  | yes     | yes | —       |
| openSUSE Tumbleweed        | yes     | yes | yes     |
| Oracle Linux (8, 9, 10)    | yes     | yes | —       |

Desktop environments currently only target Tumbleweed (Hyprland).

## Quick start

```bash
git clone --recursive <repo-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh                          # auto-detect from hostname / environment
./install.sh --env wsl                # WSL setup (includes all dev sets)
./install.sh --env desktop            # full desktop (includes all dev sets)
./install.sh --sets cpp-dev,node-dev  # console + specific dev sets
```

The install script auto-detects the distribution, installs Ansible if needed, initializes submodules, and runs the playbook.

When no `--env` or `--sets` flags are given, the configuration is resolved in this order:

1. **Host-specific defaults** — if the machine's hostname matches a file in `inventory/host_vars/` (e.g. `ddesk.yml`, `dwork.yml`), those settings are used automatically.
2. **Auto-detection** — the `detect` role checks for WSL (via `/proc/version`) and sets the environment to `wsl` if detected, otherwise falls back to `console`.
3. For `desktop` and `wsl` environments, all package sets are included by default. For `console`, no optional sets are included unless specified.

## Architecture

```
install.sh          Entry point — parses args, bootstraps Ansible
site.yml            Main Ansible playbook (localhost)
ansible.cfg         Ansible configuration
inventory/
  localhost.yml     Local connection setup
  group_vars/       Global variables (home dir, distro key mapping)
  host_vars/        Per-host overrides (ddesk, dwork)
roles/              Ansible roles (one per component)
links/              Dotbot symlink configurations
```

### Environments

- **console** — minimal setup for servers, VMs, containers
- **wsl** — console + desktop apps that work under WSL
- **desktop** — full desktop environment with Hyprland

### Optional package sets

These are included automatically for `wsl` and `desktop` environments, but can be selected individually for console setups:

| Set          | What it installs                                        |
|--------------|---------------------------------------------------------|
| `cpp-dev`    | gcc, clang, cmake, ninja, meson, flex, bison, and libs  |
| `ruby-dev`   | ruby, rvm (Ubuntu), postgresql dev headers               |
| `node-dev`   | nodejs, npm                                              |
| `python-dev` | python3-dev, pip, pipenv                                 |

## Ansible roles

Roles are applied in order from `site.yml`. The `detect` role always runs first.

| Role            | Tags           | Condition                        | Purpose                                          |
|-----------------|----------------|----------------------------------|--------------------------------------------------|
| `detect`        | always         | —                                | Auto-detect distro, environment, and sets         |
| `base`          | base           | —                                | Core packages (curl, git, wget, ssh, jq)          |
| `shell`         | shell          | —                                | zsh + starship prompt                             |
| `neovim`        | neovim         | —                                | Neovim (unstable PPA on Ubuntu)                   |
| `git-tools`     | git-tools      | —                                | git, tig, delta                                   |
| `console-tools` | console-tools  | —                                | mc, ripgrep, fd, tmux, glances                    |
| `cpp-dev`       | cpp-dev        | `'cpp-dev' in dotfiles_sets`     | C/C++ toolchain                                   |
| `ruby-dev`      | ruby-dev       | `'ruby-dev' in dotfiles_sets`    | Ruby development                                  |
| `node-dev`      | node-dev       | `'node-dev' in dotfiles_sets`    | Node.js development                               |
| `python-dev`    | python-dev     | `'python-dev' in dotfiles_sets`  | Python development                                |
| `ai-tools`      | ai-tools       | env is `desktop` or `wsl`        | AI development tools                               |
| `desktop`       | desktop        | env is `desktop` or `wsl`        | Ghostty, Mesa, Wayland libs, NVIDIA drivers (opt.) |
| `hyprland`      | hyprland       | env is `desktop`                 | Hyprland WM + uwsm, greetd, waybar, wofi, etc.    |
| `desktop-apps`  | desktop-apps   | env is `desktop`                 | Desktop apps (zypper + Flatpak)                    |
| `wsl`           | wsl            | env is `wsl`                     | WSL-specific config (placeholder)                  |
| `links`         | links          | —                                | Dotbot symlinks (always last)                      |

### Desktop apps (Tumbleweed)

Native packages (zypper): Firefox, Thunderbird, KeePassXC, VS Code, podman

Flatpak (via Flathub): Slack, Steam, Discord, Dropbox

### NVIDIA drivers

NVIDIA GPU support is opt-in per host via the `desktop_nvidia_gpu` variable in `inventory/host_vars/`. When enabled, the NVIDIA repository is added and G06 driver packages are installed. Defaults to `false`.

```yaml
# inventory/host_vars/<hostname>.yml
desktop_nvidia_gpu: true
```

## Dotbot symlinks

The `links` role runs Dotbot with two config files:

**`links/base.conf.yaml`** (always):

| Link                | Target             |
|---------------------|--------------------|
| `~/.gitconfig`      | `gitconfig`        |
| `~/.config/nvim`    | `nvim/`            |
| `~/.zshrc`          | `zsh/.zshrc`       |
| `~/.zsh_plugins.txt`| `zsh/.zsh_plugins.txt` |
| `~/.mc`             | `mc/`              |

**`links/desktop.conf.yaml`** (desktop/wsl only):

| Link                | Target             |
|---------------------|--------------------|
| `~/.config/ghostty` | `ghostty/`         |
| `~/.Xresources`     | `Xresources`       |
| `~/.fonts`          | `fonts/`           |

## Managed configurations

- **zsh** — antidote plugin manager, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, starship prompt
- **Neovim** — Packer plugins, Treesitter, LSP (clangd), Telescope, nvim-tree, gitsigns, Solarized theme
- **Git** — delta pager, zdiff3 merge style
- **Ghostty** — Fira Code Nerd Font, Solarized Dark theme
- **Hyprland** — shared base config + per-host overrides, greetd with gtkgreet (launched via Hyprland compositor)
- **Midnight Commander** — Solarized theme
- **Fonts** — Fira Code Nerd Font (multiple weights)

## Git submodules

- `dotbot/` — [Dotbot](https://github.com/anishathalye/dotbot) symlink manager
- `zsh/antidote/` — [Antidote](https://github.com/mattmc3/antidote) zsh plugin manager

## Running specific roles

Use Ansible tags to run only specific parts:

```bash
ansible-playbook site.yml --tags shell
ansible-playbook site.yml --tags "neovim,links"
```
