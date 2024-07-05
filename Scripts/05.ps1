$domain = (Get-ADDomain).DistinguishedName 
 
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name  
 
foreach ($DC in $DCs) { 
 
    # Construct the DN (Distinguished Name) 
    $dn = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,OU=Domain Controllers,$domain" 
 
    # Set the attributes 
    Set-ADObject -Identity $dn -Replace @{ 
        "msDFSR-Enabled" = $False 
    } -Verbose 
} 