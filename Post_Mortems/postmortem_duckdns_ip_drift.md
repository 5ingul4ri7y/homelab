# Post-Mortem: DNS Resolution Failure After Server Reboot (DuckDNS IP Drift)

## Summary
After a routine reboot of the Oracle Cloud file-server instance, `sohaib-lab.duckdns.org` stopped resolving to a working server, while direct access to the instance's public IP still worked fine. The domain was pointing at a stale IP left over from before the reboot, and there was no automation in place to refresh it. The site was unreachable by domain name until I manually resynced the DuckDNS record.

## Timeline
No logging or alerting was set up for this service at the time, so this is reconstructed in relative order rather than exact timestamps.

- Rebooted the Oracle Cloud file-server instance as routine maintenance.
- On restart, the instance's ephemeral public IP got reassigned by Oracle Cloud, since this instance wasn't configured with a reserved/static public IP.
- DuckDNS kept serving the last IP it had been told, which was now stale. There was no cron job or any other automation pushing IP updates to DuckDNS yet, so nothing corrected the record on its own.
- Tried reaching `sohaib-lab.duckdns.org` and got no response.
- Confirmed nginx was running and healthy on the instance, and that NSG ingress rules for ports 80 and 443 were unchanged and correct.
- Confirmed iptables on the instance was still correctly configured to allow inbound traffic on those ports.
- Tested access via the instance's public IP directly, and it worked fine. This isolated the problem to DNS specifically, since everything downstream of DNS was working.
- Compared the instance's actual current public IP against what `sohaib-lab.duckdns.org` was resolving to. They didn't match.
- Ran a manual `curl` against the DuckDNS update endpoint to force an immediate resync of the record.
- Added a cron job to push the same update every 5 minutes going forward, so any future IP change would self-correct without me having to catch it manually.

## Root Cause
The Oracle Cloud instance's public IP changed on reboot, and DuckDNS only reflects whatever IP was last explicitly pushed to its update API. This wasn't a short propagation delay. The record stayed stale permanently until something manually fixed it, because nothing was watching for the change.

The deeper issue is architectural, not a one-off mistake. This instance's networking was set up with an ephemeral public IP instead of a reserved one, and on Oracle's Always Free tier that's not guaranteed to persist across a reboot depending on configuration. On top of that, there was no automated DDNS update mechanism running, and no monitoring on the service to catch the outage quickly. DNS was the single entry point for every downstream layer that was otherwise fine (nginx, NSG, iptables), and I had no step in my reboot process that treated DNS resolution as something to re-check, the same way I'd check that a service came back up.

## Impact
This is a single lab-hosted site with no real external users, so the practical impact was limited to lost testing time and annoyance. But framed against a real deployment: this is the same failure mode behind a lot of "the site is down" incidents where every backend component is actually healthy and the outage is just a stale DNS record following an infrastructure change. In production, this could mean the service being unreachable by domain for hours rather than minutes, if there's no monitoring to flag it. Any links or integrations pointing at the domain would fail during that window even though the server itself never went down. No data was lost here, since only reachability by name was affected, not the service or its data.

## Resolution
Immediate fix: manually forced a resync of the DuckDNS record to the instance's current public IP.

```bash
curl "https://www.duckdns.org/update?domains=sohaib-lab&token=<your-token>&ip="
```

Leaving `ip=` blank lets DuckDNS auto-detect the caller's IP, which is the simplest option when running this from the server itself.

I verified by checking that `sohaib-lab.duckdns.org` resolved to the current instance IP and that the site was reachable by domain name again, matching what I'd already confirmed via direct IP access.

Permanent fix: scheduled the same update via cron every 5 minutes, so I don't have to catch this manually next time.

```bash
*/5 * * * * curl -s "https://www.duckdns.org/update?domains=sohaib-lab&token=<your-token>&ip=" >/dev/null 2>&1
```

This turns any future IP change into something that self-heals within minutes, instead of needing me to notice and fix it.

## Prevention
- The cron-based DuckDNS update is now standing infrastructure, not an optional convenience. I should check it's present any time this instance gets rebuilt or migrated.
- Where practical, prefer a reserved/static public IP over an ephemeral one for any Oracle Cloud instance that needs to stay reachable by a stable domain. That removes the root dependency instead of working around it.
- Treat DNS resolution as part of my standard post-reboot check for any publicly reachable lab service, alongside checking that the service process came back up. A quick `curl -I https://sohaib-lab.duckdns.org` after any reboot would have caught this immediately instead of it surfacing later.
- Since I'm the only one running this lab, favor self-correcting automation like the cron job here over manual detection, wherever a dependency can silently drift. There's no one else who'll notice and flag it for me.
