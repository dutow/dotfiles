#!/usr/bin/env bash
set -e

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_runtime() {
    if [ -n "$CONTAINER_RUNTIME" ]; then
        echo "$CONTAINER_RUNTIME"
        return
    fi
    if command -v podman &>/dev/null; then
        echo "podman"
    elif command -v docker &>/dev/null; then
        echo "docker"
    else
        echo "ERROR: Neither podman nor docker found" >&2
        exit 1
    fi
}

declare -A DISTRO_IMAGES=(
    [ubuntu-24.04]="ubuntu:24.04"
    [ubuntu-22.04]="ubuntu:22.04"
    [tumbleweed]="opensuse/tumbleweed"
    [oracle-9]="oraclelinux:9"
    [oracle-8]="oraclelinux:8"
)

declare -A DISTRO_BOOTSTRAP=(
    [ubuntu-24.04]="apt-get update && apt-get install -y python3 python3-pip ansible git sudo hostname"
    [ubuntu-22.04]="apt-get update && apt-get install -y python3 python3-pip ansible git sudo hostname"
    [tumbleweed]="zypper --non-interactive dup && zypper install -y python3 ansible git-core sudo hostname"
    [oracle-9]="dnf install -y python3 python3-pip ansible-core git sudo hostname"
    [oracle-8]="dnf install -y python3 python3-pip ansible-core git sudo hostname"
)

ALL_SETS="cpp-dev,ruby-dev,node-dev,python-dev,ai-tools"
DEFAULT_DISTRO="tumbleweed"
IMAGE_PREFIX="localhost/dotfiles"

cmd_build() {
    local distro="$DEFAULT_DISTRO"
    local sets="$ALL_SETS"
    local tag=""
    local runtime=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --distro)  distro="$2"; shift 2 ;;
            --sets)    sets="$2"; shift 2 ;;
            --tag)     tag="$2"; shift 2 ;;
            --runtime) runtime="$2"; shift 2 ;;
            *) echo "Unknown build option: $1" >&2; exit 1 ;;
        esac
    done

    if [ -z "${DISTRO_IMAGES[$distro]+x}" ]; then
        echo "ERROR: Unknown distro '$distro'. Available: ${!DISTRO_IMAGES[*]}" >&2
        exit 1
    fi

    [ -n "$runtime" ] && CONTAINER_RUNTIME="$runtime"
    local rt
    rt=$(detect_runtime)
    tag="${tag:-$distro}"
    local image_name="${IMAGE_PREFIX}-${tag}"
    local base_image="${DISTRO_IMAGES[$distro]}"
    local bootstrap="${DISTRO_BOOTSTRAP[$distro]}"
    local build_container="dotfiles-build-$$"

    local host_user
    host_user=$(id -un)
    local host_uid
    host_uid=$(id -u)
    local host_gid
    host_gid=$(id -g)

    cleanup() {
        "$rt" rm -f "$build_container" &>/dev/null || true
    }
    trap cleanup EXIT

    echo "Building image: $image_name"
    echo "  Distro:  $distro ($base_image)"
    echo "  Sets:    $sets"
    echo "  Runtime: $rt"
    echo "  User:    $host_user ($host_uid:$host_gid)"
    echo

    echo "==> Creating build container..."
    "$rt" run -d --name "$build_container" "$base_image" sleep infinity

    echo "==> Bootstrapping packages..."
    "$rt" exec "$build_container" bash -c "$bootstrap"

    echo "==> Creating user $host_user..."
    "$rt" exec "$build_container" bash -c "
        groupadd -g $host_gid $host_user 2>/dev/null || true
        useradd -m -u $host_uid -g $host_gid -s /bin/bash $host_user 2>/dev/null || true
        echo '$host_user ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$host_user
        chmod 0440 /etc/sudoers.d/$host_user
    "

    echo "==> Copying dotfiles repo..."
    "$rt" cp "$BASEDIR/." "$build_container:/home/$host_user/.dotfiles"
    "$rt" exec "$build_container" chown -R "$host_uid:$host_gid" "/home/$host_user/.dotfiles"

    "$rt" exec --user "$host_uid" "$build_container" \
        git config --global --add safe.directory "/home/$host_user/.dotfiles"

    echo "==> Running install.sh --container --env console --sets $sets ..."
    "$rt" exec --user "$host_uid" --workdir "/home/$host_user/.dotfiles" "$build_container" \
        ./install.sh --container --env console --sets "$sets"

    echo "==> Committing image..."
    "$rt" commit \
        --change "USER $host_user" \
        --change "WORKDIR /home/$host_user" \
        --change "ENV CLAUDE_CONFIG_DIR=/home/$host_user/.claude" \
        --change 'CMD ["/bin/zsh"]' \
        "$build_container" "$image_name"

    echo
    echo "Image built: $image_name"
    echo "Run with: $0 run --tag $tag"
}

cmd_run() {
    local tag="$DEFAULT_DISTRO"
    local mounts=()
    local context="default"
    local shell="/bin/zsh"
    local runtime=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tag)     tag="$2"; shift 2 ;;
            --mount)   mounts+=("$2"); shift 2 ;;
            --context) context="$2"; shift 2 ;;
            --shell)   shell="$2"; shift 2 ;;
            --runtime) runtime="$2"; shift 2 ;;
            *) echo "Unknown run option: $1" >&2; exit 1 ;;
        esac
    done

    [ -n "$runtime" ] && CONTAINER_RUNTIME="$runtime"
    local rt
    rt=$(detect_runtime)
    local image_name="${IMAGE_PREFIX}-${tag}"

    local aicont_dir="${DOTFILES_AICONT_DIR:-$HOME/.aicont}"
    local ctx_dir="$aicont_dir/$context"
    mkdir -p "$ctx_dir/claude" "$ctx_dir/codex"

    local host_user
    host_user=$(id -un)

    local run_args=(run --rm -it)

    if [ "$rt" = "podman" ]; then
        run_args+=(--userns=keep-id)
    else
        run_args+=(--user "$(id -u):$(id -g)")
    fi

    run_args+=(-v "$ctx_dir/claude:/home/$host_user/.claude")
    run_args+=(-v "$ctx_dir/codex:/home/$host_user/.codex")

    for mount in "${mounts[@]}"; do
        if [[ "$mount" == *:* ]]; then
            run_args+=(-v "$mount")
        else
            run_args+=(-v "$mount:$mount")
        fi
    done

    run_args+=("$image_name" "$shell")

    echo "Running: $rt ${run_args[*]}"
    "$rt" "${run_args[@]}"
}

cmd_list() {
    local runtime=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --runtime) runtime="$2"; shift 2 ;;
            *) echo "Unknown list option: $1" >&2; exit 1 ;;
        esac
    done

    [ -n "$runtime" ] && CONTAINER_RUNTIME="$runtime"
    local rt
    rt=$(detect_runtime)

    echo "Dotfiles container images:"
    echo
    "$rt" images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | \
        grep -E "(REPOSITORY|${IMAGE_PREFIX})" || echo "  (none found)"
}

cmd_clean() {
    local runtime=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --runtime) runtime="$2"; shift 2 ;;
            *) echo "Unknown clean option: $1" >&2; exit 1 ;;
        esac
    done

    [ -n "$runtime" ] && CONTAINER_RUNTIME="$runtime"
    local rt
    rt=$(detect_runtime)

    local images
    images=$("$rt" images --format "{{.Repository}}:{{.Tag}}" | grep "^${IMAGE_PREFIX}" || true)

    if [ -z "$images" ]; then
        echo "No dotfiles images found."
        return
    fi

    echo "The following images will be removed:"
    echo "$images" | sed 's/^/  /'
    echo

    read -r -p "Continue? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$images" | xargs "$rt" rmi
        echo "Done."
    else
        echo "Cancelled."
    fi
}

usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
  build   Build a container image
  run     Run a container from a built image
  list    List dotfiles container images
  clean   Remove dotfiles container images

Build options:
  --distro <key>           Base distro (default: $DEFAULT_DISTRO)
                           Available: ${!DISTRO_IMAGES[*]}
  --sets <sets>            Comma-separated package sets (default: $ALL_SETS)
  --tag <name>             Image tag (default: derived from distro)
  --runtime <podman|docker> Override runtime detection

Run options:
  --tag <tag>              Image tag to run (default: $DEFAULT_DISTRO)
  --mount <path>           Volume mount (repeatable). host:container or just path
  --context <name>         AI config context name (default: default)
  --shell <shell>          Override shell (default: /bin/zsh)
  --runtime <podman|docker> Override runtime detection

Examples:
  $0 build
  $0 build --distro tumbleweed --sets cpp-dev,ai-tools
  $0 run --mount /tmp/project
  $0 run --tag tumbleweed --context my-project --mount /home/user/work:/work
  $0 list
  $0 clean
EOF
}

# --- Main ---

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

command="$1"
shift

case "$command" in
    build) cmd_build "$@" ;;
    run)   cmd_run "$@" ;;
    list)  cmd_list "$@" ;;
    clean) cmd_clean "$@" ;;
    -h|--help|help) usage ;;
    *) echo "Unknown command: $command" >&2; usage; exit 1 ;;
esac
