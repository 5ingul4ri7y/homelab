# VPS Security Posture - Sohaib - 18 October 2026

**System:** Oracle Cloud VPS, Ubuntu 24.04

## Executive Summary

This document describes the security controls implemented on my Oracle Cloud VPS, the residual risk I have accepted, and recommendations for further improvement. The server hosts my homelab website and is used only for labs and documentation, so it holds no production or customer data.

**Overall security posture: GOOD - Lynis score 82/100**

GOOD describes how strong the controls in place are. The MEDIUM residual risk in the risk assessment describes what is still exposed after those controls, so the two ratings do not conflict.

The Lynis hardening index went from 66 at baseline to 69 at the end of Phase 3, dipped to 68 when rkhunter pulled in an unhardened postfix dependency, and reached 82 at the final audit after the hardening sprint fixed it, against a target of 80 or more. On my own scale, 80 to 90 is serious hardening effort. An external scan from Kali confirmed the result from an attacker's point of view: only three TCP ports are reachable (SSH on a non-standard port, HTTP and HTTPS), the SSH banner shows the OpenSSH version but hides the OS, the web server leaks no version information, and all HTTP requests are redirected to HTTPS. The main gaps that remain are logs that only exist on the server itself, a single factor on SSH, and backups that only cover configuration. The risk assessment rates the overall residual risk as MEDIUM.

## Latest Audit Results

| Check | Result |
|-------|--------|
| Open TCP ports (nmap service scan from Kali) | 2222 (SSH, non-standard port), 80 (HTTP), 443 (HTTPS) |
| SSH banner | OpenSSH version is shown, but the OS and build details that are normally present in the banner are hidden |
| TLS certificate | Valid |
| HTTP on port 80 | Redirects all requests to HTTPS |
| Response headers | No nginx version leaked, X-Frame-Options and Strict-Transport-Security set, other required security headers present |
| Lynis hardening index | 66 baseline, 69 end of Phase 3, 68 before the hardening sprint (unhardened postfix), 82 final (target 80+) |

## 1. Perimeter Controls

- **Layered firewalls:** Oracle Cloud firewall as the outer layer, and a host firewall with a default-restrictive policy. The external scan confirms only SSH (2222), HTTP (80) and HTTPS (443) are reachable.
- **fail2ban:** automated banning of repeated failed logins.
- **Suricata IDS:** Emerging Threats ruleset (about 52,800 rules at first load) plus a custom rule for a known C2 address, proven in the incident response simulation. It runs in IDS mode, so it alerts but does not block.

## 2. Authentication Controls

- **SSH:** key-based authentication, root login disabled, non-standard port 2222.
- **PAM password policy:** pwquality with a 14 character minimum, at least one digit, uppercase, lowercase and special character, no more than 3 repeated characters, and a GECOS check.
- **Account lockout:** pam_faillock locks an account after 5 failures and unlocks it after 15 minutes.
- **Account hygiene:** accounts audited and unused ones removed, password hashing and aging configured, umask 027, restrictive permissions on sshd_config (600), shadow (640) and crontab (600), and SUID/SGID binaries reviewed.
- **Admin endpoint:** home network on WPA3 with WPS off and the router admin interface not exposed to the internet, and a hardened browser (HTTPS-only mode, DNS over HTTPS, uBlock Origin and a password manager).

## 3. Application Controls

- **nginx:** reverse proxy in front of the site's backends. Hardened response headers (Content-Security-Policy, Strict-Transport-Security, X-Frame-Options, Referrer-Policy and Permissions-Policy), version information suppressed, and HTTP redirected to HTTPS.
- **TLS:** Let's Encrypt certificate (valid in the audit) with automatic renewal through Certbot, modern TLS only.
- **WAF:** ModSecurity with OWASP CRS 3.3.5 in enforcement mode. Tested against SQL injection, XSS, path traversal and scanner traffic, with the attack requests returning 403.
- **Service hardening:** the web server runs inside a systemd sandbox with restricted privileges.

## 4. System Integrity Controls

- **auditd:** five rules under the keys identity, privilege, exec and system (passwd, shadow, sudoers, process execution and hostname changes).
- **rkhunter:** baseline built, daily scan and weekly database update through cron, last full check clean.
- **File integrity monitoring** on critical system files.
- **sysctl hardening:** SYN cookies, reverse path filtering, ICMP redirects and source routing disabled, martian packet logging, dmesg and kernel pointer restriction, full ASLR and BPF JIT hardening.
- **Reduced attack surface:** unused filesystems (cramfs, freevxfs, jffs2, hfs, hfsplus) and usb-storage disabled, unused network protocols and kernel modules blocked, core dumps disabled, AppArmor enabled, and process and system accounting turned on.
- **Lynis:** periodic automated audits to track the score over time.

## 5. Backup and Recovery

- Configuration backups and a rollback plan before every change, with changes tested in a second session before closing the first.
- There is no full-system backup and no tested restore yet, this is listed as a known gap below.

## 6. Monitoring and Visibility

- **Netdata:** real-time monitoring, only reachable through SSH port forwarding and never exposed publicly. **vnstat** tracks bandwidth totals over days and months.
- **Attack summary:** a script in root's crontab runs daily at 06:00 and writes dated reports to `/var/log/attack-summary/`, covering total attack attempts, top attacking IPs, unique IP count and top targeted usernames from the SSH logs.
- **Log sources:** Suricata alerts, auditd, the ModSecurity audit log, the SSH journal and fail2ban. All of these currently stay on the server.

## 7. Patch Management

- **unattended-upgrades:** daily security-only updates including the Ubuntu ESM channels, no automatic reboot, email on failure, and old kernels removed automatically. Package integrity verification and post-upgrade checks for services still running outdated libraries are in place.
- **Patch priorities:** Critical (CVSS 9.0 or higher) within 24 hours, High (7.0 to 8.9) within 72 hours, Medium and Low in the next maintenance window. To check whether a CVE affects me, I compare the affected version range with the installed version and check `apt-cache policy` for backported fixes.
- Because automatic reboot is off, a patched kernel only takes effect after I reboot manually.

## 8. Known Gaps and Accepted Risks

- **No SIEM or central logging.** All logs only exist on the VPS, so someone with root could alter or delete them. The SIEM architecture is documented but not deployed. Planned: ship logs to a second system in real time.
- **Kernel updates need a manual reboot.** Planned: a regular reboot window, or kernel live patching if it is available.
- **SSH depends on a single factor.** Anyone holding my private key has a way in. Planned: add a TOTP second factor.
- **Suricata is detection only.** It alerts but does not block, and the C2 address rule has no `classtype` or priority. Planned: add a classtype to the C2 rule and consider IPS mode only after tuning.
- **auditd rule set is minimal.** Not yet watched: /etc/group, /etc/gshadow, /etc/sudoers.d/, auth.log tampering and time changes. Planned: extend the rules and keep an eye on audit log size.
- **WAF is at the default CRS paranoia level and untuned.** Planned: review the logs for false positives and try a higher paranoia level.
- **Backups are configuration-only.** Accepted for now because the server only holds lab material. Planned: a full snapshot and a tested restore.
- **Dependency on DuckDNS.** The site lives on a free dynamic DNS subdomain, so an outage or loss of the account token takes the site offline or lets someone repoint it.
- **Lynis score of 82 out of 100.** Some suggestions are still open and tracked through periodic audits.
- **Trust assumptions I accept:** Oracle for the hardware, hypervisor and console, the Ubuntu repositories, the third-party Suricata PPA and Let's Encrypt for updates and certificates, and my own admin machine (Windows 11, kept up to date) as the way into the server.

## Related Documents

- [Security audit](../../Security/System_Hardening/vps_security_audit/README.md)
- [VPS risk assessment](../risk_assessment_vps/README.md)
- [Incident report](../c2_incident_report/README.md)
- [Post-mortem](../../Post_Mortems/postmortem_vps_c2_incident.md)
