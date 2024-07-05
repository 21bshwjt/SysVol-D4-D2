$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 
# Start the DRSR Service  

$DCs | Foreach-Object -Process { 
    #Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname 
    Invoke-Command -ComputerName $PSItem { Start-Service -Name 'DFS Replication' -Verbose 
    } 
} 