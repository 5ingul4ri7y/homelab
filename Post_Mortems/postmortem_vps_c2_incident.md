# Post-Mortem: Simulated C2 Connection Detected by Suricata

**Date:** 11 October 2026
**System:** Oracle Cloud VPS (Ubuntu 24.04)
**Type:** Simulated incident, no real malware and no real attacker
**Detected by:** Suricata IDS
**Status:** Resolved

The setup and the step by step response, with screenshots, are in the incident response lab (Security/System_Hardening/incident_response). This document is the post-mortem for it.

## 1. Summary

On 11 October 2026 at 17:47 UTC, a disguised process on the VPS opened a connection to a known command and control (C2) address and Suricata raised an alert within seconds. I identified the process, blocked the address, collected evidence, removed the process and checked for persistence, all in under ten minutes. It was a planned simulation so nothing real was compromised and no data was lost, but it showed that the alert looked like routine background noise and that my detection only covered an address I already knew about.

## 2. Timeline

Times are server time (UTC) on 11 October 2026, taken from Suricata's fast.log, the process start times and file timestamps.

| Time | Event |
|------|-------|
| 17:46 | Fake C2 listener (PID 2408) started on 203.0.113.25 port 4444 |
| 17:47 | Disguised process `/tmp/.sysupdate.py` (PID 2425) started |
| 17:47:29 | Suricata fired rule sid 9000001 twice, one alert for each direction of the connection to 203.0.113.25:4444 |
| 17:48 | Alert confirmed in fast.log. `ss` showed the listener and the ESTABLISHED connection, and `ps` tied both ends to python3 processes running hidden scripts from /tmp |
| 17:49 | `/proc/PID/exe` showed both were the normal python3.12 interpreter. I then pulled the command lines, the parent PID (2359 for both) and the open files |
| 17:49 to 17:57 | Containment, evidence collection and eradication, in the order listed below |
| 17:58 | Audit log reviewed with `aureport --file`, the last entries in it were my own cleanup commands from 17:58:40 to 17:58:58 |

Between 17:49 and 17:57, in order:
1. Blocked outbound traffic to 203.0.113.25 with ufw
2. Attached `strace` to both processes to watch their network system calls, and saved the open files and memory map of PID 2408 to `/tmp/ir-lsof-evidence.txt` and `/tmp/ir-maps-evidence.txt`
3. Hashed the script with `sha256sum`
4. Checked cron, the shell startup files and systemd for "sysupdate", nothing was found
5. Killed both processes with `kill -9`, ran `pkill -f .c2listener.py` as a catch all, and deleted both scripts

Both `kill -9` commands succeeded, so both processes were still running when I killed them. They were set to sleep for ten minutes after connecting at 17:47:29, so eradication was done before 17:57:29, under ten minutes after the alert.

## 3. Root Cause

This was a planned exercise, so there was no real way in to find, I placed the process on the server myself. The useful question was what a real version of this would have relied on, and where the simulation showed gaps in how I detect and investigate. Three things stood out.

1. **The detection only knew what I told it.** The alert fired because I wrote a rule for 203.0.113.25 in advance. That is the same mechanism the known C2 rules in the Emerging Threats ruleset use, which is fine for known bad addresses, but it says nothing about a C2 server on an address nobody has listed yet.
2. **The alert was easy to ignore.** The rule had no `classtype` or priority, so it showed `Classification: (null)` and `Priority: 3`, the same as the routine "Misc activity" alerts that internet scanning produces all day. A confirmed C2 connection looked like background noise.
3. **The disguise worked on the surface.** A hidden dot-file script in /tmp run by the normal python3 interpreter shows up as just "python3" in `ps`, and `/proc/PID/exe` points at the legitimate interpreter. Only the command line gave it away.

## 4. Impact

There was no real impact. Nothing left the server, the C2 address is a reserved documentation address (TEST-NET-3) aliased onto the loopback interface, and both ends of the connection were scripts I wrote. The scripts only connected and waited, so no data was exchanged or lost. Nothing the web server or SSH depend on was touched during the response, the only changes to the system were one outbound firewall rule and the two processes and files I removed afterwards.

In numbers, it was 1 host, 2 processes and 1 TCP connection on port 4444, with an exposure window of at most ten minutes.

In a production environment this would be a host with an active command and control channel, where an attacker could send commands, steal data or move to other systems for as long as the connection stayed open. This server only holds lab material, so the data at risk is limited, but the admin account would still give full control of the machine, so I would rate the real equivalent as significant.

## 5. Resolution

1. Confirmed the alert with `sudo grep "C2" /var/log/suricata/fast.log | tail -5`.
2. Found the processes behind the connection with `sudo ss -tulnp | grep 4444` and `sudo ss -tnp | grep 203.0.113.25`, then inspected them with `ps aux`, `/proc/PID/exe`, `/proc/PID/cmdline`, `/proc/PID/status` and `sudo lsof -p PID`.
3. Contained before killing anything with `sudo ufw deny out to 203.0.113.25`, then attached `strace` and saved the `lsof` and `/proc/2408/maps` output as evidence.
4. Eradicated by hashing the script with `sha256sum`, checking for persistence with `grep` over cron and the shell startup files and `find` over /etc/systemd/ (nothing found), then `sudo kill -9 2425`, `sudo kill -9 2408`, `sudo pkill -f .c2listener.py` and `sudo rm /tmp/.sysupdate.py /tmp/.c2listener.py`.
5. Recovered by running an rkhunter scan, reviewing `sudo aureport --file`, removing the lab loopback alias with `sudo ip addr del 203.0.113.25/32 dev lo`, and removing the ufw rule because the lab was over (in a real incident that block would stay). I turned the lab rule into a permanent detection by removing the `LAB:` prefix from its message and reloading the rules with `sudo suricatasc -c ruleset-reload-rules`.

Verified by the `kill` commands succeeding, strace reporting both processes killed by SIGKILL and both strace jobs ending, no persistence found, and the audit report ending with only my own cleanup commands.

**What worked well:** Suricata alerted within seconds of the connection. `ss`, `ps`, `/proc` and `lsof` quickly tied the connection to the exact processes and scripts. Leaving the processes running until the evidence was collected meant nothing was destroyed. The UFW block would not have cut this particular connection (loopback, already established), which is a limit of the simulation. The auditd setup from the hardening sprint gave me an audit trail to review afterwards.

## 6. Prevention

1. **Make real C2 alerts loud.** Give the rule a `classtype` such as `trojan-activity` and a high priority so it stands out from background noise, and review fast.log by priority and not just by scrolling.
2. **Do not rely on known addresses alone.** Keep the Emerging Threats ruleset updating on a schedule so newly listed C2 addresses are picked up, and add host level checks for unusual outbound connections from non-service processes, such as a routine `ss` review or auditd or eBPF based telemetry, since a C2 on an unlisted address would not have triggered this rule.
3. **Review what runs out of /tmp.** The exec rule from the hardening sprint should already record the command line used to launch a process like this, so I should add a routine review of exec events whose arguments point into /tmp, where hidden scripts like this one tend to live.
4. **Limit outbound traffic.** Move toward a default-deny outbound policy that only allows what the server needs, such as package updates, DNS and certificate renewal, so a planted process cannot freely call out.
5. **Keep the response steps as a runbook.** Identify, contain before killing, collect evidence, eradicate, then recover, written down in the repo so the order is repeatable under pressure.
