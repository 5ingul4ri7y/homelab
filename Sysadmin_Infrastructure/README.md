# Phase 3 — Sysadmin Infrastructure

Phase 3 moves the homelab from networking fundamentals into actual systems infrastructure.

The phase covers publicly reachable web infrastructure on Oracle Cloud, host-level security, DNS and DHCP, load balancing, automated operations, file services, time synchronization, and a Windows Active Directory environment running inside Hyper-V.

The goal was not simply to install services, but to understand how they fit together, verify their behaviour, and document the reasoning behind the resulting configuration.

## Architecture

![Homelab Architecture — End of Phase 3](assets/architecture-phase3.png)

The Phase 3 environment has two distinct infrastructure domains.

### Oracle Cloud

The cloud side contains a primary public-facing VPS and a restricted secondary VPS.

The primary VPS handles:

* Nginx reverse proxy
* TLS termination
* SSH access
* WireGuard VPN
* BIND9
* host-level firewalling
* dynamic DNS
* backup automation

Nginx can forward traffic to the cloud backends, while the secondary VPS is restricted to traffic originating from the primary VPS.

### Hyper-V

The local infrastructure runs on an internal Hyper-V network.

The lab contains:

* `DC01` — Active Directory domain controller
* `Client1` — domain-joined Windows client
* `VM2` — Linux test client
* `VM1` — infrastructure services
* DHCP
* BIND9
* HAProxy
* two Dockerized Apache backends

The internal Hyper-V network is intentionally documented as **not air-gapped from the host**. The host's `vEthernet` internal switch provides connectivity between the PC and Hyper-V guests.

## What Was Built

### 1. Web Infrastructure

Apache2 was first configured directly, including virtual hosts and server hardening.

The architecture was then extended so that Nginx became the public-facing reverse proxy and TLS termination point.

The cloud web path is therefore conceptually:

```text
Internet
   │
   ▼
OCI network filtering
   │
   ▼
UFW / iptables
   │
   ▼
Nginx
   ├──► cloud backend A
   └──► restricted cloud backend B
```

TLS certificates are issued and renewed using Certbot and Let's Encrypt.

### 2. SSH & Host Security

SSH was hardened with:

* key-based authentication
* password authentication disabled
* root login disabled
* reduced authentication attempts
* non-default SSH port
* configuration stored under `sshd_config.d/`

Fail2Ban was added to react to repeated authentication failures.

The resulting access path is protected by both cloud-level and host-level controls.

### 3. Firewalling

The VPS uses multiple filtering layers:

```text
Internet
   │
   ▼
OCI Network Security Group
   │
   ▼
UFW
   │
   ▼
iptables / netfilter
   │
   ▼
Service
```

The firewall configuration was not treated as correct simply because the rules looked reasonable.

Open listeners were audited directly and justified against:

* `ss -ulnp`
* `ss -tlnp`
* `systemctl`
* UFW rules
* OCI network rules
* service configuration

This led to the removal of unnecessary services including rpcbind, rpc-statd, Squid, fwupd, ModemManager, and udisks2.

### 4. DNS

DNS work covered both theory and operational configuration.

The phase included:

* BIND9 authoritative DNS
* recursive resolution
* forward zones
* reverse DNS
* PTR records
* recursion ACLs
* internal DNS
* dnsmasq comparison
* DNS/DHCP service comparisons
* SPF/DKIM/DMARC record analysis

The final VPS BIND configuration restricts recursive access rather than relying only on the interface on which the service happens to listen.

### 5. DHCP

ISC DHCP Server was configured with:

* DHCP address pool
* reservations
* lease verification
* client testing

The Hyper-V infrastructure VM provides DHCP for the internal lab network.

### 6. Load Balancing

Two different load-balancing designs exist in the Phase 3 environment and should not be confused.

#### Cloud-side Nginx

Nginx acts as the public reverse proxy and can distribute web traffic across the cloud backends.

#### Hyper-V HAProxy

HAProxy is a separate local infrastructure service running inside VM1.

It distributes requests across two Dockerized Apache backends:

```text
HAProxy
   ├──► backend_a :8001
   └──► backend_b :8002
```

Health checks, failover, and multiple balancing algorithms were tested.

### 7. Active Directory

The Windows side of the lab was extended into a working Active Directory domain.

The environment includes:

* Windows Server 2022 domain controller
* `corp.lab`
* organizational units
* users and groups
* Group Policy
* GPO inheritance
* LDAP queries
* domain-joined Windows client
* Fine-Grained Password Policy

LDAP fundamentals were explored directly before relying on the Active Directory management interface.

### 8. Fine-Grained Password Policy

A Fine-Grained Password Policy was created and applied to the administrative security group.

The policy was verified through Active Directory PowerShell commands and by testing the resulting lockout behaviour from the domain client.

The important lesson was that policy configuration was verified through **resultant policy and actual client behaviour**, rather than assumed from the configuration alone.

### 9. Backups

Nightly offsite backups were automated using rsync and cron.

The process includes:

* scheduled backup execution
* offsite destination
* backup logging
* recovery verification
* documentation against the 3-2-1 backup principle

### 10. Time Synchronization

NTP was configured using chrony.

The lab focused on:

* NTP fundamentals
* stratum hierarchy
* synchronization state
* verification of the resulting time source

### 11. File Services & Transfer Protocols

The phase also includes practical work with:

* Samba
* NFS
* Samba vs NFS comparison
* FTP
* SFTP
* TFTP

The purpose was to understand the protocol and service differences rather than treat file sharing as a single generic feature.

### 12. System Auditing

The phase ended with a full VPS listener and service audit.

Every listening port and running service was evaluated against:

1. What is it?
2. Why does it need to exist?
3. What happens if it is removed?

The phase closed with a Lynis audit showing a hardening-index change from **66/100 to 69/100**, with the final measurement taken after the infrastructure cleanup.

## Key Accomplishments

* Built Apache2 web services and named virtual hosts
* Hardened Apache configuration and HTTP security headers
* Placed Nginx in front of the web stack
* Implemented TLS with Certbot and Let's Encrypt
* Added dynamic DNS automation
* Hardened SSH and added Fail2Ban
* Built layered OCI + host firewall controls
* Audited every VPS listener
* Removed unnecessary services
* Built BIND9 authoritative and recursive DNS
* Configured reverse DNS
* Built DHCP services and reservations
* Compared BIND9 and dnsmasq
* Deployed Nginx-based cloud backend routing
* Built HAProxy load balancing inside Hyper-V
* Created a working Active Directory domain
* Configured OUs and GPOs
* Tested LDAP directly
* Implemented and verified FGPP
* Automated nightly offsite backups
* Configured chrony/NTP
* Practiced Samba, NFS, FTP, SFTP, and TFTP
* Completed a system-wide Lynis audit

## What I Learned

The central lesson of Phase 3 was that **configuration is not verification**.

A firewall rule can look correct while another layer still blocks the traffic.

A service can appear internal while another networking layer exposes it.

A security policy can exist without actually being applied to the intended account.

A backup job can run successfully without proving that recovery works.

This phase repeatedly forced the same workflow:

> **Configure → observe → test → challenge the assumption → verify → document.**

That mindset became more important as the infrastructure became more interconnected.

## Labs

The directory structure below reflects the current repository rather than older lab names.

### Web & Proxy Infrastructure

* [`apache2/`](apache2/)
* [`apache2_virtualhost/`](apache2_virtualhost/)
* [`apache_hardening/`](apache_hardening/)
* [`nginx_load_balancing/`](nginx_load_balancing/)
* [`haproxy_load_balancing/`](haproxy_load_balancing/)
* [`dns_tls/`](dns_tls/)

### DNS & DHCP

* [`DNS_Labs/`](DNS_Labs/)
* [`isc-dhcp-server/`](isc-dhcp-server/)

### Access & Firewalling

* [`ssh_hardening/`](ssh_hardening/)
* [`ufw_firewall/`](ufw_firewall/)
* [`iptables/`](iptables/)
* [`port_audit_phase3/`](port_audit_phase3/)

### Active Directory

* [`active_directory_ldap/`](active_directory_ldap/)
* [`active_directory_ou_gpo/`](active_directory_ou_gpo/)
* [`active_directory_fgpp/`](active_directory_fgpp/)

### Operations & Infrastructure

* [`rsync-backup-automation/`](rsync-backup-automation/)
* [`ntp_protocol/`](ntp_protocol/)
* [`linux_disk_partitioning/`](linux_disk_partitioning/)

### File Services & Protocols

* [`samba_file_sharing/`](samba_file_sharing/)
* [`samba_vs_nfs/`](samba_vs_nfs/)
* [`nfs_protocol/`](nfs_protocol/)
* [`file_transfer_protocols/`](file_transfer_protocols/)

## Phase Status

**Phase 3 — Complete**

The infrastructure built here becomes the foundation for the next stage of the homelab.

**Next phase: Security.**

