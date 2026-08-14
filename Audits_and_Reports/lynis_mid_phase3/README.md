# Lynis Report: Phase 3, Post Apache Hardening

**Tool:** Lynis
**Context:** Run mid phase 3 (sysadmin infrastructure), right after the Apache hardening lab
**Goal:** Get a system wide security baseline, not just an Apache specific one

## Why I ran this

Up to this point in phase 3 I had been hardening individual services one at a time, Apache being the most recent. That is useful but narrow. It tells me nothing about the overall state of the machine, things like kernel settings, file permissions, auth configuration, and all the other surface area a single service audit does not touch. Lynis does a full sweep of the system rather than one service, so I ran it to get an honest baseline before going further into the sysadmin phase.

## Result

![[assets/lynis_report_mid_phase3.png]]

- **Hardening index:** 66 / 100
- **Tests performed:** 268
- **Plugins enabled:** 1
- **Scan mode:** Normal
- **Modules run:** Security audit, Vulnerability scan (Compliance status not applicable at this stage)


## My take

66 is a reasonable starting point but it is nowhere near where I would want a production system to sit. The good news is that a lot of what is dragging the score down looks unrelated to Apache itself, the malware scanner component showing as not installed is one clear example. That means the Apache hardening work I already did is probably not being fairly represented in this single number, since Lynis is scoring the whole machine, not just the web server config.

I am deliberately not chasing this score up right now. Going deeper into hardening (kernel parameters, auth policies, closing out the flagged suggestions) is real Security phase work, not sysadmin phase work, and I want to keep phase boundaries honest rather than blur them just to make a number look better early. For now this report exists as a marker: this is where the system stood after Apache hardening, and it gives me something concrete to compare against once I actually get to the Security phase and start working through Lynis's suggestions one by one.

## Next steps (deferred to Security phase)

- Go through Lynis's suggestions list in full, not just the summary index
- Install and configure a malware scanner (rkhunter or similar) to close that specific gap
- Re-run Lynis after each round of hardening to track the index moving over time
- Eventually enable the compliance module once there is an actual baseline to check against
