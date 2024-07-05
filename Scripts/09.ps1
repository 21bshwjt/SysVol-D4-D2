# Change PDC on ADSIEDIT 
# Get the PDC Emulator for the domain 
$PDCNameFull = (Get-ADDomain).PDCEmulator 
 
# Split the full server name to get only the server name part 
$PDCName = $PDCNameFull -split '\.' | Select-Object -First 1 
 
$domain = (Get-ADDomain).DistinguishedName 
 
# Construct the DN (Distinguished Name) 
$dn = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$PDCName,OU=Domain Controllers,$domain" 
 
# Set the attributes 
Set-ADObject -Identity $dn -Replace @{ 
    "msDFSR-Enabled" = $True 
} -Verbose 