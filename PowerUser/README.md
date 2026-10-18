# Phase 1 - PowerUser: Linux and Windows Command-Line Fundamentals

## What I Built

A hardened Ubuntu 24.04 VPS on Oracle Cloud (key-only SSH, no root login) used for all Linux practice, plus a local Windows 10 machine and Hyper-V VMs (Windows 10 and Windows Server 2025 on an internal virtual switch) used for PowerShell practice. Everything was done from the terminal, with the goal of understanding what the OS is doing rather than memorising commands.

## Key Accomplishments

**Linux (Oracle Cloud VPS)**
- [x] Hardened SSH from day one: key authentication only, password auth and root login disabled, max 3 attempts, X11 forwarding off (`/etc/ssh/sshd_config`)
- [x] Created three account types (regular user, sudoer, `nologin` service account) and triggered `Permission denied` on purpose to watch the permission model work (`useradd`, `usermod -aG`, `chmod 600`, `chmod 770`)
- [x] Ran a system-wide SetUID audit to separate expected binaries from potential privilege escalation vectors (`find / -perm -4000 -type f`)
- [x] Built a custom systemd service that logs uptime and load average every 60 seconds (`labhealth.service`, `journalctl -u labhealth`)
- [x] Created, formatted, mounted and unmounted a 100MB ext4 filesystem on a loop device (`dd`, `mkfs.ext4`, `mount -o loop`)
- [x] Added a 1GB persistent swapfile (`fallocate`, `mkswap`, `swapon`, `/etc/fstab`)
- [x] Wrote a dated tar backup script for the repo (`tar -czf`)
- [x] Pulled the attacking IPs out of real SSH bruteforce traffic on an unadvertised server (`journalctl -p err | grep -i maximum | awk ... | sort | uniq`)

**Windows (PowerShell 7 and Hyper-V)**
- [x] Installed PowerShell 7 via winget instead of using the built-in 5.1 (`winget install Microsoft.Powershell`)
- [x] Managed local users and groups entirely from PowerShell (`New-LocalUser`, `New-LocalGroup`, `Add-LocalGroupMember`, `Disable-LocalUser`)
- [x] Managed software with winget and NTFS permissions with icacls, including inheritance flags and an explicit deny (`icacls /grant "LabTeam:(OI)(CI)(M)"`, `icacls /deny`)
- [x] Queried and exported Security event logs for failed logons (`Get-WinEvent -FilterHashtable @{logname='Security'; id=4625} | Export-CSV`)
- [x] Hardened the local password and lockout policy: minimum length 0 to 12, lockout threshold 10 to 5 (`net accounts /minpwlen:12 /lockoutthreshold:5`)
- [x] Verified system file integrity and practiced taking file ownership (`sfc /scannow`, `takeown /f`)
- [x] Built a Linux to Windows command reference table covering users, permissions, processes, services, logs and packages

## Technologies Used

| Tool | Purpose | Evidence |
|---|---|---|
| OpenSSH | Key-only remote access to the VPS | [linux/](linux/README.md) |
| useradd, chmod, chown, id, stat | User, group and permission management | [linux/users_and_perms/](linux/users_and_perms/README.md) |
| grep, awk, sed, find | Text processing and SetUID audit | [linux/text_processing_and_sys_tools/](linux/text_processing_and_sys_tools/README.md) |
| systemd, journalctl | Service management and log reading | [linux/services_and_logging/](linux/services_and_logging/README.md) |
| df, du, dd, mkfs.ext4, swapon | Disk inspection, loop filesystem, swap | [linux/storage/](linux/storage/README.md) |
| journalctl, awk, sort, uniq | Bruteforce attack audit | [linux/bruteforce_audit/](linux/bruteforce_audit/README.md) |
| PowerShell 7, winget | Windows CLI and package management | [windows/](windows/README.md) |
| Get-Process, Select-String, Get-CimInstance | Navigation, processes, system info | [windows/powershell_basics/](windows/powershell_basics/README.md) |
| New-LocalUser, Add-LocalGroupMember | Local account management | [windows/local_user_management/](windows/local_user_management/README.md) |
| icacls | NTFS permissions | [windows/package_management_and_permissions/](windows/package_management_and_permissions/README.md) |
| Get-WinEvent, Event Viewer | Security event log auditing | [windows/event_logs/](windows/event_logs/README.md) |
| net accounts, sfc, takeown | Password policy, integrity, ownership | [windows/policy_integrity_ownership/](windows/policy_integrity_ownership/README.md) |

## Key Learnings

The error is the lesson. Seeing `Permission denied` after setting up a restricted file meant the access control was working, and that was easier to understand by triggering it on purpose than by reading about it. The bruteforce audit made the same point from the other side: the VPS was not advertised anywhere and bots were already hitting SSH within days, so hardening is not optional on anything internet-facing.

Linux and Windows solve the same problems with different tools. PowerShell pipelines pass objects instead of text, so each cmdlet can select properties directly rather than parsing strings. NTFS also supports explicit deny entries that override allows, while Linux permissions are purely additive. The command reference table in the policy lab maps the two side by side.

## Files in This Directory

| Folder | Description |
|---|---|
| [linux/](linux/README.md) | Day 0 VPS setup, SSH hardening and repo initialisation |
| [linux/users_and_perms/](linux/users_and_perms/README.md) | Users, groups, permissions and SetUID audit |
| [linux/text_processing_and_sys_tools/](linux/text_processing_and_sys_tools/README.md) | Processes, grep/awk/sed, redirection, tar backup |
| [linux/services_and_logging/](linux/services_and_logging/README.md) | Custom systemd service and journalctl |
| [linux/storage/](linux/storage/README.md) | df/du, loop filesystem, swapfile |
| [linux/bruteforce_audit/](linux/bruteforce_audit/README.md) | Extracting attacker IPs from the journal |
| [windows/](windows/README.md) | PowerShell 7 setup |
| [windows/powershell_basics/](windows/powershell_basics/README.md) | Navigation, processes, Select-String, system info |
| [windows/local_user_management/](windows/local_user_management/README.md) | Local users and groups |
| [windows/package_management_and_permissions/](windows/package_management_and_permissions/README.md) | winget and icacls |
| [windows/event_logs/](windows/event_logs/README.md) | Event Viewer, Get-WinEvent, CSV export |
| [windows/policy_integrity_ownership/](windows/policy_integrity_ownership/README.md) | net accounts, sfc, takeown, Linux vs Windows table |
