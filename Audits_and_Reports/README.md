# Audits and Reports

This directory tracks periodic security audits and reports run against my lab machines. Unlike the phase folders, which document building and configuring services, this is where I check in on the actual security posture of a machine after the fact. Think of it as the accountability layer sitting on top of everything else in this repo.

Each entry is its own folder, tagged with the tool used and the context it was run in. Every entry contains a README with the findings and reasoning, and an `assets/` subfolder with the raw scan output.

## Entries

- [lynis_mid_phase3](./lynis_mid_phase3/) — first full system Lynis scan, run mid phase 3 right after the Apache hardening lab
