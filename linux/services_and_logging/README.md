# Services and Logging - systemctl + journalctl

This covers how Linux manages background services using systemd, and how to read logs with journalctl. The practical side was building a custom service from scratch that runs a health logger on the VPS.

---

# systemctl

systemd is the init system on modern Linux distros. It's what starts, stops, and manages background services (called units). `systemctl` is how you interact with it.

Core commands:

- `systemctl start <service>` - starts a service
- `systemctl stop <service>` - stops a service
- `systemctl enable <service>` - makes the service start automatically on boot
- `systemctl enable --now <service>` - enables and starts it in one step
- `systemctl disable <service>` - removes it from boot
- `systemctl status <service>` - shows current state, recent logs, and PID
- `systemctl daemon-reload` - required after creating or editing a unit file, tells systemd to re-read its config

---

# Building a Custom Service

The goal was to write a shell script that logs system health every 60 seconds, then wrap it in a proper systemd service so it runs in the background automatically.

## Step 1 - Write the script

```bash
sudo tee /usr/local/bin/labhealth.sh << 'EOF'
#!/bin/bash
while true; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') | uptime: $(uptime -p) | load: $(cat /proc/loadavg | cut -d' ' -f1-3)" >> /var/log/labhealth.log
  sleep 60
done
EOF
sudo chmod +x /usr/local/bin/labhealth.sh
```

The script runs in an infinite loop, appending a timestamped line to `/var/log/labhealth.log` every 60 seconds. The line includes uptime and the 1/5/15 minute load averages pulled from `/proc/loadavg`.

`tee` writes the content to the file while also printing it to stdout. The `<< 'EOF'` syntax is a heredoc, it lets you pass a block of text as input to a command.

## Step 2 - Create the service unit file

```bash
sudo tee /etc/systemd/system/labhealth.service << 'EOF'
[Unit]
Description=Lab Health Logger
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/labhealth.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

Unit files live in `/etc/systemd/system/`. Breaking down the sections:

- `[Unit]` - metadata and dependency ordering. `After=network.target` means it starts after networking is up.
- `[Service]` - defines how to run it. `Type=simple` means systemd treats the process itself as the service. `Restart=on-failure` means systemd will restart it automatically if it crashes.
- `[Install]` - defines when it should run. `WantedBy=multi-user.target` means it starts in normal multi-user mode, which is the standard runlevel for a server.

## Step 3 - Load and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now labhealth
systemctl status labhealth
```

![labhealth service status|221](images/labhealth-status.png)

After running this, the service should show as `active (running)` in the status output.

## Step 4 - Confirm it is logging

```bash
tail -f /var/log/labhealth.log
```

![labhealth log output|172](images/labhealth-log.png)

`tail -f` follows the file in real time, printing new lines as they are written. Each line should appear roughly every 60 seconds with the timestamp, uptime, and load average.

---

# journalctl

journalctl reads logs from the systemd journal. Every service managed by systemd writes its stdout/stderr there automatically.

Useful commands:

- `journalctl -u <service>` - shows all journal entries for a specific service
- `journalctl -u <service> -f` - follows the journal live, like `tail -f` but for systemd
- `journalctl -u <service> --since "1 hour ago"` - limits output to a time range
- `journalctl -xe` - shows recent entries with extra context, useful when a service fails to start
- `journalctl --disk-usage` - shows how much space the journal is using

![journalctl output for labhealth|281](images/labhealth-journal.png)

The journal is useful alongside the log file because it also captures startup errors, crashes, and restarts that the script itself would never write to the log.

---

# Environment

- Platform: Oracle Cloud VPS
- OS: Ubuntu (Linux)
- Access: SSH from local machine
