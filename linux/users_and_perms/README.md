# SSH & Linux Permissions - Lab Drill

> **Day 3 Lab** | Practiced on an Oracle VPS (Ubuntu)  
> Goal: Understand Linux user roles, file permissions, and access control by intentionally triggering `Permission denied` errors.

---

## Objective

The point of this drill wasn't just to run commands. It was to actually **see the OS refuse access** and understand *why*. Every `Permission denied` error was the lesson working as intended.

---

## What I Practiced

### Step 1 | Created Three Users with Different Roles

| User | Type | Capability |
|---|---|---|
| `labuser_a` | Regular user | Can log in, no sudo |
| `labadmin` | Admin user | Can log in, has sudo |
| `webservice` | Service account | Cannot log in interactively (`nologin`) |

```bash
# Regular user — can log in, no sudo
sudo useradd -m -s /bin/bash -c "Lab User Alpha" labuser_a
sudo passwd labuser_a

# Admin user — can sudo
sudo useradd -m -s /bin/bash -c "Lab Admin" labadmin
sudo passwd labadmin
sudo usermod -aG sudo labadmin

# Service account — no interactive login
sudo useradd -r -s /usr/sbin/nologin -c "Web Service" webservice

# Group setup
sudo groupadd developers
sudo usermod -aG developers labuser_a
```

**Key flags learned:**
- `-m` creates the home directory
- `-s /bin/bash` assigns the login shell
- `-r` marks it as a system/service account
- `-s /usr/sbin/nologin` blocks interactive login
- `-aG` appends to a group without removing existing memberships

---

### Step 2 | Created Files with Controlled Permissions

```bash
# Create a restricted file owned by root
sudo touch /etc/lab_secret.txt
sudo chmod 600 /etc/lab_secret.txt
sudo chown root:root /etc/lab_secret.txt

# Create a group-accessible directory
sudo mkdir -p /opt/devshared
sudo chown root:developers /opt/devshared
sudo chmod 770 /opt/devshared
```

---

### Step 3 | Switched Users and Tested Access

```bash
# Switch to regular user and attempt access
su - labuser_a
cat /etc/lab_secret.txt       # Permission denied (expected)

# Confirm group access works
touch /opt/devshared/test.txt  # Success (labuser_a is in developers)

# Attempt to write as non-member
su - labadmin
touch /opt/devshared/admin.txt # Permission denied (not in developers group)
```

---

### Step 4 | Verified with `id`, `ls -l`, and `stat`

```bash
id labuser_a                 # Confirms UID, GID, and group memberships
ls -la /etc/lab_secret.txt   # Shows owner, group, and permission bits
stat /opt/devshared          # Shows full metadata
```

---

## Key Concepts Reinforced

- **User types**: Regular, admin (sudoer), and service accounts each serve a different purpose. Mixing them up is a security risk.
- **Permission bits**: `rwx` applies to owner, group, and others in that order. `chmod 600` means only the owner can read and write.
- **Group-based access**: Adding a user to a group is the clean way to share resources without opening permissions to everyone.
- **`nologin` shell**: Service accounts shouldn't have an interactive shell. It blocks SSH login while still letting the account run processes.
- **The error is the lesson**: A `Permission denied` response means the system is working correctly. Access control is being enforced.

---

## Environment

- **Platform:** Oracle Cloud VPS  
- **OS:** Ubuntu (Linux)  
- **Access:** SSH from local machine

---

## Notes

This is part of a structured Linux/DevOps learning series. Each drill builds on the last. Day 3 focused on identity and access management at the OS level, which underpins everything from web servers to CI/CD pipelines.
