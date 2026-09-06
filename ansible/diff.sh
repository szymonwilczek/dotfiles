#!/usr/bin/env python3
"""
diff.sh / Drift Detector - Spots differences between system state and Git state
Usage:
  ./diff.sh          # Checks and displays differences (audit)
  ./diff.sh --sync   # Appends freshly installed packages to Git (to dnf_inbox.yml)
"""

import sys
import os
import subprocess
import yaml

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
VARS_DIR = os.path.join(SCRIPT_DIR, "vars")

GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
BOLD = "\033[1m"
RESET = "\033[0m"


def load_ignore():
    path = os.path.join(VARS_DIR, "ignore.yml")
    if not os.path.exists(path):
        return set(), set(), set()
    with open(path, "r") as f:
        data = yaml.safe_load(f) or {}
    ign_dnf = set(str(p).strip() for p in data.get("ignored_dnf_packages", []) if p)
    ign_flatpaks = set(str(p).strip() for p in data.get("ignored_flatpaks", []) if p)
    ign_coprs = set(str(p).strip() for p in data.get("ignored_coprs", []) if p)
    return ign_dnf, ign_flatpaks, ign_coprs


def load_yaml(filename):
    path = os.path.join(VARS_DIR, filename)
    if not os.path.exists(path):
        return []
    with open(path, "r") as f:
        data = yaml.safe_load(f) or {}
    if not data:
        return []
    key = list(data.keys())[0]
    return [
        str(p).strip() for p in data.get(key, []) if p and not str(p).startswith("#")
    ]


def write_yaml_list(filename, key, items):
    path = os.path.join(VARS_DIR, filename)
    with open(path, "w") as f:
        f.write(f"---\n{key}:\n")
        for item in sorted(items):
            f.write(f"  - {item}\n")


def get_installed_user_dnf():
    cmd = "dnf5 repoquery --installed --qf '%{name} %{reason}\n' 2>/dev/null | grep -E ' (User|External User)$' | awk '{print $1}'"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return set(line.strip() for line in res.stdout.splitlines() if line.strip())


def get_installed_flatpaks():
    cmd = "flatpak list --app --columns=application 2>/dev/null"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    lines = [line.strip() for line in res.stdout.splitlines() if line.strip()]
    if lines and "Identyfikator" in lines[0] or (lines and "Application" in lines[0]):
        lines = lines[1:]
    return set(lines)


def get_enabled_coprs():
    cmd = "dnf copr list 2>/dev/null"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    repos = set()
    for line in res.stdout.splitlines():
        line = line.strip()
        if not line or "(disabled)" in line:
            continue
        parts = line.split("/")
        if len(parts) >= 3:
            repo_name = f"{parts[-2]}/{parts[-1]}"
            repos.add(repo_name)
    return repos


def main():
    sync_mode = "--sync" in sys.argv or "-s" in sys.argv

    print(f"\n{BOLD}{BLUE}--- PACKAGES SYNC AUDIT ---{RESET}")
    print("Scanning...")

    dnf_files = [
        "dnf_common.yml",
        "dnf_dev.yml",
        "dnf_apps.yml",
        "dnf_sway.yml",
        "dnf_mail.yml",
        "dnf_docker.yml",
        "dnf_latex.yml",
        "dnf_system_hw.yml",
        "dnf_libs.yml",
        "dnf_kde.yml",
        "dnf_inbox.yml",
    ]
    declared_dnf = set()
    for f in dnf_files:
        declared_dnf.update(load_yaml(f))

    ign_dnf, ign_flatpaks, ign_coprs = load_ignore()

    installed_dnf = get_installed_user_dnf()
    new_dnf = (installed_dnf - declared_dnf) - ign_dnf
    removed_dnf = declared_dnf - installed_dnf

    declared_flatpaks = set(load_yaml("flatpaks.yml"))
    installed_flatpaks = get_installed_flatpaks()
    new_flatpaks = (installed_flatpaks - declared_flatpaks) - ign_flatpaks
    removed_flatpaks = declared_flatpaks - installed_flatpaks

    declared_coprs = set(load_yaml("copr.yml"))
    enabled_coprs = get_enabled_coprs()
    new_coprs = (enabled_coprs - declared_coprs) - ign_coprs
    removed_coprs = declared_coprs - enabled_coprs

    drift_found = False

    if new_dnf:
        drift_found = True
        print(
            f"\n{BOLD}{YELLOW}[+] New packages in OS (lack in Git):{RESET} ({len(new_dnf)})"
        )
        for p in sorted(new_dnf):
            print(f"    {GREEN}+ {p}{RESET}")

    if removed_dnf:
        drift_found = True
        print(
            f"\n{BOLD}{RED}[-] DNF packages in Git, but uninstalled from OS:{RESET} ({len(removed_dnf)})"
        )
        for p in sorted(removed_dnf):
            print(f"    {RED}- {p}{RESET}")

    # Prezentacja Flatpak
    if new_flatpaks:
        drift_found = True
        print(
            f"\n{BOLD}{YELLOW}[+] New Flatpacks in OS (lack in Git):{RESET} ({len(new_flatpaks)})"
        )
        for p in sorted(new_flatpaks):
            print(f"    {GREEN}+ {p}{RESET}")

    if removed_flatpaks:
        drift_found = True
        print(
            f"\n{BOLD}{RED}[-] Flatpacks in Git, but uninstalled from OS:{RESET} ({len(removed_flatpaks)})"
        )
        for p in sorted(removed_flatpaks):
            print(f"    {RED}- {p}{RESET}")

    # Prezentacja COPR
    if new_coprs:
        drift_found = True
        print(
            f"\n{BOLD}{YELLOW}[+] New COPR repos in OS (lack in Git):{RESET} ({len(new_coprs)})"
        )
        for p in sorted(new_coprs):
            print(f"    {GREEN}+ {p}{RESET}")

    if not drift_found:
        print(f"\n{BOLD}{GREEN} NICE! OS and Git are 100% synced!{RESET}")
        print("Desync not found.\n")
        return

    if sync_mode:
        print(f"\n{BOLD}{BLUE}==> Automatic sync changes to Git...{RESET}")
        if new_dnf:
            existing_inbox = set(load_yaml("dnf_inbox.yml"))
            existing_inbox.update(new_dnf)
            write_yaml_list("dnf_inbox.yml", "dnf_inbox_packages", existing_inbox)
            print(f"  -> Appended {len(new_dnf)} new packages to vars/dnf_inbox.yml")

        if new_flatpaks:
            all_flatpaks = declared_flatpaks.union(new_flatpaks)
            write_yaml_list("flatpaks.yml", "flatpak_applications", all_flatpaks)
            print(f"  -> Updated vars/flatpaks.yml ({len(new_flatpaks)} new Flatpaks)")

        if new_coprs:
            all_coprs = declared_coprs.union(new_coprs)
            write_yaml_list("copr.yml", "copr_repositories", all_coprs)
            print(f"  -> Updated vars/copr.yml ({len(new_coprs)} new COPR repos)")

        print(f"\n{BOLD}{GREEN}Sync completed!{RESET}")
    else:
        print(f"\n{BOLD}{BLUE}Hint:{RESET}")
        print(
            "To automatically save this newly made changes (to vars/dnf_inbox.yml), type:"
        )
        print(f"  {BOLD}./diff.sh --sync{RESET}\n")


if __name__ == "__main__":
    main()
