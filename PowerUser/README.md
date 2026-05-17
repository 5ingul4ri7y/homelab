# PowerUser Phase

This phase covers command-line proficiency and system administration fundamentals across both Linux and Windows. The goal was not just to memorise commands but to understand what the OS is actually doing when you run them, and to build the habit of working entirely from the terminal rather than relying on GUI tools.

The phase is split into two sections. Linux was practiced on a live Oracle Cloud VPS over SSH. Windows was practiced on the local machine and a Windows 10 VM running inside Hyper-V.

---

## Linux

### [VPS Setup and SSH](linux/README.md)

Starting point for the whole lab. Set up an Oracle Cloud VPS, hardened SSH access by disabling password authentication and root login, changed the hostname, ran system updates, and initialised this GitHub repo. All subsequent Linux practice was done on this machine over SSH.

### [Users and Permissions](linux/users_and_perms/README.md)

Created three user types with different privilege levels: a regular user, a sudoer, and a service account with `nologin` shell. Set up group-based file access and intentionally triggered `Permission denied` errors to observe the permission model working as intended. Also ran a system-wide SetUID audit to identify binaries running with elevated privileges.

Key tools: `useradd`, `usermod`, `groupadd`, `chmod`, `chown`, `su`, `id`, `stat`, `find -perm /4000`

### [Text Processing and System Tools](linux/text_processing_and_sys_tools/README.md)

Covered the core CLI tools for working with text output and system processes. Practiced building pipelines that chain multiple commands together to filter, transform, and extract data. Also wrote a small dated backup script using tar.

Key tools: `ps`, `top`, `kill`, `pkill`, `nohup`, `grep`, `awk`, `sed`, `find`, `tar`, I/O redirection (`>`, `2>`, `<`)

### [Services and Logging](linux/services_and_logging/README.md)

Learned how systemd manages background services and built a custom one from scratch. The service runs a shell script that logs system health metrics every 60 seconds to a log file. Also covered journalctl for reading the systemd journal and filtering service-specific output.

Key tools: `systemctl`, `journalctl`, `tee`, heredoc syntax, systemd unit file structure

### [Storage](linux/storage/README.md)

Covered disk space inspection, filesystem creation from scratch using a loop device, and swapfile setup. The loop device exercise was particularly useful since it walks through the full lifecycle of a filesystem (create, format, mount, use, unmount) entirely in software.

Key tools: `df`, `du`, `dd`, `mkfs.ext4`, `mount`, `umount`, `fallocate`, `mkswap`, `swapon`, `/etc/fstab`

### [Bruteforce Attack Audit](linux/bruteforce_audit/README.md)

A consolidation exercise that applied journalctl, grep, and awk against real SSH attack traffic on the VPS. Sampled failed authentication attempts from the security journal and then extracted and deduplicated the attacking IPs using an awk loop. The server was not advertised anywhere and was already being hit by bots within days of setup.

Key tools: `journalctl -p err`, `grep`, `awk`, `sort`, `uniq`

---

## Windows

### [Setup](windows/README.md)

Installed PowerShell 7 (`pwsh.exe`) via winget rather than using the built-in Windows PowerShell 5.1. PowerShell 7 is the current cross-platform version and the one used by Azure and modern Microsoft tooling. Also set up a Windows 10 VM and Windows Server 2025 VM inside Hyper-V with an internal virtual switch for isolated lab networking.

### [PowerShell Basics](windows/powershell_basics/README.md)

Covered filesystem navigation, file creation and deletion, process management, and system information queries. A key thing learned here is that PowerShell pipelines pass objects rather than plain text, which means each cmdlet can inspect and select specific properties from what it receives rather than parsing string output.

Key cmdlets: `Get-Location`, `Set-Location`, `Get-ChildItem`, `New-Item`, `Remove-Item`, `Get-Process`, `Stop-Process`, `Select-String`, `Get-CimInstance`, `Get-PSDrive`, `Get-ComputerInfo`

### [Local User and Group Management](windows/local_user_management/README.md)

Created local user accounts and groups through PowerShell, added users to groups, and practiced disabling and enabling accounts. Mirrors the Linux user management work but through the Windows local account model. Passwords must be passed as SecureString objects rather than plain text, which reflects how PowerShell handles sensitive data.

Key cmdlets: `New-LocalUser`, `New-LocalGroup`, `Add-LocalGroupMember`, `Get-LocalUser`, `Get-LocalGroupMember`, `Disable-LocalUser`, `Enable-LocalUser`, `Remove-LocalUser`

### [Package Management and File Permissions](windows/package_management_and_permissions/README.md)

Used winget to search, install, and upgrade packages from the command line. Then practiced NTFS permission management using icacls, including granting group-level access with inheritance flags and adding explicit deny entries. The explicit deny concept is a meaningful difference from Linux, where permissions are purely additive.

Key tools: `winget`, `icacls /grant`, `icacls /deny`, `Add-LocalGroupMember`

### [Event Logs](windows/event_logs/README.md)

Explored Windows event logs through both Event Viewer (GUI) and PowerShell. Learned the key Security event IDs for auditing purposes and used `Get-WinEvent` with `-FilterHashtable` to query the Security log efficiently. Exported filtered results to CSV for offline analysis.

Key tools: `eventvwr.exe`, `Get-WinEvent`, `Export-CSV`, Security event IDs (4624, 4625, 4634, 4740)

### [Password Policy, System Integrity and File Ownership](windows/policy_integrity_ownership/README.md)

Used `net accounts` to view and harden local password and lockout policy. Ran `sfc /scannow` to verify system file integrity. Practiced taking ownership of files with `takeown` and then adjusting permissions with `icacls`. The section ends with a full Linux to Windows command reference table mapping equivalent tools across both operating systems.

Key tools: `net accounts`, `sfc`, `DISM`, `takeown`

---

## Linux vs Windows - Quick Reference

A full comparison table is included in the [policy, integrity and ownership](windows/policy_integrity_ownership/README.md) section. The short version is that the concepts are identical across both OSes. The tools and syntax differ, but user management, permissions, process control, logging, and package management all exist on both sides.

---

## What Comes Next

The next phase covers networking fundamentals: IP addressing, subnetting, DNS, routing, firewalls, and packet analysis. The Hyper-V lab environment with the internal virtual switch is already set up and will be used for hands-on networking practice between the Windows 10 and Windows Server VMs.
