
# Networking

This phase covers practical networking from the ground up: how packets move,
how names resolve, how traffic is inspected, and how to build real network
services on a live VPS. Labs are split between Cisco Packet Tracer simulations
and hands-on work on an Oracle Cloud VPS and real hardware.

---

## Structure


Networking/  
├── lab_setup/  
├── arp_lab/  
├── routing_and_dhcp/  
├── company_network_lab/  
├── dns_lab/  
├── dns_querying/  
├── more_dns/  
├── ping_traceroute_mtr/  
├── ip_and_ss/  
├── network_traffic_inspection/  
├── wireguard_vpn/  
└── squid_proxy/


---

## Labs

### [Lab Setup -- Router Workaround](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/lab_setup)

The ISP-issued router has locked firmware with no access to DHCP reservations,
DNS settings, or routing config. A spare TP-Link router was repurposed as a
LAN-side lab device by connecting it via LAN-to-LAN ethernet and reassigning
its admin IP to avoid a conflict with the main router. This gave full access
to a configurable network device without needing new hardware.

---

### [ARP Lab -- MAC vs IP, Switched LAN](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/arp_lab)

**Tool:** Cisco Packet Tracer

Observed ARP in a six-PC switched LAN. Watched the ARP cache start empty,
populate after a ping, and used simulation mode to confirm that ARP runs
before the first ICMP packet is ever sent. Demonstrated that ping does not
start with ICMP -- it starts with ARP.

Key concepts: ARP broadcasts vs unicast replies, dynamic cache entries, switch
MAC address table learning, Layer 2 vs Layer 3 addressing.

---

### [Routing and DHCP](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/routing_and_dhcp)

**Tools:** Cisco Packet Tracer + real TP-Link hardware

Configured a Cisco 1941 router from scratch in IOS: interface IPs, `no
shutdown`, DHCP pools with excluded addresses, verified bindings with `show ip
dhcp binding`. Replicated the same concepts on a real TP-Link router through
its admin panel, observing live DHCP lease assignments on connected devices.

Key concepts: router interfaces default to down, excluded addresses prevent
conflicts, DHCP pools are per-subnet, `show` commands for verification.

---

### [Company Network Capstone -- Subnetting, DHCP Server, DNS, Inter-subnet Routing](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/company_network_lab)

**Tool:** Cisco Packet Tracer

Capstone lab combining subnetting, centralised DHCP, DNS, and inter-subnet
routing. Subnetted `192.168.10.0/24` into three department subnets of
different sizes (two /26, one /27), configured a centralised DHCP and DNS
server on the IT subnet, set up `ip helper-address` relay on the router so
DHCP broadcasts from remote subnets reach the server, and verified cross-subnet
DNS resolution from a MANAGEMENT PC to an IT-hosted internal domain.

Key concepts: variable-length subnetting, centralised vs router-based DHCP,
`ip helper-address` for cross-subnet DHCP relay, DNS across subnets.

---

### [DNS Server Lab](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/dns_lab)

**Tool:** Cisco Packet Tracer

Set up a DNS server in Packet Tracer with A records and a CNAME alias,
excluded the server IP from the DHCP pool, updated the DHCP pool to hand out
the DNS server address, and verified resolution of all record types from client
machines. Tested NXDOMAIN response for a nonexistent domain to confirm the
server is properly authoritative.

Key concepts: A records vs CNAME aliases, excluding static IPs from DHCP,
DHCP and DNS dependency, `nslookup` as a verification tool.

---

### [DNS Querying on Linux](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/dns_querying)

**Environment:** Oracle Cloud VPS

Practical DNS querying using `dig`, `host`, `nslookup`, and `resolvectl`.
Queried A, MX, and NS records, used `@` to send queries directly to specific
resolvers, ran `+trace` to watch the full recursive resolution chain from root
servers down. Demonstrated `/etc/hosts` taking priority over DNS by overriding
`google.com` to a fake IP and observing the effect on `dig`, `ping`, and
`getent hosts`.

Key concepts: DNS record types, stub resolver vs authoritative server, hosts
file priority, systemd-resolved, TTL and caching, `resolvectl flush-caches`.

---

### [DNS Providers and Resolution Order](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/more-dns)

**Environment:** Oracle Cloud VPS

Compared query latency across Google (8.8.8.8), Cloudflare (1.1.1.1), and
Quad9 (9.9.9.9) using a shell script with `dig`. Tested Quad9's malicious
domain blocking by querying a known threat domain and observing NXDOMAIN.
Documented the full OS-level DNS resolution order (hosts file, local cache,
configured resolver) and built a six-step DNS failure diagnosis playbook.

Key concepts: DNS resolution order, provider differences, Quad9 threat
blocking, `resolvectl status`, systematic DNS troubleshooting.

---

### [Ping, Traceroute, and MTR](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/ping_traceroute_mtr)

**Environment:** Oracle Cloud VPS

Used `ping` for connectivity testing and latency comparison across DNS
resolvers using `awk` to extract timing fields. Used `traceroute` to map the
path to google.com and observed silent hops. Used `mtr` in both interactive
and report modes to collect per-hop statistics. Demonstrated the difference
between real packet loss and ICMP de-prioritization by intermediate routers.

Key concepts: ICMP echo, TTL-based path discovery, MTR columns (Loss%, StDev,
Wrst), intermediate hop loss vs end-to-end loss.

---

### [ip and ss](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/ip_and_ss)

**Environment:** WSL Ubuntu (to avoid locking out the VPS)

Used `ip addr`, `ip link`, and `ip route` to inspect interfaces, MAC
addresses, and the kernel routing table. Used `ip route get` to ask the kernel
exactly which route it would use for a specific destination. Used `ss -tuln`
to list listening TCP and UDP ports and `ss -tulnp` with sudo to identify the
process behind each socket.

Key concepts: Layer 2 vs Layer 3 interface info, routing table lookup, socket
statistics, identifying services by port.

---

### [Network Traffic Inspection -- curl, wget, tcpdump](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/network_traffic_inspection)

**Environment:** Oracle Cloud VPS

Used `curl` to fetch pages, save output, retrieve headers only with `-I`, and
trace the full TLS handshake with `-v`. Used `tcpdump` to capture HTTP traffic
on port 80 and read a complete server response in plaintext -- a direct
demonstration of why HTTPS is not optional. Captured DNS traffic on port 53 in
real time while running `dig` in a second terminal, and saved a packet capture
to a `.pcap` file for Wireshark analysis.

Key concepts: HTTP HEAD requests, curl verbose output (`*`, `>`, `<` prefixes),
plaintext HTTP exposure, DNS as observable UDP traffic, pcap files.

---

### [WireGuard VPN](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/wireguard_vpn)

**Environment:** Oracle Cloud VPS (server), Windows PC and Android phone (clients)

Built a full WireGuard VPN server on the VPS routing all client traffic
through it. Configured Oracle Cloud's two-tier firewall (OCI Network Security
Group and OS-level iptables) to allow UDP 51820. Generated key pairs,
configured the server with PostUp NAT and forwarding rules, and connected a
Windows client via the WireGuard desktop app and an Android phone via QR code.
Verified both clients simultaneously with `sudo wg show` showing two active
handshakes.

Encountered and resolved a post-handshake no-internet issue caused by Oracle's
default iptables FORWARD chain REJECT rule sitting above the ACCEPT rule added
by WireGuard's PostUp. Fix was inserting ACCEPT rules at position 1 with
`-I FORWARD 1` instead of appending with `-A`. Full incident log documented
for post-mortem.

Key concepts: WireGuard cryptography (ChaCha20, Diffie-Hellman), UDP-only
transport, public/private key peer authentication, NAT masquerade, iptables
rule ordering, QR code peer provisioning.

---

### [Squid Forward Proxy](https://github.com/5ingul4ri7y/homelab/tree/main/Networking/squid_proxy)

**Environment:** Oracle Cloud VPS (proxy server), Windows PC (client)

Deployed Squid as a forward proxy on the VPS, wrote a minimal config from
scratch restricting access to the VPN subnet and a specific PC IP. Configured
Oracle Cloud's two-tier firewall for TCP port 3128 -- NSG ingress rule locked
to the PC's /32 and an iptables INPUT rule for the same source. Connected
Windows via system proxy settings and verified all browser traffic was exiting
through the VPS. Monitored the Squid access log in real time with `tail -f`
and observed live proxied requests with full method, destination, and status
code visible per line.

Key concepts: forward vs reverse vs transparent proxy, ACL-based access
control, proxy-specific firewall scoping, Squid access log format, two-tier
firewall architecture on OCI.

---

## Environment Summary

| Environment | Used For |
|-------------|----------|
| Cisco Packet Tracer | ARP, routing, DHCP, DNS server, subnetting labs |
| Oracle Cloud VPS (Ubuntu 24.04) | DNS querying, ping/traceroute/mtr, ip/ss, curl/tcpdump, WireGuard server, Squid proxy |
| WSL Ubuntu | ip and ss lab (safe alternative to running on live VPS) |
| TP-Link router (real hardware) | DHCP observation, router admin panel |
| Windows 10 (local machine) | WireGuard client, Squid browser proxy, PowerShell verification |
| Android phone | WireGuard client via QR code |


---

