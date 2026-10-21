# VPS Risk Assessment - Oracle Cloud VPS - 14 October 2026

## 1. Executive Summary

This assessment covers the Oracle Cloud VPS running Ubuntu 24.04 that hosts my homelab website, assessed on 14 October 2026. The system is a public-facing nginx web server with SSH access, used only for labs and documentation, so it holds no production or customer data. Overall risk is rated MEDIUM. The system is well hardened, with layered controls in place (cloud and host firewalls, key-based SSH, a WAF in enforcement mode, an IDS, kernel-level audit logging and automatic security patching), and the Lynis hardening index went from 68 to 82 over the Security phase. The remaining risk comes from the public attack surface, a single administrative access path, and logs that only exist on the server itself.

**Overall Risk Rating: MEDIUM** Critical findings: 0 | High: 0 | Medium: 3 | Low: 5

**Scope and method.** In scope are the VPS operating system, the services it exposes (nginx, ModSecurity, SSH and WireGuard) and the security tooling running on it. Out of scope are my Oracle Cloud account, my home network and admin workstation (except where they affect the risk to the VPS), and my other cloud instances. The findings come from the Lynis audits (baseline of 68 with 269 tests performed, then 82 after the hardening sprint), the VPS port audit from the Sysadmin phase, my testing of Suricata, ModSecurity and auditd during the Security phase, the incident response simulation, and manual review. Risk is scored as Likelihood x Impact on a 1 to 5 scale. A score of 1 to 5 is Low, 6 to 11 is Medium, 12 to 19 is High and 20 to 25 is Critical.

## 2. Assets Being Protected

|Asset|Classification|Value|
|---|---|---|
|Lab website availability (sohaib-lab.duckdns.org)|Availability|High, it is the public face of the homelab project|
|nginx configuration, TLS certificate and private key|Confidentiality|High, a leaked private key would let someone impersonate the site|
|Admin account, SSH access and sudo rights|Confidentiality|Critical, they give full control of the host|
|VPS integrity (system binaries and configuration)|Integrity|High, a compromise hands the attacker the whole system|
|Audit trail (auditd, Suricata and ModSecurity logs)|Integrity|Medium, needed to investigate incidents, and tampering would hide an intrusion|
|Server IP reputation|Reputation|Medium, abuse could get the IP blocklisted or the instance suspended|

This server only holds lab material. No production services or customer data run on it, which is what keeps the impact of a compromise at significant and not critical.

## 3. Threat Actors

|Threat Actor|Motivation|Capability|Likelihood|
|---|---|---|---|
|Automated bots and scanners|Cryptomining, spam relay, credential harvesting|Low to Medium|HIGH, already seen in the Suricata logs as repeated SSH banner probing from external addresses|
|Opportunistic attackers|Practice, reusing public exploits|Low to Medium|MEDIUM|
|Script kiddies|Curiosity, vandalism, defacement|Low|MEDIUM|
|Administrator error (me)|None, accidents|Not applicable|MEDIUM, my earlier post-mortems document outages caused by misconfiguration|
|Supply chain compromise|Malicious package or repository|High, but outside my control|LOW, relevant because I use a third-party PPA for Suricata|
|Targeted attacker|Very little, this is a low value target|High|LOW|

## 4. Vulnerabilities Identified

From the Lynis audits, the port audit, my own testing and manual review:

**MEDIUM (V1): No centralised logging.** The auditd, Suricata, ModSecurity and system logs only exist on the VPS. Someone with root could edit or delete them, which would hide what they did.

**MEDIUM (V2): Kernel updates are not live until I reboot.** unattended-upgrades is set with Automatic-Reboot disabled, so a patched kernel only takes effect after a manual reboot. The server previously ran for a long time between reboots, so this gap is real and not just theoretical.

**MEDIUM (V3): Administrative access depends on a single factor.** SSH is key-based, which is strong against brute force, but there is no second factor, so anyone who gets hold of my private key has a way in.

**LOW (V4): The auditd rule set is minimal.** Five rules cover passwd, shadow, sudoers, process execution and hostname changes. Not watched yet are /etc/group, /etc/gshadow, /etc/sudoers.d/, tampering with auth.log and system time changes. The execve rule is also high volume, so audit log disk usage needs watching.

**LOW (V5): The WAF is at the default CRS paranoia level with one protected site.** It blocks the common attacks I tested (SQL injection, XSS and path traversal) but has not been tuned against real traffic. A higher paranoia level would catch more, and untuned rules can also block legitimate requests.

**LOW (V6): Backups are configuration-only.** I take configuration backups before every change, but there is no tested full-system backup or restore. A rebuild would mean repeating the setup from my notes. This stays Low because the server only holds lab material and the labs are documented.

**LOW (V7): Dependency on a free dynamic DNS provider.** The site lives on a DuckDNS subdomain, so an outage at DuckDNS or loss of the account token would take the site offline or let someone repoint it. An earlier IP drift problem is documented in my post-mortems.

**LOW (V8): Lynis score of 82 out of 100.** Some suggestions are still open. Periodic automated audits track them over time.

## 5. Controls In Place

| Area          | Control                   | Detail                                                                                                                                                                                                                                |
| ------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Network       | Layered firewalls         | Oracle Cloud firewall as the outer layer, host firewall with a default-restrictive policy, only required services exposed and unused services removed                                                                                 |
| Access        | SSH hardening             | Key-based authentication, root login disabled, non-default port                                                                                                                                                                       |
| Access        | fail2ban                  | Automated banning of repeated failed logins                                                                                                                                                                                           |
| Access        | PAM password policy       | pwquality with a 14 character minimum, at least one digit, uppercase, lowercase and special character, no more than 3 repeated characters, and a GECOS check                                                                          |
| Access        | Account lockout           | pam_faillock locks an account after 5 failures and unlocks it after 15 minutes                                                                                                                                                        |
| Access        | Account hygiene           | Accounts audited and unused ones removed, password hashing and aging configured, umask 027, restrictive permissions on sshd_config (600), shadow (640) and crontab (600), SUID/SGID binaries reviewed with nothing unexpected         |
| Access        | Admin endpoint            | Home network on WPA3 with WPS off and the router admin interface not exposed to the internet, browser hardened with HTTPS-only mode, DNS over HTTPS, uBlock Origin and a password manager                                             |
| Kernel and OS | sysctl hardening          | SYN cookies, reverse path filtering, ICMP redirects and source routing disabled, martian packet logging, dmesg and kernel pointer restriction, full ASLR and BPF JIT hardening                                                        |
| Kernel and OS | Reduced attack surface    | Unused filesystems (cramfs, freevxfs, jffs2, hfs, hfsplus) and usb-storage disabled, unused network protocols and kernel modules blocked, core dumps disabled                                                                         |
| Kernel and OS | Mandatory access control  | AppArmor enabled, with process and system accounting turned on                                                                                                                                                                        |
| Web           | TLS                       | Let's Encrypt certificate through Certbot with automatic renewal, modern TLS only, legacy protocols disabled                                                                                                                          |
| Web           | Security headers          | Content-Security-Policy, Referrer-Policy and Permissions-Policy set in nginx                                                                                                                                                          |
| Web           | WAF                       | ModSecurity with OWASP CRS 3.3.5 in enforcement mode, tested against SQL injection, XSS, path traversal and scanner traffic, with the attack requests returning 403                                                                   |
| Web           | Service hardening         | Service banners and version information suppressed, and the web server runs inside a systemd sandbox with restricted privileges                                                                                                       |
| Detection     | Suricata IDS              | Emerging Threats ruleset (about 52,800 rules at first load) plus a custom rule for a known C2 address, proven in the incident response simulation                                                                                     |
| Detection     | auditd                    | Five rules under the keys identity, privilege, exec and system, verified by triggering the identity rule                                                                                                                              |
| Detection     | rkhunter                  | Baseline built, daily scan and weekly database update through cron, last full check clean                                                                                                                                             |
| Detection     | File integrity monitoring | Monitoring on critical system files                                                                                                                                                                                                   |
| Monitoring    | netdata and vnstat        | Real-time and long-term monitoring, with netdata only reachable through SSH port forwarding and never exposed publicly                                                                                                                |
| Patching      | unattended-upgrades       | Daily security-only updates including the ESM channels, no automatic reboot, email on failure, old kernels removed automatically, plus package integrity verification and post-upgrade checks for services running outdated libraries |
| Process       | Change control            | Configuration backup and rollback plan before each change, changes tested in a second session before closing the first, re-audit after each round (Lynis 68 to 82)                                                                    |
| Process       | Incident response         | Full incident response lifecycle practiced in a simulated C2 incident on the VPS                                                                                                                                                      |

## 6. Residual Risk and Recommendations

**Residual risks:**

1. A zero-day in nginx, OpenSSH or ModSecurity could bypass all of the current controls. The WAF and IDS are mostly signature based, so they are weakest against attacks nobody has written a rule for yet.
2. The administrator endpoint sits outside the VPS's technical controls. My own PC (Windows 11, kept up to date) and any phishing or social engineering aimed at me are the most direct route to the server.
3. I trust Oracle with the underlying hardware and hypervisor, and an account takeover of my Oracle Cloud console would bypass everything configured on the VPS. Both are outside the scope of this assessment.
4. I trust the Ubuntu repositories, the third-party Suricata PPA and Let's Encrypt. A compromise of any of them would reach the server through a normal update.
5. This is a point-in-time assessment, so it goes out of date as the system changes.

**Recommendations (priority order):**

1. Ship logs to a second system so an intruder with root cannot erase the evidence (V1).
2. Add a second factor for SSH, such as a TOTP code alongside the key, and consider restricting SSH to known source addresses at the cloud firewall (V3).
3. Schedule a regular reboot window so kernel patches go live, or use kernel live patching if it is available (V2).
4. Extend the auditd rules to cover /etc/group, /etc/gshadow, /etc/sudoers.d/, auth.log and time changes, and keep an eye on audit log size (V4).
5. Review the WAF logs for false positives and try a higher CRS paranoia level (V5).
6. Take a full snapshot or boot volume backup and test restoring from it (V6).
7. Keep running the periodic Lynis audits and close the remaining suggestions (V8).

## 7. Risk Matrix - Top 5 Risks

Risk = Likelihood x Impact, scored after the controls above.

| ID  | Risk                                                                                                                                                                | Likelihood       | Impact        | Score | Rating | Related findings                                                                |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ------------- | ----- | ------ | ------------------------------------------------------------------------------- |
| R1  | A zero-day or unpatched flaw in an exposed service (nginx, OpenSSH, ModSecurity) lets an attacker in, including the window before a patched kernel is rebooted into | 2 Unlikely       | 4 Significant | 8     | Medium | V2, V5                                                                          |
| R2  | Admin access is compromised through my SSH key or my admin machine                                                                                                  | 2 Unlikely       | 4 Significant | 8     | Medium | V3                                                                              |
| R3  | An intruder alters or deletes the local logs to hide their activity                                                                                                 | 2 Unlikely       | 3 Moderate    | 6     | Medium | V1, V4                                                                          |
| R4  | A misconfiguration or a DNS or provider problem takes the site offline                                                                                              | 3 Possible       | 2 Minor       | 6     | Medium | V6, V7                                                                          |
| R5  | Constant automated scanning and exploit attempts against SSH and HTTP                                                                                               | 5 Almost certain | 1 Negligible  | 5     | Low    | Seen in the Suricata logs, blocked or logged by the firewalls, fail2ban and WAF |

| Likelihood / Impact  | 1 Negligible | 2 Minor | 3 Moderate | 4 Significant | 5 Critical |
| -------------------- | ------------ | ------- | ---------- | ------------- | ---------- |
| **5 Almost certain** | R5           |         |            |               |            |
| **4 Likely**         |              |         |            |               |            |
| **3 Possible**       |              | R4      |            |               |            |
| **2 Unlikely**       |              |         | R3         | R1, R2        |            |
| **1 Rare**           |              |         |            |               |            |

R5 is the only risk with a likelihood of 5, since the internet scans every exposed host all the time, but the layered controls keep the impact negligible. R1 and R2 are the highest residual risks and share a cell, one coming from software I cannot fully control and the other from the single administrative path into the server. Both are the reason the overall rating stays at MEDIUM and not LOW.
