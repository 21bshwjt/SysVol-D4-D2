# Get the PDC Emulator for the domain 
$PDCNameFull = (Get-ADDomain).PDCEmulator 
 
# Split the full server name to get only the server name part 
$PDCName = $PDCNameFull -split '\.' | Select-Object -First 1 
Invoke-Command -ComputerName $PDCName  {Start-Service -Name 'DFS Replication' -Verbose} 