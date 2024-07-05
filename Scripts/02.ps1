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