<h2 align="center">
  <img width="55" src="https://github.com/21bshwjt/SysVol-D4-PowerShell/blob/bf9cb4a2ecc57a5f5b4b0a411ddcc0ab53f3e607/Screenshots/dfsr.png?raw=true">
  Force DFSR Sysvol Replication using PowerShell
  <img width="55" src="https://github.com/21bshwjt/SysVol-D4-PowerShell/blob/bf9cb4a2ecc57a5f5b4b0a411ddcc0ab53f3e607/Screenshots/dfsr.png?raw=true">
</h2>

___________________________________________________________________________________________________________________

👉 **D4/D2 Automation is done by following this Microsoft [KB](https://learn.microsoft.com/en-us/troubleshoot/windows-server/group-policy/force-authoritative-non-authoritative-synchronization).**
___________________________________________________________________________________________________________________

### Instructions & prerequisites
👉 - Clone the Repo : git clone https://github.com/21bshwjt/SysVol-D4-PowerShell.git<br/>
👉 - Copy Scripts folder into the PDC<br/>
👉 - Domain Admins Privillages<br/>
👉 - Run those Scripts in sequence<br/>
👉 - Script numbering have been done based on readme file numbering hence 3, 8 & 12 are not there <br/>
👉 - Make sure Active Directory Replication is completed across the domain before running the next script<br/>
___________________________________________________________________________________________________________________

#### 1. Set the DFS Replication service Startup Type to Manual and stop the service on all domain controllers in the domain. 
```powershell
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
```

#### 2. Verify DFSR Service Status from all Domain Controllers
```powershell
# Get the DFSR Service Status
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 
$GetoBj = Foreach ($DC in $DCs) { 
    Invoke-Command -ComputerName $DC { 
        [PSCustomObject]@{ 
            DomainController = ($env:COMPUTERNAME).ToUpper() 
            ServiceName      = (Get-Service -Name DFSR).Name 
            Status           = (Get-Service -Name DFSR).Status 
            StartType        = (Get-Service -Name DFSR).StartType 
        }  
    }  
}  
$GetoBj | Select-Object -Property DomainController, ServiceName, Status, StartType 
```

#### 3. In the ADSIEDIT.MSC tool, modify the following DN and two attributes on the domain controller you want to make authoritative (preferably the PDC Emulator, which is usually the most up-to-date for sysvol replication contents) - Manual
```powershell
CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=<the server name>,OU=Domain Controllers,DC=<domain>

msDFSR-Enabled=FALSE
msDFSR-options=1
```

#### 4 Modify that using PowerShell - Automated
```powershell
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
    "msDFSR-Enabled" = $False 
    "msDFSR-options" = 1 
} -Verbose 
```
#### 5. Modify the following DN and single attribute on all other domain controllers in that domain
```powershell
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
```
#### 6. Force Active Directory replication throughout the domain and validate its success on all DCs.
```powershell
repadmin /syncall /A /e /P /d /q
```

#### 7. Start the DFSR service on the PDC
```powershell
# Get the PDC Emulator for the domain 
$PDCNameFull = (Get-ADDomain).PDCEmulator 
 
# Split the full server name to get only the server name part 
$PDCName = $PDCNameFull -split '\.' | Select-Object -First 1 
Invoke-Command -ComputerName $PDCName  {Start-Service -Name 'DFS Replication' -Verbose} 
```

#### 8. You'll see Event ID 4114 in the DFSR event log indicating sysvol replication is no longer being replicated. 

#### 9. Set msDFSR-Enabled=TRUE on PDC
```powershell
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
```
#### 10. Force Active Directory replication throughout the domain and validate its success on all DCs. 
```powershell
repadmin /syncall /A /e /P /d /q
```
#### 11. Run the following command from an elevated command prompt on the same server that you set as authoritative:
```powershell
DFSRDIAG POLLAD 
```
#### 12. You'll see Event ID 4602 in the DFSR event log indicating sysvol replication has been initialized. That domain controller has now done a D4 of sysvol replication. 

#### 13. Start the DFSR service on the other non-authoritative DCs. You'll see Event ID 4114 in the DFSR event log indicating sysvol replication is no longer being replicated on each of them 
```powershell
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 
# Start the DRSR Service  

$DCs | Foreach-Object -Process { 
    #Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname 
    Invoke-Command -ComputerName $PSItem { Start-Service -Name 'DFS Replication' -Verbose 
    } 
} 
```

#### 14 Modify the following DN and single attribute on all other domain controllers in that domain:
```powershell
$domain = (Get-ADDomain).DistinguishedName  
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name  
 
foreach ($DC in $DCs) {  
 
    $dn = "CN=SYSVOL Subscription,CN=Domain System Volume,CN=DFSR-LocalSettings,CN=$DC,OU=Domain Controllers,$domain"  
    Set-ADObject -Identity $dn -Replace @{  
        "msDFSR-Enabled" = $True 
 
    } -Verbose  
}
```
#### 15. Run the following command from an elevated command prompt on all non-authoritative DCs (that is, all but the formerly authoritative one): 
```powershell
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
```

#### 16. Return the DFSR service to its original Startup Type (Automatic) on all DCs. 
```powershell
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 
# Change Service startup type Autometic

$DCs | Foreach-Object -Process { 
    Invoke-Command -ComputerName $PSItem { Set-Service -Name 'DFSR' -StartupType Automatic -Verbose
    } 
} 
```
#### 17. Verify DFSR Service Status from all Domain Controllers
```powershell
# Get the DFSR Service Status
$DCs = Get-ADGroupMember -Identity "Domain Controllers" | Select-Object -ExpandProperty Name 

$GetoBj = foreach ($DC in $DCs) { 
    try {
        $result = Invoke-Command -ComputerName $DC -ScriptBlock {
            [PSCustomObject]@{ 
                DomainController = $env:COMPUTERNAME.ToUpper()
                ServiceName      = (Get-Service -Name DFSR -ErrorAction Stop).Name
                Status           = (Get-Service -Name DFSR -ErrorAction Stop).Status
                StartType        = (Get-Service -Name DFSR -ErrorAction Stop).StartType
            }
        }
    }
    catch {
        $result = [PSCustomObject]@{
            DomainController = $DC.ToUpper()
            ServiceName      = "DFSR"
            Status           = "Error: $($Error[0].Exception.Message)"
            StartType        = "Unknown"
        }
    }
    
    $result
}

$GetoBj | Select-Object -Property DomainController, ServiceName, Status, StartType
```

#### 18. Verify SysVol State
```powershell
<#
State values are:
0: Uninitialized
1: Initialized
2: Initial Sync
3: Auto Recovery
4: Normal
5: In Error
Expected value is '4'.
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
            Write-Warning "No DFSR information found on $server for 'SYSVOL share'." 
        }
    }
    catch {
        Write-Warning "Error querying $server : $_"
    }
}

```
#### 19. Verify msDFSR-Enabled for msDFSR-options attribute values from all Domain Controllers (Optional)
```powershell
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
```
___________________________________________________________________________________________________________________

Biswajit Biswas a.k.a bshwjt | Email: <bshwjt@gmail.com> | [LinkedIn](https://www.linkedin.com/in/bshwjt/)
___________________________________________________________________________________________________________________
