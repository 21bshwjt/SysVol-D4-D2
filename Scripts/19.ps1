$domain = (Get-ADDomain).DistinguishedName 

$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 

$Objs = Foreach ($DC in $DCs){
    Get-ADObject -Filter {Name -eq "SYSVOL Subscription"} -SearchBase "CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,OU=Domain Controllers,$domain" -Properties DistinguishedName, msDFSR-Enabled, msDFSR-options | 
    Select-Object DistinguishedName, msDFSR-Enabled, msDFSR-options
}

foreach ($Obj in $Objs){
    $msDFSR_options = $Obj.'msDFSR-options'
    if ([string]::IsNullOrWhiteSpace($msDFSR_options)) {
        $msDFSR_options = "<not set>"
    }

    [PSCustomObject]@{ 
        DomainController = ($($Obj.DistinguishedName) -split ",")[3].Substring(3)
        "msDFSR-Enabled" = $($Obj.'msDFSR-Enabled')
        "msDFSR-options" = $msDFSR_options
    } 
}
