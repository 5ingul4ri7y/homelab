# Active Directory Setup

This lab was performed on the Windows Server set up in the previous lab, along with a freshly set up Windows 10 VM in Hyper-V, which will act as a client for the Windows Server and connect to its Active Directory domain.

Now that the server was set up for Active Directory, I was ready to start creating real OUs, users, and groups for the Active Directory.

![Creating three Organizational Units](assets/AD01.png)

First off, I started out by creating three Organizational Units (OUs), namely IT, Sales, and Management, as they would realistically exist in a corporation. The commands used in PowerShell for this were:

```powershell
# Create Organisational Units

New-ADOrganizationalUnit -Name "IT" -Path "DC=corp,DC=lab"
New-ADOrganizationalUnit -Name "Sales" -Path "DC=corp,DC=lab"
New-ADOrganizationalUnit -Name "Management" -Path "DC=corp,DC=lab"
```

![Creating users and a group in PowerShell](assets/AD02.png)

I then stored a default password inside an environment variable in PowerShell to reuse for the users I would create. I created two users (inspired by my favorite show Mr. Robot), elliot.alderson and darlene.alderson. I also created a group named fsociety-Admins (again inspired by Mr. Robot) and added both users to it. All the commands I used are given below:

```powershell
# Create users

$pw = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force

New-ADUser -Name "Elliot Alderson" `
-GivenName "Elliot" `
-Surname "Alderson" `
-SamAccountName "elliot.alderson" `
-UserPrincipalName "elliot.alderson@corp.lab" `
-Path "OU=IT,DC=corp,DC=lab" `
-AccountPassword $pw `
-Enabled $true

New-ADUser -Name "Darlene Alderson" `
-GivenName "Darlene" `
-Surname "Alderson" `
-SamAccountName "darlene.alderson" `
-UserPrincipalName "darlene.alderson@corp.lab" `
-Path "OU=IT,DC=corp,DC=lab" `
-AccountPassword $pw `
-Enabled $true


# Create group and add members

New-ADGroup -Name "fsociety-Admins" `
-GroupScope Global `
-Path "OU=IT,DC=corp,DC=lab"

Add-ADGroupMember -Identity "fsociety-Admins" `
-Members elliot.alderson, darlene.alderson


# Verify users

Get-ADUser -Filter * `
-SearchBase "OU=IT,DC=corp,DC=lab" |
Select-Object Name, SamAccountName
```

![Confirming OUs, groups and users in ADUC](assets/AD03.png)

I then confirmed that the OUs, groups, and users had indeed been created, inside ADUC (Active Directory Users and Computers).

![Setting a static IP on the Windows client](assets/AD04.png)

I then turned to my Windows client VM, which was linked to the virtual network interface named "Internal-LAN," the same one the server was already linked to, and set up a static IP address as I had done for the server. I could have used the server as a DHCP server to hand out an IP to the Windows VM, but this was done deliberately to keep things simple throughout the lab. I set the DNS server for the Windows client to the IP address of the server, which lets it resolve the domain name of the server, corp.lab, as set up in the previous lab.

![Confirming DNS resolution with nslookup](assets/AD05.png)

I then checked that the DNS being set to the Windows Server indeed resolves correctly when querying for corp.lab and the subdomain dc01.corp.lab, and it was confirmed successfully.

![Joining the client VM to the domain](assets/AD06.png)

I then opened Settings and opened the Rename PC properties window. I proceeded to change the name of the Windows VM to Client1 and its domain to corp.lab. Clicking OK prompted me for the username and password for the Windows Server, which I provided.

![Domain join confirmation dialogue](assets/AD07.png)

It then displayed the dialogue confirming that the VM had been successfully added to the Active Directory domain of the Windows Server.

![Attempting to log in as elliot.alderson](assets/AD08.png)

I then tried to log in as the AD user elliot.alderson, as set up previously in the lab on the Windows Server.

![Remote Desktop sign in warning](assets/AD_trouble1.png)

But this gave me a warning and did not let me sign in. This issue was clearly on the local machine (Windows Client VM) and not on the side of the server.

![Adding AD users to the Remote Desktop Users group](assets/AD_trouble2.png)

I then logged in as the local user and added both AD users to the Remote Desktop Users group, as the warning had advised.

![Successfully logged in as elliot.alderson](assets/AD09.png)

I was then successfully able to log in as the AD user elliot.alderson. Windows set up a separate profile for my user when I logged in.

![Checking domain membership with systeminfo](assets/AD-10.png)

I then checked Active Directory domain info using the command `systeminfo | findstr "Domain"`, which printed only the domain being used by the machine. The domain was corp.lab, as expected.

![Get-ADComputer output on the server](assets/AD-11.png)

On the Windows Server, I ran the command `Get-ADComputer -Filter *` to get all the computers attached to the Active Directory on the server. It listed Client1 as one of those computers, which is our client VM running Windows 10.

![Wallpaper file placed in the NETLOGON share](assets/AD-12.png)

I then got to creating Group Policy Objects (GPOs) for the users of the Active Directory. For the first GPO, I wanted to force a wallpaper on all computers in the IT OU. I put an image named wallpaper.jpg, an image of the Blue Mosque, inside the `\\DC01\NETLOGON\` network directory. This is the wallpaper all users under the IT OU will receive.

> A GPO is a collection of settings that apply to users or computers in a scope (domain, OU). Click each GPO to see what it does and the exact setting path.

![Editing the Desktop Wallpaper GPO setting](assets/AD-13.png)

I then opened Group Policy Management and added a GPO inside the IT OU. Editing the GPO, I navigated to `User Configuration -> Policies -> Administrative Templates -> Desktop -> Desktop -> Desktop Wallpaper` and set up the wallpaper location.

![Wallpaper path and comment set in the GPO](assets/AD-14.png)

The location of the wallpaper was given inside the GPO, and a comment was added describing the policy this GPO enforces.

![Running gpupdate /force on the client](assets/AD-15.png)

I then turned to the Client1 VM and ran `gpupdate /force`, which pulls the latest Group Policy from the AD domain. After it completed, I had to log out and log back in to see if the changes took effect.

![Wallpaper applied after logging back in](assets/AD-16.png)

After logging back in, I could see that the wallpaper was successfully applied. The group policy was immediately applied as expected.

![Confirming the applied GPO with gpresult](assets/AD-17.png)

I checked the Group Policy for this specific user (elliot) by running `gpresult /r` and confirmed that a Group Policy Object by the name of "IT Desktop Wallpaper" was applied for this user.

![Domain wide password policy GPO](assets/AD-18.png)

Finally, I added a domain wide GPO that applies to all users under the domain. I set the following specs for the password:

```
Minimum password length: 12
Password must meet complexity: Enabled
Maximum password age: 90 days
```

---

# GPO Inheritance Logic

When multiple GPOs apply to a user, they are processed in a specific order. The last one to apply wins, and OUs override domains, which override sites.

## GPO Processing Order (lowest to highest priority)

### 1. Local Computer Policy

Settings configured directly on the machine via `gpedit.msc`.

Lowest priority, domain settings will override these.

applied next (overrides local)

### 2. AD Site GPOs

Applied to all computers in an AD site (physical location). Rarely used in small networks.

applied next (overrides site)

### 3. Domain GPOs

Applied to all users and computers in the domain.

The Default Domain Policy lives here. Password policy must be configured here.

applied last (highest priority)

### 4. OU GPOs

Applied only to objects within the OU.

Child OUs inherit parent OU GPOs unless inheritance is blocked.

OU GPOs have the highest priority and win conflicts.

> Example: if the Domain GPO says wallpaper = A and the OU GPO says wallpaper = B, the user gets wallpaper B. OU wins.
> Use `gpresult /r` on the client to see exactly which GPO applied each setting.

## AD Management with PowerShell

Every action you can do in ADUC, you can do faster with PowerShell.

| Cmdlet | Purpose |
|--------|---------|
| `Get-ADUser` | Query users with filters and property selection |
| `Set-ADUser` | Modify user attributes |
| `New-ADUser` | Create a new domain user |
| `Disable-ADAccount` | Disable a user (do not delete, keep for audit trail) |
| `Add-ADGroupMember` | Add users or computers to a group |
| `Unlock-ADAccount` | Unlock a locked out account |
| `Get-ADComputer` | List domain joined computers |
