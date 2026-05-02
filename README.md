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
| `ruby-dev`   | Ruby via mise, build dependencies                        |
| `node-dev`   | Node.js (LTS) via mise                                   |
| `python-dev` | Python via mise, python3-dev headers                     |
| `selenium`   | Firefox for headless browser automation                       |
| `android-dev`| JDK 21, Android SDK/NDK bootstrap helper, kotlin-language-server |
| `ai-tools`   | Claude Code, OpenAI Codex (requires node-dev for Codex)  |
| `kubernetes` | Docker, minikube, kubectl, helm, k3d                      |

## Ansible roles

Roles are applied in order from `site.yml`. The `detect` role always runs first.

| Role            | Tags           | Condition                        | Purpose                                          |
|-----------------|----------------|----------------------------------|--------------------------------------------------|
| `detect`        | always         | —                                | Auto-detect distro, environment, and sets         |
| `base`          | base           | —                                | Core packages (curl, git, wget, ssh, jq)          |
| `shell`         | shell          | —                                | zsh + starship prompt                             |
| `neovim`        | neovim         | —                                | Neovim (unstable PPA on Ubuntu)                   |
| `git-tools`     | git-tools      | —                                | git, tig, delta, gh                               |
| `console-tools` | console-tools  | —                                | mc, ripgrep, fd, tmux, glances, go-task            |
| `cpp-dev`       | cpp-dev        | `'cpp-dev' in dotfiles_sets`     | C/C++ toolchain                                   |
| `mise`          | mise           | any language dev set active       | mise universal version manager                    |
| `ruby-dev`      | ruby-dev       | `'ruby-dev' in dotfiles_sets`    | Ruby via mise + build dependencies                |
| `node-dev`      | node-dev       | `'node-dev' in dotfiles_sets`    | Node.js (LTS) via mise                            |
| `python-dev`    | python-dev     | `'python-dev' in dotfiles_sets`  | Python via mise + dev headers                     |
| `selenium`       | selenium       | `'selenium' in dotfiles_sets`    | Firefox for headless browser automation              |
| `android-dev`   | android-dev    | `'android-dev' in dotfiles_sets` | JDK + Android SDK/NDK bootstrap (lives in aicontext persist) |
| `ai-tools`      | ai-tools       | `'ai-tools' in dotfiles_sets`    | AI development tools (Claude Code, Codex)           |
| `kubernetes`    | kubernetes     | `'kubernetes' in dotfiles_sets`  | Docker, minikube, kubectl, helm, k3d                 |
| `desktop`       | desktop        | env is `desktop` or `wsl`        | Ghostty, Mesa, Wayland libs, NVIDIA drivers (opt.) |
| `hyprland`      | hyprland       | env is `desktop`                 | Hyprland WM + uwsm, greetd, waybar, wofi, etc.    |
| `desktop-apps`  | desktop-apps   | env is `desktop`                 | Desktop apps (zypper + Flatpak)                    |
| `wsl`           | wsl            | env is `wsl`                     | WSL-specific config (placeholder)                  |
| `links`         | links          | —                                | Dotbot symlinks (always last)                      |

### Desktop apps (Tumbleweed)

Native packages (zypper): Firefox, Thunderbird, KeePassXC, VS Code, podman, scrcpy, android-tools, qemu-kvm

Flatpak (via Flathub): Slack, Discord, Dropbox, Android Studio

The desktop role also adds the local user to the `kvm` group so the Android
emulator (and other KVM workloads) can use `/dev/kvm`. Re-login required
after first install.

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

- **zsh** — antidote plugin manager, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, starship prompt, mise activation
- **mise** — universal version manager for Ruby, Node.js, Python (replaces rvm, system nodejs/npm, pip)
- **Neovim** — Packer plugins, Treesitter, LSP (clangd), Telescope, nvim-tree, gitsigns, Solarized theme
- **Git** — delta pager, zdiff3 merge style
- **Ghostty** — Fira Code Nerd Font, Solarized Dark theme
- **Hyprland** — shared base config + per-host overrides, greetd with gtkgreet (launched via Hyprland compositor)
- **Midnight Commander** — Solarized theme
- **Fonts** — Fira Code Nerd Font (multiple weights)

## Container images

The `dcont` command builds container images provisioned with dotfiles — useful for AI agent environments or reproducible dev setups. It supports podman (preferred) and docker. It is symlinked to `~/.local/bin/dcont` so it's available from anywhere.

### Supported distros

`ubuntu-24.04` (default), `ubuntu-22.04`, `tumbleweed`, `oracle-9`, `oracle-8`

### Setup

Container builds require a sudo password for the in-container user. Generate `.container_sudo_password` (gitignored) containing a SHA-512 hash:

```bash
openssl passwd -6 'your-password' > .container_sudo_password
```

You'll be prompted for the plaintext password at build time (verified against the hash).

### Usage

```bash
# Build with defaults (ubuntu-24.04, all sets)
dcont build

# Build a specific distro with specific sets
dcont build --distro tumbleweed --sets cpp-dev,ai-tools

# Run (ephemeral container with zsh)
dcont run --mount /path/to/project

# Run with a named AI config context (persistent OAuth sessions)
dcont run --context my-project --mount /home/user/work:/work

# List / clean images
dcont list
dcont clean
```

Zsh tab completion is provided for all subcommands and their flags.

#### Project pinning via env vars

`dcont run` reads its defaults from environment variables, so per-project settings can live in a `.env` file that zsh autoloads when you `cd` into the project:

| Variable        | Equivalent flag | Notes                                                                 |
| --------------- | --------------- | --------------------------------------------------------------------- |
| `DCONT_TAG`     | `--tag`         |                                                                       |
| `DCONT_CONTEXT` | `--context`     |                                                                       |
| `DCONT_SHELL`   | `--shell`       |                                                                       |
| `DCONT_RUNTIME` | `--runtime`     |                                                                       |
| `DCONT_GPU`     | `--gpu`         | Truthy: `1`, `true`, `yes`, `on`                                      |
| `DCONT_MOUNT`   | `--mount`       | Single string, or newline-separated for multiple. Additive with CLI.  |
| `DCONT_NETWORK` | `--network`     | Same format and semantics as `DCONT_MOUNT`.                           |

CLI flags override scalar env vars; for `--mount` / `--network`, command-line values are appended to whatever the env vars provide.

For multiple mounts/networks, the cleanest zsh idiom is a tied array:

```zsh
typeset -T DCONT_MOUNT dcont_mount $'\n'
dcont_mount=("$PWD" /data:/data)
export DCONT_MOUNT DCONT_CONTEXT=my-project DCONT_NETWORK=myproject_default
```

A single mount is just `export DCONT_MOUNT=$PWD`.

AI tool configs (Claude, Codex) are persisted per-context under `$DOTFILES_AICONT_DIR` (defaults to `~/.aicont`). Each context directory is mounted in full at `~/.aicontext` inside the container; `~/.claude` and `~/.codex` are symlinks into that mount, so other LLM-related shared state (e.g. plugin repos) can live alongside them.

#### Per-context init script

For tools that don't fit the file-only model (shell installers, global npm
packages, etc.), each context can ship an `init.sh` that runs once at
container start, before the shell. Layout:

```
~/.aicont/<ctx>/
├── claude/        Claude config (mounted at ~/.claude)
├── codex/         Codex config (mounted at ~/.codex)
├── init.sh        Optional, executable — your install recipe
└── persist/       Tool-managed install state (auto-created)
```

The entrypoint exports these before running `init.sh`, so installers land in
`persist/` instead of clobbering the image's `~/.local` and `~/.config`:

| Variable             | Value                                    |
| -------------------- | ---------------------------------------- |
| `AICONT_PERSIST`     | `~/.aicontext/persist`                   |
| `PATH`               | prepended with `$AICONT_PERSIST/{bin,npm/bin,python/bin}` |
| `NPM_CONFIG_PREFIX`  | `$AICONT_PERSIST/npm`                    |
| `PYTHONUSERBASE`     | `$AICONT_PERSIST/python`                 |

Output is teed to `~/.aicontext/init.log`. A failing `init.sh` doesn't abort
container start — the error is logged and you drop into the shell. Wipe and
reinstall with `rm -rf ~/.aicont/<ctx>/persist` (the recipe in `init.sh`
remains).

Example `~/.aicont/explore/init.sh`:

```bash
#!/usr/bin/env bash
set -e
command -v cavemem >/dev/null || { npm install -g cavemem && cavemem install; }
command -v caveman >/dev/null || \
    curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

#### Android SDK/NDK in containers

Images built with the `android-dev` set ship a JDK plus the
`dotfiles-android-init` helper. The helper downloads `commandlinetools` and
runs `sdkmanager` to install platform-tools, `platforms;android-35`,
`build-tools;35.0.0`, and `ndk;27.2.12479018` — all under
`~/.aicontext/persist/android/` so the SDK is per-context and persists
across container rebuilds (and never touches the host).

Bootstrap once per context, either by running `dotfiles-android-init`
manually after first `dcont run`, or by adding it to that context's
`init.sh`:

```bash
#!/usr/bin/env bash
set -e
command -v sdkmanager >/dev/null && [ -d "$ANDROID_HOME/platform-tools" ] \
    || dotfiles-android-init
```

Re-running is a fast no-op once the SDK is populated. The `ANDROID_HOME`,
`ANDROID_SDK_ROOT`, `ANDROID_USER_HOME`, `GRADLE_USER_HOME`, and `JAVA_HOME`
env vars are set automatically inside containers by the shell init.

Under `--audit=strict|soft`, the role imports the staged mitmproxy CA into
the JDK's truststore at image-build time so `sdkmanager` can validate
HTTPS through the proxy.

A `Taskfile.yml` is also provided for [go-task](https://taskfile.dev/) users:

```bash
task container:build                                       # default distro, all sets
task container:build DISTRO=tumbleweed SETS=cpp-dev,ai-tools
task container:build:all                                   # build all distros
task container:run MOUNT=/path/to/project CONTEXT=my-proj
task container:list
task container:clean
```

## Container egress audit

Every `dcont run` defaults to **strict audit mode**: agent HTTPS traffic is
routed through a per-invocation `mitmproxy` on the host, and an in-container
`nft` firewall blocks everything except the proxy port and joined container
networks.

Logs are written to `~/.aicont-logs/<context>/<run-timestamp>/`:
- `flows.mitm` — full request/response (binary, replay with `mitmweb -r`)
- `summary.jsonl` — one line per request
- `secrets.jsonl` — flagged credential leaks (preview-masked)
- `blocked.jsonl` — domains blocked by the malicious-URL list

Modes (`--audit=` flag or `DCONT_AUDIT=` env var):
- `strict` (default) — proxy + firewall
- `soft` — proxy only, no firewall (tools that ignore HTTPS_PROXY bypass)
- `off` — no audit, no firewall (legacy behavior)

Compose-network peer traffic (any port, any protocol) bypasses the proxy
when joined via `--network`.

JVM tools (`sdkmanager`, `gradle`, `mvn`, `kotlinc`, …) ignore
`HTTPS_PROXY`, so the entrypoint also exports `JAVA_TOOL_OPTIONS` with
the matching `-Dhttps.proxyHost`/`Port` flags whenever `HTTPS_PROXY` is
set — every JVM launched in the container picks this up automatically.

The optional malicious-URL blocklist is loaded from
`~/.config/dcont/blocklist.txt` if present (hosts file format).

### CA cert

`mitmproxy`'s CA is baked into the image at build time. If you rotate the CA
(`rm -rf ~/.mitmproxy && mitmdump --version`), rebuild images with `dcont build`.

## Git submodules

- `dotbot/` — [Dotbot](https://github.com/anishathalye/dotbot) symlink manager
- `zsh/antidote/` — [Antidote](https://github.com/mattmc3/antidote) zsh plugin manager

## Running specific roles

Use Ansible tags to run only specific parts:

```bash
ansible-playbook site.yml --tags shell
ansible-playbook site.yml --tags "neovim,links"
```
