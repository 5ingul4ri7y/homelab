# Samba vs NFS

File sharing on a mixed network almost always comes down to one of these two protocols, and picking the wrong one usually shows up later as either a permissions headache or a performance complaint. Samba speaks SMB/CIFS, the protocol Windows machines expect natively. NFS is the Unix and Linux native equivalent. Neither one is strictly better, they solve the same problem for different audiences, and most real environments end up running both side by side rather than picking a single winner.

## Samba (SMB)

Samba implements SMB/CIFS, a protocol that originated on Windows but is now cross-platform. This matters because it lets Linux servers show up as normal network shares to Windows clients without the Windows side needing any special software.

- Protocol: SMB/CIFS, originally Windows, now cross-platform
- Best for: mixed Linux and Windows environments
- Auth: username and password, backed by Samba's own user database
- Performance: good, with slightly more overhead than NFS
- Port: 445/tcp for SMB, 139/tcp for the older NetBIOS transport
- Config file: `/etc/samba/smb.conf`
- Typical use case: office file servers, Windows clients, Active Directory integration

The username and password model is the key detail here. Samba keeps its own separate user database rather than relying on Linux system accounts directly, which is what makes it usable by Windows clients that have no concept of Linux UID and GID.

## NFS

NFS is the native Unix and Linux file sharing protocol. Where Samba is built around explicit user authentication, NFS traditionally authenticates at the IP or host level, trusting whichever machine is connecting rather than a specific user.

- Protocol: NFS v3/v4, Unix and Linux native
- Best for: Linux-only environments
- Auth: IP based by default, or Kerberos when running NFSv4
- Performance: faster than Samba for Linux to Linux transfers
- Port: 2049/tcp for NFS v4
- Config file: `/etc/exports`
- Typical use case: Linux servers, HPC clusters, containers

The IP-based trust model is simpler to set up than Samba's user database but weaker on its own, since anything on a trusted subnet gets access. NFSv4 closes that gap by supporting Kerberos, which brings proper per-user authentication back into the picture at the cost of extra setup.

## Which one to use

The short version: if Windows clients are involved at all, Samba has to be part of the picture, since NFS support on Windows is limited and not something to depend on. If everything talking to the share is Linux, NFS is the faster, lighter option with less protocol overhead.

In practice most enterprise environments do not pick one over the other, they run both. Samba serves Windows desktops and laptops. NFS serves Linux application servers sharing data between nodes. Storage appliances like NAS and SAN boxes commonly export the same underlying storage through both protocols simultaneously, letting each client connect however is native to it.

# Summary

Samba and NFS solve the same problem, file sharing over a network, but they are built around different assumptions. Samba assumes a mixed, often Windows-heavy network and authenticates users explicitly. NFS assumes a Unix-native network and, by default, trusts hosts rather than users. Neither replaces the other, which is why most real infrastructure ends up running both.
