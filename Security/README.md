# Phase 4 - Security: Cryptography, Network Defence and System Hardening

## What I Built

A defence-in-depth setup for the Oracle VPS and the Hyper-V lab: Suricata IDS with custom rules, a ModSecurity WAF in front of nginx (switched from detection to enforcement), kernel, PAM and auditd hardening, automatic patching and a daily attack summary, plus a pfSense gateway for the internal VMs. On the offensive side I practiced cryptography hands-on (hashing, signing, hybrid encryption, GPG, cracking weak hashes), staged and responded to a simulated C2 incident, and audited my own server and home network from Kali. The VPS Lynis score went from 68 to 82.

## Key Accomplishments

**Cryptography**
- [x] Encrypted and decrypted files with AES-256-CBC and compared cipher modes (CBC, GCM, ECB, CTR) (`openssl enc -aes-256-cbc -salt -pbkdf2`)
- [x] Generated an RSA-2048 key pair, encrypted with the public key and decrypted with the private key, and explained why hybrid encryption exists (`openssl genrsa`, `openssl pkeyutl`)
- [x] Signed a document, verified it, then tampered with it and watched verification fail (`openssl dgst -sha256 -sign`, `-verify`)
- [x] Created a self-signed certificate and traced the Let's Encrypt chain for my own domain (`openssl req -x509`, `openssl s_client`)
- [x] Created RSA-4096 GPG keys, encrypted and clear-signed messages, and verified an Arch Linux ISO signature
- [x] Showed the avalanche effect and cracked an MD5 hash and a SHA-512 crypt hash (`qwerty`) with John the Ripper and a wordlist, using hashes I created myself
- [x] Captured plaintext FTP credentials with `tcpdump` (13 packets, 0 dropped) and analysed the capture in Wireshark

**Network security**
- [x] Installed Suricata in IDS mode with the Emerging Threats ruleset (52,828 rules loaded, 0 failed) and triggered my first alert with `curl http://testmyids.com`
- [x] Wrote three custom learning rules (access to `/secret`, SYN scan threshold, outbound traffic to a suspicious range), tested two of them in `fast.log` (the `/secret` rule and the suspicious-range rule), and removed them afterwards
- [x] Monitored the VPS with Netdata (reached through SSH port forwarding, never exposed publicly) and vnstat
- [x] Put pfSense on Hyper-V and routed selected VMs through it by setting it as their gateway (`ip route add default via 192.168.50.4`)
- [x] Applied ACLs with `setfacl` (including a default ACL and the effective-permission mask) and checked least privilege on live `sshd` and `nginx` processes
- [x] Moved my home Wi-Fi from WPA2 to WPA3 (SAE) with WPS off and no WAN admin access

**System hardening**
- [x] Ran a Lynis baseline (68), then worked through the findings: umask 027, tightened file permissions, SUID/SGID review, PAM password rules (14 characters minimum) and account lockout (5 failures, 15 minutes)
- [x] Added auditd rules for identity, sudoers, execve and hostname changes, and verified them with `ausearch -k identity`
- [x] Ran an rkhunter baseline and full scan, scheduled daily
- [x] Hardened the kernel through `/etc/sysctl.d/99-hardening.conf` (SYN cookies, reverse path filtering, no ICMP redirects or source routing, `kptr_restrict`, `bpf_jit_harden`, ASLR)
- [x] Disabled unused filesystem modules and `usb-storage`, and configured `unattended-upgrades` with ESM channels and manual reboots
- [x] Installed ModSecurity with the OWASP CRS on nginx, caught SQLi, XSS and path traversal in DetectionOnly mode (rule 942100, anomaly score 5), then switched to `SecRuleEngine On` and saw the same requests return 403
- [x] Analysed the journal's attack history: 474,952 failed SSH attempts from 4,123 unique IPs over about six months, then automated a daily 6:00 AM summary report with cron

**Incident response and audit**
- [x] Built and ran a simulated C2 incident (fake listener and "malware" on a TEST-NET-3 address) and responded in order: identify (`ss`, `/proc`, `lsof`), contain (`ufw deny out`, `strace`, evidence files), eradicate (persistence checks, `kill`, `rm`), recover (rkhunter, `aureport`) - see the [incident report](../Audits_and_Reports/c2_incident_report/README.md), [post-mortem](../Post_Mortems/postmortem_vps_c2_incident.md) and [risk assessment](../Audits_and_Reports/risk_assessment_vps/README.md)
- [x] Scanned my own VPS from Kali (`nmap -sV -sC`): only ports 2222, 80 and 443 respond, no nginx version leaks, and the WAF returned 403 to nmap's user agent
- [x] Audited my home network the way an attacker would (`nmap -sn`, `-sV --open`, `-sV -sC` on the router) and worked through a router checklist
- [x] Wrote up the concepts without building them: ARP poisoning and its defences, Kerberos ticket flow, UTM and SIEM design

**Measured outcomes**
- [x] Lynis hardening index: 68 at the start of this phase to 82 at the end (+14); 66 at the mid-Phase 3 baseline to 82 overall (+16)

## Technologies Used

| Tool | Purpose | Evidence |
|---|---|---|
| OpenSSL | Hashing, AES, RSA, signatures, certificates | [Cryptography/](Cryptography/crypto_lab/README.md) |
| GnuPG | Key pairs, encrypted and signed messages, ISO verification | [gpg_pgp_web-of-trust/](Cryptography/gpg_pgp_web-of-trust/README.md) |
| John the Ripper (Kali) | Hash cracking demonstrations | [hashing/](Cryptography/hashing/README.md), [crypto_lab/](Cryptography/crypto_lab/README.md) |
| tcpdump, Wireshark | Plaintext FTP capture and analysis | [crypto_lab/](Cryptography/crypto_lab/README.md) |
| Suricata | Network IDS and custom signatures | [suricata_ids/](Network_Security/suricata_ids/README.md), [suricata_custom_rules/](Network_Security/suricata_custom_rules/README.md) |
| ModSecurity, OWASP CRS | Web application firewall on nginx | [modsecurity_waf/](System_Hardening/modsecurity_waf/README.md) |
| pfSense, Netdata, vnstat | Gateway firewall and monitoring | [network_monitoring_utm/](Network_Security/network_monitoring_utm/README.md) |
| setfacl, getfacl | ACL-based access control | [access_control_models/](Network_Security/access_control_models/README.md) |
| PAM (pwquality, faillock), auditd, rkhunter | Authentication policy, audit logging, rootkit scanning | [hardening_sprint/](System_Hardening/hardening_sprint/README.md) |
| sysctl | Kernel parameter hardening | [kernel_hardening/](System_Hardening/kernel_hardening/README.md) |
| unattended-upgrades | Automatic security patching | [patch_management/](System_Hardening/patch_management/README.md) |
| journalctl, awk, cron | Attack intelligence and daily reporting | [log_analysis/](System_Hardening/log_analysis/README.md) |
| strace, lsof, /proc, UFW | Incident investigation and containment | [incident_response/](System_Hardening/incident_response/README.md) |
| Lynis | Hardening score tracking | [kernel_hardening/](System_Hardening/kernel_hardening/README.md), [vps_security_audit/](System_Hardening/vps_security_audit/README.md) |
| nmap (Kali) | Attacker-view audits of the VPS and home network | [vps_security_audit/](System_Hardening/vps_security_audit/README.md), [home_network_hardening/](System_Hardening/home_network_hardening/README.md) |

## Key Learnings

Encryption protects only what it covers. Plaintext FTP gave up its credentials in a single capture, and ARP poisoning only gives an attacker a position on the wire, so whether that position is worth anything depends on whether the traffic was encrypted. The same idea showed up in the cracking labs: a hash does not protect a password like `qwerty`, however strong the algorithm is.

Detection and prevention need to be layered and tuned. Suricata sees packets and ModSecurity sees HTTP, so they catch different things, and the WAF only blocked real traffic after I had watched it in DetectionOnly mode first. I also learned to verify rather than assume: the WAF's 403 on nmap's user agent showed up only because I tested it from outside, and Lynis gave me a number (68 to 82) to check my hardening against instead of a feeling.

## Files in This Directory

| Folder | Description |
|---|---|
| [Cryptography/symmetric_encryption/](Cryptography/symmetric_encryption/README.md) | AES-256-CBC and cipher modes |
| [Cryptography/asymmetric_encryption/](Cryptography/asymmetric_encryption/README.md) | RSA key pair, encryption, hybrid encryption |
| [Cryptography/hashing/](Cryptography/hashing/README.md) | Hash algorithms, avalanche effect, MD5 cracking |
| [Cryptography/digital_signatures/](Cryptography/digital_signatures/README.md) | Signing, tamper detection, certificates and PKI chain |
| [Cryptography/gpg_pgp_web-of-trust/](Cryptography/gpg_pgp_web-of-trust/README.md) | GPG keys, signing, web of trust vs CA model |
| [Cryptography/crypto_lab/](Cryptography/crypto_lab/README.md) | Six-part capstone: hash, sign, encrypt, crack, inspect, capture |
| [Network_Security/access_control_models/](Network_Security/access_control_models/README.md) | DAC, MAC, RBAC, ACLs, Kerberos |
| [Network_Security/arp_poisoning_concept/](Network_Security/arp_poisoning_concept/README.md) | ARP poisoning concept and defences |
| [Network_Security/network_monitoring_utm/](Network_Security/network_monitoring_utm/README.md) | Netdata, vnstat, pfSense and UTM |
| [Network_Security/suricata_ids/](Network_Security/suricata_ids/README.md) | Suricata install and first alert |
| [Network_Security/suricata_custom_rules/](Network_Security/suricata_custom_rules/README.md) | Custom rules, signature vs anomaly detection |
| [Network_Security/wireless_security/](Network_Security/wireless_security/README.md) | WEP to WPA3, 4-way handshake, home router upgrade |
| [System_Hardening/kernel_hardening/](System_Hardening/kernel_hardening/README.md) | Lynis baseline and sysctl hardening |
| [System_Hardening/hardening_sprint/](System_Hardening/hardening_sprint/README.md) | PAM, auditd, rkhunter, file permissions |
| [System_Hardening/patch_management/](System_Hardening/patch_management/README.md) | Unattended upgrades, CVE reading, patch priorities |
| [System_Hardening/log_analysis/](System_Hardening/log_analysis/README.md) | Attack statistics and the daily summary script |
| [System_Hardening/modsecurity_waf/](System_Hardening/modsecurity_waf/README.md) | WAF in detection mode, then enforcement |
| [System_Hardening/incident_response/](System_Hardening/incident_response/README.md) | Simulated C2 incident and response |
| [System_Hardening/vps_security_audit/](System_Hardening/vps_security_audit/README.md) | Attacker-view scan, Lynis progression, SIEM concept |
| [System_Hardening/home_network_hardening/](System_Hardening/home_network_hardening/README.md) | Browser hardening, DoH, home network audit |
