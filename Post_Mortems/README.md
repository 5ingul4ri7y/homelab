# Post-Mortems

This folder collects write-ups of failures I hit while building out the homelab, once the root cause was actually understood rather than just patched. Each one follows the same format: summary, timeline, root cause, impact, resolution, and prevention.

The point of keeping these separately from the individual lab READMEs is that most of these failures cut across multiple labs (networking, sysadmin, and security touched all three of the ones below), so they don't cleanly belong to a single topic folder.

## Index

|Post-mortem|What broke|
|---|---|
|[OCI Default Firewall](postmortem_oci_default_firewall.md)|Server unreachable on 80/443 despite correct NSG rules, caused by Oracle's default OS-level iptables block|
|[DuckDNS IP Drift](postmortem_duckdns_ip_drift.md)|Domain stopped resolving after a reboot because the instance's public IP changed and DuckDNS was never told|
|[WireGuard FORWARD Chain](postmortem_wireguard_forward_chain.md)|Tunnel handshake succeeded but passed no traffic, caused by an appended FORWARD rule landing after Oracle's default REJECT|

