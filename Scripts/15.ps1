# Get members of the "Domain Controllers" group and store their names in $servers array
$servers = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name

# Get the PDC Emulator for the domain 
$PDCNameFull = (Get-ADDomain).PDCEmulator 
 
# Split the full server name to get only the server name part 
$PDCName = $PDCNameFull -split '\.' | Select-Object -First 1 

# Remove PDC from the $servers array
$servers = $servers | Where-Object { $_ -ne "$PDCName" }

# Run DFSRDIAG POLLAD to all Non Auth DCs
$servers | ForEach-Object -Process {
    Invoke-Command -ComputerName $PSItem { DFSRDIAG POLLAD -Verbose }
}