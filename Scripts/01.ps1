$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 

# Change Service startup type to manual & stop the DFSR Service
$DCs | ForEach-Object -Process { 
    try {
        # Action that will run in parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname
        Invoke-Command -ComputerName $PSItem -ScriptBlock { 
            Set-Service -Name 'DFSR' -StartupType Manual -Verbose
            Stop-Service -Name 'DFS Replication' -Force -Verbose 
        } -ErrorAction Stop
    } catch {
        Write-Error "Failed to modify DFSR service on $PSItem Error: $_"
    }
}