$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 
# Change Service startup type Autometic

$DCs | Foreach-Object -Process { 
    Invoke-Command -ComputerName $PSItem { Set-Service -Name 'DFSR' -StartupType Automatic -Verbose
    } 
} 