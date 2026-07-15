Active Directory Home Lab

A two-machine Active Directory environment built from scratch in VirtualBox: one Windows Server 2022 domain controller, one Windows 11 client joined to the domain, with a Group Policy Object created, linked, and verified applying on the client.

I built this to get hands-on with the tools I would actually be using in a Tier 1 or Tier 2 support role. Reading about Active Directory and using it are two different things, and I wanted to be able to talk about it from experience rather than from a study guide.

Environment

MachineRoleOSIPDC01Domain controller, DNSWindows Server 2022 Standard (Desktop Experience)192.168.10.1 (static)Client01Domain-joined workstationWindows 11 Pro192.168.10.10 (static)

Both VMs run on a VirtualBox Internal Network named labnet, which isolates the lab from my home network. The domain is thornelab.local.

What I Built

Domain controller. Installed Windows Server 2022, set a static IP, renamed the machine, then installed the Active Directory Domain Services role and promoted the server to a domain controller in a new forest. DNS installs alongside AD DS and the DC points at itself for name resolution, since the SRV records that domain joins and logons depend on are hosted by the DC itself.

Directory structure. Created two Organizational Units, Employees and IT, populated Employees with test user accounts, and created a HelpDesk-Users global security group with those users as members. I used OUs rather than the default Users container specifically because Group Policy Objects can only be linked to OUs, not to containers.

Client machine. Installed Windows 11, set a static IP on the same subnet, and pointed its DNS at the domain controller. Verified connectivity with ping and confirmed name resolution with nslookup before attempting the join, so that any failure would be a domain problem and not a network problem.

Domain join. Joined Client01 to thornelab.local using domain admin credentials. The computer object appeared automatically in the Computers container in Active Directory Users and Computers, and I confirmed the join by logging in as a domain user and checking whoami, which returned the domain account rather than a local one.

Group Policy. Created a GPO named Desktop-Standard-Policy and linked it to the Employees OU, then configured a User Configuration setting under Administrative Templates.

Verification. Ran gpupdate /force on the client, logged out and back in, and confirmed the setting took effect. gpresult /r listed Desktop-Standard-Policy under Applied Group Policy Objects and showed the policy was pulled from DC01.thornelab.local. That output is the client reporting what it applied, which is stronger evidence than the change being visible on screen.

Problems I Hit and How I Fixed Them

These were the useful part of the build. Each one took some diagnosis.

Client could not reach the domain controller. Pings to the DC timed out, and one reply came back as "Destination host unreachable" from the client's own IP. That specific message means the client sent an ARP request for the DC and got no answer, so nothing on that network segment was responding at that address. That pointed at a layer 2 problem rather than DNS or a firewall. The cause turned out to be that the client's network adapter setting had never saved to Internal Network, so the two VMs were on completely different networks despite the configuration appearing correct. Reapplying the setting with the VM fully powered off fixed it, and ping came back clean at 0 percent loss.

Client could not join the domain. In System Properties, the Domain radio button was greyed out and could not be selected. Checking winver showed the client was running Windows 11 Home, which does not support domain joins at all. This is an edition limitation, not a misconfiguration. I upgraded the client in place to Windows 11 Pro, which enabled the option and let the join proceed. This is a realistic scenario, since a user's machine turning out to be on Home edition is a common reason a domain join fails in the field.

nslookup returned "Server: UnKnown". The forward lookup for thornelab.local resolved correctly, but nslookup printed the DNS server as unknown and timed out first. This happens because nslookup attempts a reverse lookup on the DNS server to print its hostname, and no reverse lookup zone existed in DNS. The forward resolution that actually mattered succeeded, so this was cosmetic rather than a fault.

Windows 11 setup required a Microsoft account. With no internet access on an isolated network, the out of box experience stalled at the network screen. Using start ms-cxh:localonly from a command prompt during setup allowed local account creation and let the install finish.

What This Covers

The skills this lab exercises map directly to common help desk and desktop support work:


Creating and managing user accounts, groups, and OUs in Active Directory Users and Computers
Joining workstations to a domain and troubleshooting joins that fail
Creating, linking, and verifying Group Policy Objects
DNS configuration and its role in Active Directory
Static IP configuration and basic network troubleshooting with ping, ipconfig, nslookup, and arp
Command line tools including gpupdate, gpresult, and whoami
Understanding Windows edition differences and their practical impact


Screenshots

screenshots/aduc-employees-ou.pngEmployees OU with test users and the HelpDesk-Users security groupscreenshots/client01-computer-object.pngCLIENT01 computer object created automatically by the domain joinscreenshots/gpo-linked.pngDesktop-Standard-Policy linked to the Employees OU in Group Policy Managementscreenshots/gpresult.pnggpresult /r on the client confirming the GPO applied and the DC it came from

Next Steps


Install the DHCP role on the DC so the client pulls an address automatically instead of using a static IP
Add a reverse lookup zone in DNS so PTR records resolve
Create a shared folder with permissions tied to the HelpDesk-Users group to practice NTFS and share permissions
Simulate a support ticket by locking out a test account and working through the unlock in Active Directory
