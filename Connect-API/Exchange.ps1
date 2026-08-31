<#
############################################################################# 

Different commands to pull user/mailbox information from exchange.

Along with set commands to change that same informaiton.

############################################################################# 

#>
Install-Module -Name ExchangeOnlineManagement -Force
Import-Module ExchangeOnlineManagement

Connect-ExchangeOnline -Device

 Get-RecipientPermission -Identity "johndoe@company.com" -Trustee janedoe@company.com

 Get-MailboxFolderPermission -Identity "johndoe@company.com:\Calendar" -User janedoe@company.com

 Get-MailboxPermission -Identity "johndoe@company.com" -User "janedoe@company.com"

Set-Mailbox -Identity "johndoe@company.com" -MessageCopyForSentAsEnabled $True

Set-Mailbox -Identity johndoe@company.com -DisplayName "John Doe" -Alias "JohnDoe" -EmailAddresses @{Add = "SMTP:johndoe@company.com" } -PrimarySmtpAddress johndoe@company.com

Set-Mailbox -Identity johndoe@company.com -EmailAddresses @(
  "SMTP:",
  "smtp:",
  "smtp:",
  "smtp:.onmicrosoft.com"
)

$mailboxParams = @{
  Identity = "janedoe@company.com"
}

$formatParams = @{
  Property = @(
    "DisplayName"
    "Alias"
    "UserPrincipalName"
    "FirstName"
    "LastName"
    "PrimarySmtpAddress"
    "EmailAddresses"
    "HiddenFromAddressListsEnabled"
    "IsMailboxEnabled"
    "RecipientTypeDetails"
    "MessageCopyForSentAsEnabled"
  )
}
Get-Mailbox @mailboxParams | Format-List @formatParams

Get-MailboxCalendarConfiguration -Identity "johndoe@company.com" | Select-Object DefaultOnlineMeetingProvider

<#
############################################################################# 

Pull Mail-Enabled Security groups

############################################################################# 

#>

Connect-ExchangeOnline -Device
 
$GroupEmail = "blank@company.com"
$CsvPath    = ".csv"

$Group = Get-DistributionGroup -Identity $GroupEmail
$OwnerRefs = $Group.ManagedBy

$Owners = if ($OwnerRefs) { $OwnerRefs | ForEach-Object { Get-Recipient $_ } } else { @() }
$Members = Get-DistributionGroupMember -Identity $GroupEmail -ResultSize Unlimited

$OwnerIds = $Owners.ExternalDirectoryObjectId | Where-Object { [string]::IsNullOrWhiteSpace($_) -eq $false }

$ExportData = @()

if ($Owners) {
    $ExportData += $Owners | Select-Object @{Name="Id"; Expression={$_.ExternalDirectoryObjectId}}, 
        DisplayName, 
        @{Name="UserPrincipalName"; Expression={$_.PrimarySmtpAddress}}, 
        @{Name="Role"; Expression={"Owner"}}
}

if ($Members) {
    $ExportData += $Members | Where-Object { $_.ExternalDirectoryObjectId -notin $OwnerIds } | Select-Object @{Name="Id"; Expression={$_.ExternalDirectoryObjectId}}, 
        DisplayName, 
        @{Name="UserPrincipalName"; Expression={$_.PrimarySmtpAddress}}, 
        @{Name="Role"; Expression={"Member"}}
}

$ExportData | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

Write-Host "Export complete: $CsvPath"
<#
############################################################################# 

Pull DDL memebers

############################################################################# 
#>

Connect-ExchangeOnline -Device

Get-DynamicDistributionGroupMember -Identity "" | Select-Object Name, PrimarySmtpAddress | Export-Csv -Path "" -NoTypeInformation

<#
############################################################################# 

Add CSV members to an distribution group

############################################################################# 
#>

# Connect-ExchangeOnline -Device

$GroupId = ""
$InputCsv = ""
$OutputCsv = ""
$EmailColumn = "email"

$UseBypassSecurityGroupManagerCheck = $true

# Validate and import the CSV
if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw "Input CSV was not found: $InputCsv"
}

$Users = @(Import-Csv -LiteralPath $InputCsv)

if ($Users.Count -eq 0) {
    throw "The input CSV contains no data rows."
}

$EmailProperty = $Users[0].PSObject.Properties.Name |
    Where-Object { $_ -ieq $EmailColumn } |
    Select-Object -First 1

if (-not $EmailProperty) {
    throw "The CSV does not contain the column '$EmailColumn'."
}

# Store existing members for fast lookups
$Comparer = [System.StringComparer]::OrdinalIgnoreCase

$Members = [System.Collections.Generic.HashSet[string]]::new($Comparer)
$SeenInput = [System.Collections.Generic.HashSet[string]]::new($Comparer)

Write-Host "Retrieving existing group members..." -ForegroundColor Cyan

Get-DistributionGroupMember `
    -Identity $GroupId `
    -ResultSize Unlimited `
    -ErrorAction Stop |
ForEach-Object {
    $Address = ([string]$_.PrimarySmtpAddress).Trim()

    if ($Address) {
        [void]$Members.Add($Address)
    }
}

Write-Host "Existing members retrieved: $($Members.Count)" -ForegroundColor Cyan

# Process the CSV
$Report = foreach ($User in $Users) {

    # Remove hidden spaces and clean the email
    $Email = (
        ([string]$User.$EmailProperty) -replace
        '[\u00A0\u200B\uFEFF]', ''
    ).Trim()

    $Status = "Failed"
    $Active = $false

    if ([string]::IsNullOrWhiteSpace($Email)) {
        $Status = "Blank Email"
    }
    elseif (-not $SeenInput.Add($Email)) {
        $Status = "Duplicate in CSV"
        $Active = $Members.Contains($Email)
    }
    elseif ($Members.Contains($Email)) {
        $Status = "Already Member"
        $Active = $true
    }
    else {
        try {
            Add-DistributionGroupMember `
                -Identity $GroupId `
                -Member $Email `
                -BypassSecurityGroupManagerCheck:$UseBypassSecurityGroupManagerCheck `
                -ErrorAction Stop

            [void]$Members.Add($Email)
            $Status = "Success"
            $Active = $true
        }
        catch {
            $Message = if ($_.ErrorDetails.Message) { [string]$_.ErrorDetails.Message } else { [string]$_.Exception.Message }
            $Message = ($Message -replace '^\s*\|+\s*', '').Trim()

            if ($Message -match '(?i)already.*member') {
                [void]$Members.Add($Email)
                $Status = "Already Member"
                $Active = $true
            }
            elseif ($Message -match '(?i)multiple recipients matching|matches multiple recipients|matches multiple entries') {
                try {
                    $Duplicates = Get-Recipient -ResultSize Unlimited -Filter "EmailAddresses -eq '$Email'" -ErrorAction Stop
                    
                    if ($Duplicates) {
                        # Sort descending to prioritize MailUser over MailContact
                        $TargetId = ($Duplicates | Sort-Object RecipientType -Descending)[0].DistinguishedName
                        
                        Add-DistributionGroupMember `
                            -Identity $GroupId `
                            -Member $TargetId `
                            -BypassSecurityGroupManagerCheck:$UseBypassSecurityGroupManagerCheck `
                            -ErrorAction Stop

                        [void]$Members.Add($Email)
                        $Status = "Success (Resolved Ambiguous)"
                        $Active = $true
                    }
                    else {
                        $Status = "Ambiguous Recipient (Resolution Failed)"
                    }
                }
                catch {
                    $Status = "Ambiguous Recipient (Resolution Failed)"
                }
            }
            elseif ($Message -match '(?i)couldn.?t find object|could not find object|couldn.?t be found|could not be found') {
                $Status = "User Not Found (Requires MailContact)"
            }
            else {
                $Status = "Error: $Message"
            }
        }
    }

    # Preserve original columns
    $OutputRow = [ordered]@{}

    foreach ($Property in $User.PSObject.Properties) {
        $OutputRow[$Property.Name] = $Property.Value
    }

    # Write the cleaned email to the output
    $OutputRow[$EmailProperty] = $Email
    $OutputRow["Active"] = $Active
    $OutputRow["InvitedStatus"] = $Status

    [PSCustomObject]$OutputRow
}

# Export results
$Report |
    Export-Csv `
        -LiteralPath $OutputCsv `
        -NoTypeInformation `
        -Encoding UTF8

# Display summary
Write-Host ""
Write-Host "PROCESS COMPLETED" -ForegroundColor Cyan
Write-Host "Total input rows: $($Users.Count)"

$Report |
    Group-Object InvitedStatus |
    Sort-Object Name |
    Select-Object `
        @{Name = "Status"; Expression = { $_.Name } },
        Count |
    Format-Table -AutoSize

Write-Host "Report saved to: $OutputCsv" -ForegroundColor Cyan

Disconnect-ExchangeOnline -Confirm:$false

<#
############################################################################# 

Add mail contacts to tenant.

############################################################################# 
#>
Connect-ExchangeOnline -Device

$InputCsv = ""

Import-Csv -LiteralPath $InputCsv | ForEach-Object {
    $Email = ([string]$_.email -replace '[\u00A0\u200B\uFEFF]', '').Trim()
    
    if (-not [string]::IsNullOrWhiteSpace($Email)) {
        $Name = $Email.Split('@')[0]
        
        try {
            New-MailContact `
                -Name $Name `
                -ExternalEmailAddress $Email `
                -ErrorAction Stop
                
            Write-Host "Created Mail Contact: $Email" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed or already exists: $Email" -ForegroundColor Yellow
        }
    }
}