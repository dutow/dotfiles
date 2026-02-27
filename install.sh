#!/usr/bin/env bash
set -e

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BASEDIR}"

EXTRA_VARS=()
ANSIBLE_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            EXTRA_VARS+=("dotfiles_env=$2")
            shift 2
            ;;
        --sets)
            # Convert comma-separated list to JSON array
            IFS=',' read -ra SETS <<< "$2"
            JSON_SETS=$(printf '"%s",' "${SETS[@]}")
            JSON_SETS="[${JSON_SETS%,}]"
            EXTRA_VARS+=("dotfiles_sets=${JSON_SETS}")
            shift 2
            ;;
        --tags)
            ANSIBLE_ARGS+=("--tags" "$2")
            shift 2
            ;;
        *)
            ANSIBLE_ARGS+=("$1")
            shift
            ;;
    esac
done

for var in "${EXTRA_VARS[@]}"; do
    ANSIBLE_ARGS+=("--extra-vars" "$var")
done

install_ansible() {
    if command -v ansible-playbook &>/dev/null; then
        echo "Ansible is already installed."
        return
    fi

    echo "Installing Ansible..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
    else
        echo "ERROR: Cannot detect OS (no /etc/os-release)"
        exit 1
    fi

    case "$ID" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip ansible
            ;;
        opensuse-tumbleweed|opensuse*)
            sudo zypper install -y python3 ansible
            ;;
        ol|oracle*)
            sudo dnf install -y python3 python3-pip ansible-core
            ;;
        *)
            echo "ERROR: Unsupported OS: $ID"
            exit 1
            ;;
    esac
}

install_ansible

git submodule update --init --recursive

# Target the current hostname if it has a host_vars file, otherwise fall back to localhost
HOSTNAME=$(hostname -s)
if [ -f "${BASEDIR}/inventory/host_vars/${HOSTNAME}.yml" ]; then
    ANSIBLE_ARGS+=("--limit" "${HOSTNAME}")
else
    ANSIBLE_ARGS+=("--limit" "localhost")
fi

ansible-playbook "${BASEDIR}/site.yml" "${ANSIBLE_ARGS[@]}"
