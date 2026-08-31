<#
############################################################################# 

Remove Bulk Devices in csv from Intune

############################################################################# 

#>

$tenantId = ""
$appId = ""
$appSecret = ""
$csvPath = '.csv'

$tokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $appId
    Client_Secret = $appSecret
}

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $tokenBody
$secureToken = ConvertTo-SecureString -String $tokenResponse.access_token -AsPlainText -Force

Connect-MgGraph -AccessToken $secureToken

# Bypass 400 BadRequest by caching inventory locally
Write-Output "Caching Autopilot inventory..."
$allAutopilotDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All
$serialData = Import-Csv -Path $csvPath

foreach ($row in $serialData) {
    $serialNumber = $row.SERIAL.Trim()

    if ([string]::IsNullOrWhiteSpace($serialNumber)) { continue }

    $device = $allAutopilotDevices | Where-Object { $_.SerialNumber -eq $serialNumber }

    if ($device) {
        Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $device.Id
        Write-Output "Removed: $serialNumber"
    } else {
        Write-Output "Not Found: $serialNumber"
    }
}

Disconnect-MgGraph