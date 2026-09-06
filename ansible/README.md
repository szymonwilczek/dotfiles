# Declarative Fedora Workstation with Ansible

Declarative, reproducible, and idempotent system provisioning for **Fedora Linux**, inspired by the NixOS philosophy of tracking system packages in Git without the overhead of immutability.

This setup allows completely bootstrapping a Fedora installation (CLI tools, desktop applications, development runtimes, COPR repos, and Flatpaks) with a single command, while maintaining 100% idempotency.

---

### Bootstrap Fresh System

Clone the dotfiles repository and run the setup script:

```bash
cd ansible
./run.sh
```

_The script checks if `ansible-core` is present (installs it if missing) and runs the playbook locally._

### Test Without Making Changes

To simulate what Ansible would do without touching or installing anything:

```bash
./run.sh --dry-run
```

_(Uses Ansible's native `--check --diff` mode)._

---

## Drift Detection (`diff.sh`)

One of the biggest pain in the ass of declarative setups on standard distributions is **configuration drift** - installing packages with `sudo dnf install` causes Git to get out of sync.

To solve this, `diff.sh` provides instant drift detection and 1-click synchronization:

### Audit Differences

```bash
./diff.sh
```

In 2 seconds, it inspects your DNF, Flatpak, and COPR state and shows:

- 🟢 **New packages installed in the OS** (missing from Git)
- 🔴 **Packages removed from the OS** (still declared in Git)

### 1-Click Auto-Sync

```bash
./diff.sh --sync
```

- Captures newly installed DNF packages and writes them to [`vars/dnf_inbox.yml`](vars/dnf_inbox.yml).
- Appends new Flatpaks to [`vars/flatpaks.yml`](vars/flatpaks.yml).
- Appends new COPR repos to [`vars/copr.yml`](vars/copr.yml).

## Customization and Profiles

### Selective Execution via Tags

You can target or skip specific parts of the system at any time:

```bash
# Only update CLI and dev tools
ansible-playbook playbook.yml --tags "common,dev"

# Only install Flatpaks
ansible-playbook playbook.yml --tags "flatpak"

# Everything except GUI desktop applications
ansible-playbook playbook.yml --skip-tags "apps"
```

Available tags: `repos`, `copr`, `common`, `dev`, `apps`, `sway`, `mail`, `docker`, `latex`, `system_hw`, `libs`, `kde`, `inbox`, `exclude`, `flatpak`.
