<#
############################################################################# 

Block a spam numbers globally in Teams

############################################################################# 
#>

# Install-Module MicrosoftTeams -Force
# Import-Module MicrosoftTeams
Connect-MicrosoftTeams -UseDeviceAuthentication

New-CsInboundBlockedNumberPattern `
    -Name "" `
    -Enabled $True `
    -Description "" `
    -Pattern "^\+? place number here  $"

Get-CsInboundBlockedNumberPattern | Where-Object { $_.Pattern -eq '^\+? place number here $' }
