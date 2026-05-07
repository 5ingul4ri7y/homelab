# Day 0 - VPS Setup + SSH + Github Init


## What I did
- SSHed into Oracle VPS for the first time
- Changed hostname to my preference
- Ran system updates
- Initialised homelab GitHub repo
- Hardened SSH by changning settings in /etc/ssh/sshd_config to be strict i.e max 3 attempts, no root login and no x11 aforwarding

## Key commands used
- ssh -i ~/.ssh/oracle_key ubuntu@x.x.x.x
- sudo hostnamectl set-hostname labserver
- sudo apt update && sudo apt upgrade -y


## VPS Overview
![/home/ubuntu/homelab/linux/images/vps.PNG]

- **Provider:** Oracle Cloud Infrastructure (OCI) — Free Tier
- **OS:** Ubuntu 24.04 LTS
- **Purpose:** General-purpose homelab environment for Linux & sysadmin learning, lightweight service hosting, and security tooling practice
- **Access:** SSH with private key authentication (password auth disabled)
- **Repo scope:** Tracks configuration, scripts, and documentation from this lab — no credentials, keys, or sensitive system details are committed
