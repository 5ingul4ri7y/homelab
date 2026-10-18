# Phase 2 - Networking: From Packets to Services

## What I Built

A set of networking labs split across Cisco Packet Tracer, real hardware and an Oracle Cloud VPS: a switched LAN and a routed three-department company network (centralised DHCP and DNS), a spare TP-Link router turned into a configurable LAN lab device, Linux DNS and traffic inspection work, a WireGuard VPN server with two clients, and a Squid forward proxy locked to a single source IP.

## Key Accomplishments

- [x] Worked around an ISP-locked router by connecting a spare TP-Link LAN-to-LAN and moving its admin IP from `192.168.1.1` to `192.168.1.2` to avoid a conflict
- [x] Proved ping starts with ARP, not ICMP: empty cache, then `arp -a` showing a dynamic entry after the ping, with Simulation mode showing the ARP broadcast at t=150.025 and the first ICMP packet at t=150.029
- [x] Configured a Cisco 1941 from scratch in IOS (interfaces, `no shutdown`, DHCP pools, excluded addresses) and verified it with `show ip dhcp binding`, then repeated the same DHCP concepts on the real TP-Link router
- [x] Subnetted `192.168.10.0/24` into two /26 subnets and one /27, with a centralised DHCP and DNS server reached across subnets via `ip helper-address 192.168.10.70`
- [x] Verified cross-subnet DNS resolution of `intranet.company.local` from a MANAGEMENT PC (`nslookup`)
- [x] Built a Packet Tracer DNS server with A records and a CNAME, and confirmed an NXDOMAIN for a nonexistent name (`nslookup doesntexist.lab`)
- [x] Queried A, MX and NS records, traced recursive resolution from the root servers (`dig +trace google.com`), and proved `/etc/hosts` overrides DNS by pointing `google.com` at a fake IP
- [x] Compared Google, Cloudflare and Quad9 resolvers with a `dig` loop (3 ms vs 2 ms vs 2 ms from the VPS) and wrote a six-step DNS failure diagnosis playbook
- [x] Told real packet loss from ICMP de-prioritisation with `mtr -n --report --report-cycles 10` (90% and 20% loss at intermediate hops, 0% at the destination)
- [x] Captured plaintext HTTP and live DNS queries with `sudo tcpdump -i ens3 -n -A port 80` and `port 53`, and saved a `.pcap` for Wireshark
- [x] Deployed a WireGuard server on the VPS and connected a Windows PC and an Android phone at the same time (`sudo wg show` showed two active handshakes)
- [x] Fixed a post-handshake no-internet failure caused by Oracle's default FORWARD REJECT rule sitting above the ACCEPT rule, by inserting the rules at the top with `-I FORWARD 1` (see [post-mortem](../Post_Mortems/postmortem_wireguard_forward_chain.md))
- [x] Deployed Squid as a forward proxy with a minimal from-scratch config, ACL-restricted to the VPN subnet and one PC, with an OCI NSG rule locked to that PC's /32

## Technologies Used

| Tool | Purpose | Evidence |
|---|---|---|
| Cisco Packet Tracer | ARP, routing, DHCP, DNS and subnetting simulations | [arp_lab/](arp_lab/README.md), [routing_and_dhcp/](routing_and_dhcp/README.md), [company_network_lab/](company_network_lab/README.md), [dns_lab/](dns_lab/README.md) |
| Cisco IOS CLI | Router interfaces, DHCP pools, DHCP relay | `.pkt` files in each lab's `assets/` |
| TP-Link router | Real-hardware DHCP and a configurable lab device | [lab_setup/](lab_setup/README.md) |
| dig, host, nslookup, resolvectl | DNS querying and resolver inspection | [dns_querying/](dns_querying/README.md), [more-dns/](more-dns/README.md) |
| ping, traceroute, mtr | Connectivity, path discovery, loss analysis | [ping_traceroute_mtr/](ping_traceroute_mtr/README.md) |
| ip, ss | Interfaces, routing table, listening sockets | [ip_and_ss/](ip_and_ss/README.md) |
| curl, wget, tcpdump | HTTP inspection and packet capture | [network_traffic_inspection/](network_traffic_inspection/README.md) |
| WireGuard | VPN server with Windows and Android clients | [wireguard_vpn/](wireguard_vpn/README.md) |
| Squid | Forward proxy with ACLs and access logging | [squid_proxy/](squid_proxy/README.md) |
| OCI NSG and iptables | Two-tier cloud and OS firewalling | [wireguard_vpn/](wireguard_vpn/README.md), [squid_proxy/](squid_proxy/README.md) |

## Key Learnings

Troubleshooting works best from the bottom of the stack up. ARP has to succeed before ICMP can be sent, and the DNS failure playbook starts by pinging a raw IP before blaming DNS. The same idea showed up in MTR: loss at one intermediate hop means nothing if the destination shows 0%, because routers often de-prioritise ICMP while still forwarding real traffic.

Oracle Cloud has two independent firewalls (the NSG in the cloud and iptables in the OS), and a rule in one does nothing for the other. The WireGuard incident also showed that iptables order matters: an ACCEPT rule appended below a REJECT is never reached. Finally, `tcpdump` on port 80 showed a full server response in plaintext, which made the case for HTTPS better than any explanation.

## Files in This Directory

| Folder | Description |
|---|---|
| [lab_setup/](lab_setup/README.md) | TP-Link LAN-to-LAN workaround for the ISP-locked router |
| [arp_lab/](arp_lab/README.md) | ARP cache and simulation-mode event list in a switched LAN |
| [routing_and_dhcp/](routing_and_dhcp/README.md) | Cisco 1941 routing and DHCP, plus real TP-Link DHCP |
| [company_network_lab/](company_network_lab/README.md) | Capstone: subnetting, central DHCP and DNS, helper-address relay |
| [dns_lab/](dns_lab/README.md) | Packet Tracer DNS server with A and CNAME records |
| [dns_querying/](dns_querying/README.md) | dig, host, nslookup, resolvectl and the hosts file override |
| [more-dns/](more-dns/README.md) | Resolver comparison, resolution order, DNS failure playbook |
| [ping_traceroute_mtr/](ping_traceroute_mtr/README.md) | Latency, path mapping and reading MTR loss correctly |
| [ip_and_ss/](ip_and_ss/README.md) | Interfaces, routes and listening sockets (done on WSL) |
| [network_traffic_inspection/](network_traffic_inspection/README.md) | curl, wget and tcpdump captures |
| [wireguard_vpn/](wireguard_vpn/README.md) | WireGuard server, two clients, FORWARD chain fix |
| [squid_proxy/](squid_proxy/README.md) | Squid forward proxy with two-tier firewall scoping |
