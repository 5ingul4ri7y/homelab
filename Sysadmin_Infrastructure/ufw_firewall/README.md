This block was added to `/etc/ufw/before.rules`, which contains rules that run before
UFW's own command-line-added rules are applied. The custom NAT table here performs
source NAT (masquerading) on traffic originating from the WireGuard subnet
(`10.0.0.0/24`) as it leaves through `ens3`.

Without this, WireGuard clients would have packets with their internal VPN IP as the
source address, which the wider internet has no route back to. Masquerading rewrites
the source address to the VPS's public IP for outbound packets and reverses the
translation for the return traffic, the same NAT mechanism that lets an entire home
network share one public IP. This is the functional equivalent of the iptables `nat`
table rules and is what allows the VPS to act as a proper VPN gateway rather than just
a routing relay.

![rules.before file showing the NAT masquerade rule for WireGuard](assets/ufw6.png)

## Conclusion

UFW trades iptables' fine-grained control for speed and readability. For a VPS where
the firewall needs are well understood and don't require complex chains or custom
matching logic, UFW is fast to configure correctly and easy to audit later by reading
`ufw status verbose`. It is a reasonable choice for production servers where
simplicity reduces the chance of a misconfiguration, though iptables (or nftables)
remains the better tool when more granular control is needed.
