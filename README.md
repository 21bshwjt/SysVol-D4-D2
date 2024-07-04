# SysVol-D4-D2 -Work in Progress

```powershell
$servers = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 

foreach ($server in $servers) {
    try {
        $result = Get-WmiObject -Namespace "root\microsoftdfs" -Class "dfsrreplicatedfolderinfo" -ComputerName $server -Filter "replicatedfoldername='SYSVOL share'" | 
        Select-Object @{Name = 'DomainController'; Expression = { $_.MemberName } }, ReplicationGroupName, ReplicatedFolderName, State
        if ($result) {
            $result # | Format-Table -AutoSize
        }
        else {
            Write-Host "No DFSR information found on $server for 'SYSVOL share'."
        }
    }
    catch {
        Write-Host "Error querying $server : $_"
    }
} 

```
