$NonASCIIChars = '[^\x20-\x7F]'
$OutputFolder = "$Home\Desktop"

function Get-NonASCII {
    param(
        [Parameter(Mandatory=$true)]
        [String]$ViewType,

        [Parameter(Mandatory=$true)]
        [String]$Label
    )

    $Names = (Get-View -Server $vCenter -ViewType $ViewType -Property Name).Name
    $NonASCIINames = $Names | Where-Object {$_ -cmatch $NonASCIIChars}

    if ($NonASCIINames) {
        $Report | Add-Member -MemberType NoteProperty -Name $Label -Value $NonASCIINames
    } else {
        $Report | Add-Member -MemberType NoteProperty -Name $Label -Value "All $Label have ASCII compliant names"
    }
}

# Verify the VMware.PowerCLI module is installed
if (!(Get-Module -ListAvailable -Name "VMware.PowerCLI")) {
    Write-Warning "The VMware.PowerCLI module is not installed!"
    break
}

# Verify the output folder exists for exporting the report
while (!(Test-Path -LiteralPath $OutputFolder)) {
    Write-Warning "$OutputFolder does not exist!"
    $OutputFolder = Read-Host 'Enter an existing folder path (e.g. C:\FolderName)'
}

# Connect to the vCenter Server
$vCenter = Read-Host "Enter the vCenter FQDN or IP address"
$Connection = Connect-VIServer -Server $vCenter
while (!$Connection) {
    Write-Warning 'Failed to connect to vCenter!'
    $vCenter = Read-Host "Enter the vCenter FQDN or IP address"
    $Connection = Connect-VIServer -Server $vCenter
}

# Create an object to store names that are not ASCII compliant
$Report = New-Object -TypeName PSObject

# Generate a report of names that are not ASCII compliant
Get-NonASCII -ViewType 'VirtualMachine' -Label 'VMs'
Get-NonASCII -ViewType 'Network' -Label 'Networks'
Get-NonASCII -ViewType 'Folder' -Label 'Folders'
Get-NonASCII -ViewType 'Datacenter' -Label 'Datacenters'
Get-NonASCII -ViewType 'ClusterComputeResource' -Label 'Clusters'
Get-NonASCII -ViewType 'ResourcePool' -Label 'Resource Pools'
Get-NonASCII -ViewType 'Datastore' -Label 'Datastores'

# Export the report to a .txt file
$OutputFile = "$OutputFolder\NonASCIIResults.txt"
Set-Content -LiteralPath $OutputFile -Value "ASCII Compliance Report : $vCenter"
Add-Content -LiteralPath $OutputFile -Value '-------------------------------------------------------------------------'
$Report | Out-File -LiteralPath $OutputFile -Append -Encoding utf8

# Disconnect from the vCenter Server
Disconnect-VIServer -Server $vCenter -Confirm:$false