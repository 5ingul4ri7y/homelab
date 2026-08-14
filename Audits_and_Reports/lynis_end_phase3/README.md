# Lynis Report: End of Phase 3

**Tool:** Lynis

**Context:** Run at the end of Phase 3 (Sysadmin Infrastructure), after completing the service hardening labs

**Goal:** Establish a system-wide security baseline at the end of the sysadmin phase

## Why I ran this

At the end of Phase 3, I ran Lynis to get a system-wide view of where the machine stands after completing the infrastructure and service-hardening work throughout the phase.

Unlike the individual service audits performed during Phase 3, Lynis looks across the entire system. It checks areas such as system configuration, security controls, authentication, permissions, kernel-related settings, and other parts of the host security surface.

Running it at the end of the phase gives me a concrete baseline before moving into the dedicated Security phase.

## Result

![Lynis End of Phase 3 Report](assets/lynis_report_end_phase3.png)

* **Hardening index:** 69 / 100
* **Tests performed:** 270
* **Plugins enabled:** 1
* **Scan mode:** Normal
* **Firewall:** Detected
* **Malware scanner:** Not detected
* **Modules run:** Security audit, Vulnerability scan
* **Compliance status:** Not assessed at this stage


## My take

The final Phase 3 score of **69 / 100** is a useful baseline rather than a target I need to optimize immediately.

The score has improved from the earlier mid-phase baseline of **66 / 100**, while the number of tests performed also increased from 268 to 270. More importantly, this scan was performed after completing the broader Phase 3 infrastructure work, so it represents the state of the machine at the actual boundary between sysadmin infrastructure and the upcoming Security phase.

The scan also confirms that a firewall is present, while Lynis does not detect a malware-scanning component. There are therefore still security-related gaps, but they are not necessarily problems that need to be solved as part of the sysadmin phase itself.

I am deliberately **not treating the hardening index as a score to chase right now**. The purpose of Phase 3 was to build and harden the infrastructure, understand how services behave, troubleshoot them, and document the work. The deeper process of interpreting Lynis recommendations and systematically hardening the host belongs to the Security phase.

This report therefore acts as a **phase-end snapshot**: the machine has completed the sysadmin infrastructure work, and this is the security posture from which the dedicated security work will begin.

## Next steps — Security phase

* Go through the complete Lynis suggestions and warnings rather than focusing only on the hardening index
* Investigate the missing malware-scanning component and determine whether it is appropriate for the system
* Review authentication, permissions, kernel, networking, and service-level recommendations
* Apply security hardening systematically rather than making changes solely to increase the Lynis score
* Re-run Lynis after each major hardening round and document the changes
* Establish an actual security/compliance baseline before enabling or evaluating the compliance module
* Compare future Lynis results against this **end-of-Phase-3 baseline**

