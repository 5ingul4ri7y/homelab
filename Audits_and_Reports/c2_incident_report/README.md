# Incident Report: Suspicious Process + Outbound C2 Connection

**Date:** 11 October 2026
**Severity:** HIGH (rated as it would be for a real equivalent, this was a simulation)
**System:** Oracle Cloud VPS (Ubuntu 24.04)
**Status:** RESOLVED
**Type:** Simulated incident, a planned exercise with no real malware and no real attacker

## 1. Executive Summary

At 17:47 UTC on 11 October 2026, the intrusion detection system on the VPS (Suricata) alerted that a hidden program on the server had connected to an address on its list of known command and control (C2) servers. I identified the program within about a minute, blocked the address, collected evidence, then removed the program and confirmed nothing would bring it back. No data was affected. This was a planned simulation, so no real malware or attacker was involved, and the address used belongs to a reserved range that cannot reach a real machine.

**Resolution time:** under 10 minutes from detection to the program being removed, and about 11 minutes to the final audit review.

## 2. Timeline

Times are server time (UTC) on 11 October 2026, taken from Suricata's fast.log, the process start times and file timestamps.

| Time | Event |
|------|-------|
| 17:46 | Fake C2 listener (PID 2408) started on 203.0.113.25 port 4444 |
| 17:47 | Suspicious process `/tmp/.sysupdate.py` (PID 2425) started |
| 17:47:29 | Suricata alerted, rule sid 9000001 "LAB: outbound connection to known C2 IP". The connection produced two alert lines, one for each direction of the traffic |
| 17:48 | Alert confirmed in fast.log, which I was already watching live, so there was no notification delay. `ss` showed the listener and the ESTABLISHED connection, and `ps` tied both ends to hidden scripts running from /tmp. A CPU check showed nothing unusual |
| 17:49 | `/proc/PID/exe` showed both processes were the legitimate python3.12 interpreter. Command lines, the parent PID (2359 for both) and the open files were collected |
| 17:49 to 17:57 | Containment, evidence collection and eradication, in the order listed below |
| 17:58 | auditd reviewed with `aureport --file`, the last entries in it were my own commands from 17:58:40 to 17:58:58 |

Between 17:49 and 17:57, in order:
1. Blocked outbound traffic to 203.0.113.25 with ufw
2. Attached `strace` to both processes, and saved the open files and memory map of PID 2408 as evidence
3. Hashed the script with `sha256sum`
4. Checked cron, shell startup files and systemd for persistence, nothing found
5. Killed both processes, deleted both scripts

Both `kill -9` commands succeeded, so both processes were still running when I killed them. They were set to sleep for ten minutes after connecting at 17:47:29, so removal was done before 17:57:29.

## 3. Root Cause Analysis

**Entry point:** none. This was a planned exercise, I placed the process on the server myself, so there was no vulnerability to find and nothing to patch. The analysis below covers what a real equivalent would have relied on and why the detection and response had the gaps they did.

**Mechanism:** a hidden dot-file Python script in /tmp, run by the system's normal python3 interpreter, opened an outbound TCP connection to a C2 address. On the host, nothing stopped a local process from opening that connection.

**Contributing factors:**
1. The detection only knew what I told it. The alert fired because I had written a rule for 203.0.113.25 in advance, the same mechanism the known C2 rules in the Emerging Threats ruleset use. A C2 server on an address nobody has listed would not have triggered it.
2. The alert was easy to ignore. The rule had no `classtype` or priority, so it showed `Classification: (null)` and `Priority: 3`, the same as the routine "Misc activity" alerts that internet scanning produces all day.
3. The disguise worked on the surface. The process shows up as just "python3" in `ps` and `/proc/PID/exe` points at the legitimate interpreter, so only the command line gave it away.

A fuller, blameless discussion is in the post-mortem.

## 4. Impact Assessment

**Availability:** no impact. The scripts only slept, so CPU and network use did not change, and nothing the web server or SSH depend on was touched during the response.

**Data:** no data left the server. The C2 address is a reserved documentation address (TEST-NET-3) aliased onto the loopback interface, and the scripts only connected and waited, so no data was sent. The audit report I reviewed after the response showed only my own cleanup commands.

**Integrity:** no system files were modified by the incident. The changes were two scripts in /tmp, evidence files saved to /tmp, one loopback alias and one outbound firewall rule. The scripts, the alias and the firewall rule were removed during recovery.

**Reputation:** none, no traffic left the server. In a real incident the VPS IP could be used for attacks and end up on blocklists.

**Scope:** one host, 2 processes and 1 TCP connection on port 4444, with an exposure window of at most ten minutes. In a real incident the process would have whatever access the account running it has, and the admin account on this server gives full control of the machine, which is why I rate the real equivalent as HIGH. The server only holds lab material, so the data at risk would have been limited.

## 5. Response Actions Taken

**Containment:** blocked the C2 address with `sudo ufw deny out to 203.0.113.25`, before killing anything so the evidence was preserved.

**Evidence:** attached `strace` to both processes (`sudo strace -p 2425 -e trace=network &` and the same for 2408), saved `sudo lsof -p 2408` to `/tmp/ir-lsof-evidence.txt` and `/proc/2408/maps` to `/tmp/ir-maps-evidence.txt`, inspected `/proc/PID/cmdline`, `/proc/PID/status` and `lsof -p 2425`, and hashed the script with `sha256sum /tmp/.sysupdate.py`.

**Eradication:** checked cron, shell startup files and systemd for persistence (nothing found), then `sudo kill -9 2425`, `sudo kill -9 2408`, `sudo pkill -f .c2listener.py` and `sudo rm /tmp/.sysupdate.py /tmp/.c2listener.py`.

**Patching:** not applicable, there was no vulnerability, the process was planted for the exercise.

**Hardening:** turned the lab rule into a permanent detection by removing the `LAB:` prefix from its message and reloading the rules with `sudo suricatasc -c ruleset-reload-rules`.

**Recovery:** ran an rkhunter scan, reviewed `sudo aureport --file`, removed the lab loopback alias with `sudo ip addr del 203.0.113.25/32 dev lo`, and removed the ufw rule because the exercise was over (in a real incident that block would stay in place). Status set to resolved at 17:58.

The step by step walkthrough with screenshots is in the incident response lab README.

## 6. Recommendations

Owner for all items: me, as the only administrator. Timelines are targets.

**IMMEDIATE (before this incident is archived):**
1. Keep the C2 rule as a permanent detection, done.
2. Give the rule a `classtype` such as `trojan-activity` and a high priority so a confirmed C2 contact stands out from background noise.

**SHORT TERM (within 2 weeks):**
3. Set up an alert notification pipeline so high priority Suricata alerts reach me by email or chat within a minute, so detection does not depend on someone watching fast.log.
4. Keep the Emerging Threats ruleset updating on a schedule so newly listed C2 addresses are picked up.
5. Add a routine review of auditd exec events whose arguments point into /tmp, where hidden scripts like this one tend to live.

**MEDIUM TERM:**
6. Move toward a default-deny outbound policy that only allows what the server needs, such as package updates, DNS and certificate renewal.
7. Add host level checks for unusual outbound connections from non-service processes, such as a routine `ss` review or auditd or eBPF based telemetry, since a C2 on an unlisted address would not trigger the current rule.
8. Ship logs to a second system in real time so an intruder with root cannot tamper with them.
9. Keep the response steps as a runbook in the repo: identify, contain before killing, collect evidence, eradicate, then recover.

## Related Documents

- Incident response lab README [Incident Response LAB](https://github.com/5ingul4ri7y/homelab/tree/main/Security/System_Hardening/incident_response), setup, trigger and step by step response with screenshots
- Post-mortem: [Post-mortem report](https://github.com/5ingul4ri7y/homelab/blob/main/Post_Mortems/postmortem_vps_c2_incident.md) 
- VPS risk assessment : [Risk Assessment Document](https://github.com/5ingul4ri7y/homelab/blob/main/Audits_and_Reports/risk_assessment_vps)
