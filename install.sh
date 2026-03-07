#!/usr/bin/env bash
set -e

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BASEDIR}"

EXTRA_VARS=()
ANSIBLE_ARGS=()
CONTAINER_MODE=false
DISABLE_YUBIKEY=false
YUBIKEY_USB_DEVICE=""

YUBICO_VENDOR_ID="1050"

find_yubikey_usb_device() {
    for devpath in /sys/bus/usb/devices/*/idVendor; do
        if [[ -f "$devpath" ]] && [[ "$(cat "$devpath")" == "$YUBICO_VENDOR_ID" ]]; then
            YUBIKEY_USB_DEVICE="$(basename "$(dirname "$devpath")")"
            return 0
        fi
    done
    return 1
}

disable_yubikey() {
    if ! find_yubikey_usb_device; then
        echo "WARNING: No YubiKey found, skipping disable"
        return
    fi
    echo "Disabling YubiKey (USB device: $YUBIKEY_USB_DEVICE)..."
    echo "$YUBIKEY_USB_DEVICE" | sudo tee /sys/bus/usb/drivers/usb/unbind > /dev/null
}

enable_yubikey() {
    if [[ -z "$YUBIKEY_USB_DEVICE" ]]; then
        return
    fi
    echo "Re-enabling YubiKey (USB device: $YUBIKEY_USB_DEVICE)..."
    echo "$YUBIKEY_USB_DEVICE" | sudo tee /sys/bus/usb/drivers/usb/bind > /dev/null
}

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
        --container)
            CONTAINER_MODE=true
            shift
            ;;
        --disable-yubikey)
            DISABLE_YUBIKEY=true
            shift
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
            sudo apt-get install -y python3 python3-pip ansible git
            ;;
        opensuse-tumbleweed|opensuse*)
            sudo zypper install -y python3 ansible git-core
            ;;
        ol|oracle*)
            sudo dnf install -y python3 python3-pip ansible-core git
            ;;
        *)
            echo "ERROR: Unsupported OS: $ID"
            exit 1
            ;;
    esac
}

install_ansible

if [ "$CONTAINER_MODE" = false ]; then
    git submodule update --init --recursive
fi

# Target the current hostname if it has a host_vars file, otherwise fall back to localhost
HOSTNAME=$(hostname -s)
if [ -f "${BASEDIR}/inventory/host_vars/${HOSTNAME}.yml" ]; then
    ANSIBLE_ARGS+=("--limit" "${HOSTNAME}")
else
    ANSIBLE_ARGS+=("--limit" "localhost")
fi

if [ "$(id -u)" -ne 0 ] && [ "$CONTAINER_MODE" = false ]; then
    ANSIBLE_ARGS+=("--ask-become-pass")
fi

if [ "$DISABLE_YUBIKEY" = true ]; then
    disable_yubikey
    trap enable_yubikey EXIT
fi

ansible-playbook "${BASEDIR}/site.yml" "${ANSIBLE_ARGS[@]}"
