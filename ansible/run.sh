#!/usr/bin/env bash
# run.sh - Easy package management in Ansible
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v ansible-playbook &>/dev/null; then
    echo "==> Ansible could not been found. Installing..."
    sudo dnf install -y ansible-core
    ansible-galaxy collection install community.general
fi

EXTRA_ARGS=()

for arg in "$@"; do
    case "$arg" in
    --sway)
        EXTRA_ARGS+=("-e" "enable_sway=true")
        ;;
    --dry-run | --check)
        EXTRA_ARGS+=("--check" "--diff")
        ;;
    *)
        EXTRA_ARGS+=("$arg")
        ;;
    esac
done

echo "==> Running Ansible's playbook..."
echo "    Directory: $SCRIPT_DIR"
echo "    Args: ${EXTRA_ARGS[*]:-brak}"

ansible-playbook playbook.yml --ask-become-pass "${EXTRA_ARGS[@]}"
