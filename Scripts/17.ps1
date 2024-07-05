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