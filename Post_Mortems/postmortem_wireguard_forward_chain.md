# Post-Mortem: WireGuard Tunnel Established but No Internet Access (FORWARD Chain Rule Order)

## Summary
I set up a WireGuard tunnel between the Oracle Cloud VPS (`neo-1`) and a Windows client. The handshake completed successfully, but no traffic passed through. The client could connect but had no internet access and no DNS resolution through the tunnel. This was broken for the entire duration of my initial WireGuard deployment on this host, until I fixed the FORWARD chain rule order.

## Timeline
No logging was in place at the time since this was initial lab setup, so this is reconstructed from memory in relative order.

- Deployed the WireGuard server and client configs. `wg-quick up wg0` brought the interface up with no errors.
- Connected from the Windows client. The WireGuard UI showed a successful handshake with bytes transferred in both directions.
- Ran `curl ifconfig.me` from the client as a first connectivity test. It failed with `curl: (6) Could not resolve host: ifconfig.me`. DNS through the tunnel was also failing.
- First guess: assumed the Oracle Cloud Security List was blocking UDP 51820. Checked the console and confirmed the ingress rule for UDP was present and correct. Ruled this out, since the handshake completing already proved packets were reaching the VPS.
- Second guess: assumed the iptables INPUT chain was blocking WireGuard packets. Added an explicit `INPUT ACCEPT` rule for UDP 51820. Handshake still worked as before (it already had been), and internet access was still broken. Ruled out INPUT as the blocker.
- Confirmed IP forwarding was enabled (`net.ipv4.ip_forward = 1`) and that a MASQUERADE rule existed in POSTROUTING. Both correct, both ruled out.
- Checked the FORWARD chain directly with `iptables -L FORWARD -v -n --line-numbers` and found a default Oracle-provided `REJECT` rule sitting at position 1, with the WireGuard `PostUp` ACCEPT rule appended after it at a lower position.
- Root cause identified: the rule had been appended (`-A`) instead of inserted (`-I`) into a chain that already had a REJECT rule ahead of it.
- Fixed by re-inserting the FORWARD ACCEPT rules at the top of the chain with `-I`. Verified with a fresh `curl ifconfig.me` from the Windows client, which returned the VPS public IP. Made the rules persistent with `iptables-persistent`.

## Root Cause
The WireGuard `PostUp` script used `iptables -A FORWARD -i wg0 -j ACCEPT`, which appends a rule to the end of the FORWARD chain. iptables evaluates rules top to bottom and stops at the first match. Oracle Cloud's stock Ubuntu 24.04 image ships with a default FORWARD chain that already has a `REJECT` rule at position 1:

```
Chain FORWARD (policy ACCEPT)
target    prot opt source       destination
REJECT    0    --   0.0.0.0/0   0.0.0.0/0   reject-with icmp-host-prohibited
ACCEPT    0    --   0.0.0.0/0   0.0.0.0/0
```

Any rule appended after that REJECT is dead on arrival for the traffic it's meant to allow, since the REJECT rule matches first and stops the chain there.

The deeper issue wasn't really the `-A` vs `-I` typo itself, it was that I had no step in my setup process that verified the actual effective rule order after deployment (`iptables -L -v -n --line-numbers`). I hadn't fully internalized the `-A` vs `-I` distinction at this point in my iptables learning curve, and I was treating "the tunnel handshakes" and "the tunnel forwards traffic" as the same thing, when they're two separate things that both need checking. A working handshake only proves UDP 51820 reachability and key exchange are fine. It says nothing about whether the FORWARD chain actually lets the resulting traffic through.

## Impact
This was a single-operator home lab with one test client, so there was no real user-facing impact. But framed against a real deployment: this is the exact failure mode that would silently take down a site-to-site or remote-access VPN for an entire team. The tunnel would report healthy in any monitoring that only checks handshake status, which is the most common shallow WireGuard health check, while everyone behind it silently loses access to internal resources and the internet. In an org, this usually shows up first as a wave of "VPN connects but nothing works" tickets, which is a much more expensive way to find a rule-ordering bug than a single verification command would have been.

## Resolution
Re-inserted the FORWARD ACCEPT rules at the top of the chain instead of appending them:

```bash
sudo iptables -I FORWARD 1 -i wg0 -j ACCEPT
sudo iptables -I FORWARD 2 -o wg0 -j ACCEPT
```

Resulting chain order after the fix:

```
1. ACCEPT  -- wg0 inbound
2. ACCEPT  -- wg0 outbound
3. REJECT  -- Oracle default (now unreachable for wg0 traffic)
4. ACCEPT  -- Oracle default
```

Made the rules persistent across reboots:

```bash
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

I verified by running `curl ifconfig.me` through the tunnel from the Windows client. It returned the VPS's public IP, confirming traffic was correctly routed and NATed through wg0.

## Prevention
- Never assume a completed WireGuard handshake means the tunnel actually works end to end. Handshake status and traffic forwarding are two separate checks, and I need to verify both after every deployment.
- After any change to iptables FORWARD, INPUT, or NAT rules, run `iptables -L -v -n --line-numbers` and read the chain top to bottom before calling the change done. Rule position matters as much as rule content.
- On Oracle Cloud specifically, treat the default FORWARD REJECT rule as a known constant. Any service on an OCI instance that needs IP forwarding (VPN, routing, NAT, container bridge networking) needs its ACCEPT rules inserted ahead of that REJECT with `-I`, not appended with `-A`.
- Add a one-line connectivity check (`curl ifconfig.me` or equivalent through the tunnel) as a standard last step of any VPN deployment in this repo, so this class of failure gets caught before I consider the deployment done, instead of turning up in a later debugging session.
