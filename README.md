# How to force authoritative and non-authoritative synchronization for DFSR-replicated sysvol replication
[Work in Progress]

Refer the MSFT KB : https://learn.microsoft.com/en-us/troubleshoot/windows-server/group-policy/force-authoritative-non-authoritative-synchronization

## Steps are given below for complete Automation

### SysVol State
```powershell
<#
State values are:
0: Uninitialized
1: Initialized
2: Initial Sync
3: Auto Recovery
4: Normal
5: In Error
#>
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
