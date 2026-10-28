# Create-LabUsers.ps1
# Creates 5 department OUs, a security group per OU, and 150 users (30 per OU)
# Lab use only: the shared password below is for an isolated test domain.
Import-Module ActiveDirectory

$domain      = Get-ADDomain
$domainDN    = $domain.DistinguishedName
$upnSuffix   = $domain.DNSRoot
$departments = @("IT","HR","Finance","Sales","Operations")
$password    = ConvertTo-SecureString "Welcome2026!Lab" -AsPlainText -Force

# 15 first x 10 last = 150 unique names
$firstNames = @("James","Maria","David","Aisha","Kevin","Sofia","Marcus","Priya","Daniel","Elena","Andre","Grace","Luis","Nina","Omar")
$lastNames  = @("Rivera","Chen","Patel","Johnson","Okafor","Nguyen","Garcia","Kim","Brooks","Silva")

# 1. OUs and security groups
foreach ($dept in $departments) {
    $ouDN = "OU=$dept,$domainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'")) {
        New-ADOrganizationalUnit -Name $dept -Path $domainDN -ProtectedFromAccidentalDeletion $false
        Write-Host "Created OU $dept"
    }
    if (-not (Get-ADGroup -Filter "Name -eq '$dept-Users'")) {
        New-ADGroup -Name "$dept-Users" -GroupScope Global -GroupCategory Security -Path $ouDN
    }
}

# 2. Users, spread evenly across the OUs
$i = 0
foreach ($first in $firstNames) {
    foreach ($last in $lastNames) {
        $dept = $departments[$i % $departments.Count]
        $sam  = "$($first).$($last)".ToLower()

        if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'")) {
            New-ADUser -Name "$first $last" `
                -GivenName $first -Surname $last `
                -DisplayName "$first $last" `
                -SamAccountName $sam `
                -UserPrincipalName "$sam@$upnSuffix" `
                -Department $dept `
                -Path "OU=$dept,$domainDN" `
                -AccountPassword $password `
                -ChangePasswordAtLogon $false `
                -Enabled $true
            Add-ADGroupMember -Identity "$dept-Users" -Members $sam
            Write-Host "Created $sam in $dept"
        }
        $i++
    }
}

# 3. Count per OU
foreach ($dept in $departments) {
    $count = (Get-ADUser -Filter * -SearchBase "OU=$dept,$domainDN").Count
    Write-Host "$dept : $count users"
}
