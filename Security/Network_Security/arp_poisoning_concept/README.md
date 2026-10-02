# ARP Poisoning - Concept and Defence

ARP, Address Resolution Protocol, is what maps IP addresses to MAC addresses on a local network. The problem is that ARP has no authentication built in at all, any device on the network can claim to be any IP it wants, and everyone else just believes it. ARP poisoning is the attack that exploits exactly that, it lets an attacker sit in the middle of traffic between two hosts on the same switched network without either of them noticing.

## How the attack actually unfolds

Normally, if VM1 (192.168.56.101) wants to talk to VM2 (192.168.56.102), it checks its ARP cache first, asking "what MAC address is .102?" Once it has an answer, traffic flows directly between VM1 and VM2, no middleman involved.

An attacker, Kali in this case, poisons that process by sending gratuitous ARP replies that nobody asked for. Kali tells VM1 "I am 192.168.56.102, and my MAC is Kali's MAC", and separately tells VM2 "I am 192.168.56.101, and my MAC is Kali's MAC" as well. Since ARP has no authentication, both VMs just accept these unsolicited replies and update their caches accordingly.

At this point both ARP caches are poisoned. VM1's cache now points 192.168.56.102 at Kali's MAC instead of VM2's real one, and VM2's cache points 192.168.56.101 at Kali's MAC instead of VM1's real one. Both machines now genuinely believe Kali is the other machine.

This is where the man-in-the-middle position actually gets established. When VM1 sends a packet meant for VM2, it actually goes to Kali first. Kali reads it, can modify it if it wants to, and then forwards it on to the real VM2. The same happens in reverse for VM2's replies. Both VMs think they are talking directly to each other the whole time, but every single packet is passing through Kali first, who sees everything.

## Defending against it

There are a few ways to actually stop this. On managed switches, Dynamic ARP Inspection validates incoming ARP replies against DHCP snooping tables, so a poisoned reply claiming to be an IP it was never actually assigned gets dropped before it can do any damage. Static ARP entries are another option, since a statically configured mapping simply cannot be overwritten by a poisoned reply.

The approach that matters most for a home lab or any untrusted network though is just encrypting the traffic itself. A WireGuard VPN encrypts everything before it ever touches the local network, so even if Kali successfully poisons the ARP caches and intercepts every single packet, all it gets is unreadable encrypted frames. The interception still happens, Kali is still sitting in the middle, but it no longer matters because there is nothing readable left to steal.

## ARP poisoning effect by traffic type

| Traffic type | What ARP poisoning gets the attacker | Result |
|---|---|---|
| Unencrypted HTTP | Reads and intercepts all data | Complete compromise |
| HTTPS | Intercepts the encrypted stream | Traffic visible, but unreadable |
| WireGuard / VPN | Intercepts the encrypted tunnel | Cannot decrypt or tamper |
| SSH | Sees the encrypted session | Cannot read without the private key |

The pattern here is consistent with everything from the earlier crypto labs, ARP poisoning only ever gives an attacker a position on the wire, it does not break encryption on its own. Whether that position is actually worth anything to the attacker depends entirely on whether the traffic passing through it was protected in the first place.

This is exactly why a VPN like WireGuard matters on any network I do not fully trust, hotel wifi, a coffee shop, a conference. Tunneling traffic through WireGuard encrypts it before it ever reaches the local network, so even a successful ARP poisoning attack only nets the attacker encrypted frames with nothing usable inside them.
