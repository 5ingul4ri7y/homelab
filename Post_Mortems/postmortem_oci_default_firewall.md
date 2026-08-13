# Post-Mortem: Server Unreachable Despite Correct NSG Rules (OCI Default iptables Block)

## Summary
I created a Network Security Group (`fileserver-nsg`) with correct ingress rules for ports 80 and 443 and attached it to the file server instance. The server was still unreachable from outside on both ports. The NSG config was correct the whole time. The actual block was a second firewall at the OS level, iptables, which ships enabled by default on Oracle's stock Ubuntu images and had never been opened for these ports.

## Timeline
I didn't have logging in place at this point, so timestamps are approximate and reconstructed after the fact.

- Created `fileserver-nsg` with ingress rules allowing TCP 80 and TCP 443 from 0.0.0.0/0.
- Attached the NSG to the instance's VNIC.
- Tried reaching the server from outside on both ports. Both timed out.
- Went back into the OCI console and checked everything again: NSG attached correctly, rules present exactly as configured, subnet Security List not adding any conflicting deny. Everything at the console level looked fine.
- Re-checked the NSG rules a second time, assuming I'd missed something. My working assumption at this point was that the cloud-level firewall is the only thing standing between the internet and the instance, which is how it works on other providers I'd used before.
- Shifted from the console to the instance itself and ran `iptables -L -n` to check the OS-level firewall state.
- Found that the iptables INPUT chain was blocking inbound traffic on ports 80 and 443 by default, completely independent of what the NSG allowed.
- Root cause identified: Oracle's stock Ubuntu images ship with iptables pre-configured to block inbound traffic at the OS level. This is a second layer, separate from and in addition to NSG/Security List rules at the cloud level.
- Added explicit ACCEPT rules for TCP 80 and 443, made them persistent, and re-tested from outside. Server became reachable on both ports.

## Root Cause
Oracle's stock Ubuntu images include a pre-configured iptables ruleset that blocks inbound traffic by default at the OS level, independent of whatever the NSG or Security List allows at the cloud network level. It's a genuine two-layer firewall: both the cloud layer and the OS layer have to independently allow a port before traffic actually reaches the application.

The real reason this took as long as it did is that I was carrying over a mental model from other cloud providers. On AWS, GCP, and Azure, the default OS images generally ship with an open OS-level firewall, so the cloud security group is the only real gatekeeper in practice. That experience made me assume a correctly configured NSG was sufficient. Oracle breaks that assumption silently. There's no warning or console indicator that a second firewall layer exists and is active. From the outside, the failure looks identical to a misconfigured NSG (connection just times out), which is exactly why I kept re-checking console rules that were already correct instead of checking the instance's own firewall.

## Impact
This was a single-operator lab deployment during initial setup, so the actual impact was lost time, nothing else. But it's worth framing against a real deployment: this is the exact failure mode that would make a freshly provisioned production service look completely down on launch day, even though every cloud-console setting was verified correct, because the block is invisible from the console. That's the kind of thing that burns the first, most valuable minutes of an incident on the wrong debugging path. No data was at risk here, since this was purely an inbound reachability issue.

## Resolution
Opened the same ports at the OS level with iptables, on top of the NSG rules already in place:

```bash
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```

iptables rules don't survive a reboot by default, so I made them persistent:

```bash
sudo netfilter-persistent save
```

I verified by re-testing from outside the network after applying and saving these rules. The server was reachable on both ports, confirming traffic was now clearing both the NSG and the OS-level firewall.

## Prevention
- Treat Oracle Cloud as a two-layer firewall system by default. Any newly exposed port needs to be opened in the NSG/Security List at the cloud level *and* in iptables at the OS level. Neither one alone is enough.
- Whenever I expose a new service on an OCI instance, run `iptables -L -n` as a standard step right after configuring the NSG, before spending time re-verifying console rules that are probably already fine.
- Document this OCI-specific behavior directly in the homelab repo's setup notes, so future services (and future re-reads of my own past setup steps) start from the right mental model instead of the one I brought over from other providers.
- If a newly deployed service is unreachable and the cloud console shows everything as correctly configured, treat that as the signal to check the instance's own OS-level firewall next, rather than re-checking the same console settings again.
