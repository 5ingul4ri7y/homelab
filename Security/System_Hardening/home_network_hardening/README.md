# Browser and Home Network Hardening

Security doesn't stop at the server. My local machine and home network are part of my attack surface too, since every SSH session into the VPS starts from here. This lab covered hardening my browser, understanding why DNS over HTTPS matters, and auditing my home network the way an attacker would see it. It was done on my own browser and my actual home network, so there are no screenshots for this one.

## Browser Hardening

Most of these are quick changes. The real point was to go and verify each setting instead of assuming the defaults were fine.

**HTTPS-Only mode**
I turned on HTTPS-Only mode by setting `dom.security.https_only_mode` to true in `about:config`. With this on, the browser refuses to load plain HTTP pages and shows a warning instead of silently loading them. This matters because plain HTTP can be read and changed by anyone sitting in the path of the traffic, which is exactly what the ARP poisoning and plaintext FTP labs showed, an attacker in the middle sees everything.

**DNS over HTTPS**
I set DNS over HTTPS to Max Protection under Settings, Privacy and Security. Max Protection means the browser only uses the secure resolver and does not quietly fall back to regular DNS if it fails. The reasoning behind this one is in its own section below.

**Third-party cookies**
Blocking third-party cookies prevents cross-site tracking. Firefox does this by default, but I verified it was actually on rather than assuming.

**Enhanced Tracking Protection**
Set to Strict mode (or the equivalent in Chrome).

**Camera and microphone access**
Sites can't access the camera or microphone without explicit permission, which is already the default. I checked that I hadn't overridden it anywhere.

### Extensions

**uBlock Origin**
Blocks ads, trackers, and malvertising, which are ads used to deliver malware. It is the most impactful single extension, and blocking ads ends up being a security measure and not just a convenience.

**Reviewing installed extensions**
I went through every installed extension and checked that I recognised each one. Malicious extensions exist even in official stores, and an extension with broad permissions can read everything on the pages you visit, so anything I don't recognise should not be there.

**Password manager**
I use a password manager to generate a unique password for every site. That way a breach on one site doesn't hand over my credentials for any other.

## DNS over HTTPS - Why It Matters

Without DoH, my ISP can see every DNS query I make, even for sites that use HTTPS. HTTPS only protects the content of the connection itself. The DNS lookup happens before that and in plaintext, so the domain I am about to visit is visible to anyone on the path. DoH encrypts the query to the resolver. It is worth remembering that this moves the trust and doesn't remove it, the DoH resolver now sees my queries instead of the ISP.

The one item I haven't ticked off from the checklist is configuring system-wide DoH through the BIND9/dnsmasq resolver on my VPS, so every device using it as a resolver benefits and not just the browser. It is a low priority follow up.

## Home Network Security Audit

I audited my home network from an attacker's perspective, using nmap from Kali. Three scans, each more detailed than the last.

Discover all devices on the network:
`sudo nmap -sn 192.168.1.0/24`
This is a ping sweep. `-sn` skips the port scan entirely and just finds which hosts are alive. The CIDR should be replaced with your own home network's range.

Service detection on open ports:
`sudo nmap -sV --open 192.168.1.0/24`
`-sV` probes each open port to identify the service and version running on it, and `--open` filters the output down to only hosts and ports that are actually open, which cuts a lot of noise.

Detailed scan of the router:
`sudo nmap -sV -sC 192.168.1.1`
`-sC` runs nmap's default scripts on top of version detection, which pull extra information like banners and page titles. The router is the most important device on the network, so it gets its own detailed scan.

The common finding that applied to my network was ports 80 and 443 open on the router, which is just its web admin interface. That is expected, but it is also why the admin password and who can reach that interface matter so much.

### Router security checklist

- **Admin password changed from the default.** Default credentials for router models are published online, so anyone who can reach the login page can try them.
- **Admin interface not accessible from WAN.** Otherwise anyone on the internet can reach the login page and attempt to get in.
- **WPS disabled** (Settings, WiFi, WPS, Off). The WPS PIN attack is fast and effective, so there is no reason to leave it on.
- **DHCP lease table reviewed for unknown devices.** The lease table shows every device the router has handed an address to. It pairs well with the ping sweep, since that shows what is live right now, and anything that appears in one but not the other is worth a second look.

The WPS and WAN admin access items were also covered in the wireless security lab when I moved the router to WPA3.

## Conclusion

The server is only one end of the connection. The browser I use to reach it and the network it sits behind both matter, so hardening them closes gaps that no amount of server hardening would cover.
