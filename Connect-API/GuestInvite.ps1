<#
############################################################################# 

Guest user invites and add to group

############################################################################# 

#>
Connect-MgGraph -Scopes "User.Invite.All","User.ReadWrite.All","GroupMember.ReadWrite.All"

$csvPath = ''
$groupId = ""
$logPath = "$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    $line | Tee-Object -FilePath $logPath -Append
}

function Get-TrimmedValue {
    param($Value)
    return ([string]$Value).Trim()
}

Write-Log "Starting from $csvPath"

Import-Csv $csvPath | ForEach-Object {

    $firstName   = Get-TrimmedValue $_.'First Name'
    $lastName    = Get-TrimmedValue $_.'Last Name'
    $email       = Get-TrimmedValue $_.'Email'
    $employeeId  = Get-TrimmedValue $_.'Employee ID'
    $title       = Get-TrimmedValue $_.'Job Title'
    $state       = Get-TrimmedValue $_.'State'
    $country     = Get-TrimmedValue $_.'Country'
    $fteManager  = Get-TrimmedValue $_.'FTE Manager'
    $companyName = Get-TrimmedValue $_.'Company name'

    if ([string]::IsNullOrWhiteSpace($email)) {
        Write-Log "Skipping empty email" "WARNING"
        return
    }

    $displayName = ("$firstName $lastName").Trim()
    if ([string]::IsNullOrWhiteSpace($displayName)) { $displayName = $email }

    Write-Log "Processing $displayName <$email>"

    try {
        #Write-log "1"
        $guestUser = Get-MgUser -Filter "mail eq '$email'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue

        if (-not $guestUser) {
        #Write-log "2"
            $inv = New-MgInvitation `
                -InvitedUserDisplayName $displayName `
                -InvitedUserEmailAddress $email `
                -InviteRedirectUrl "https://myapps.microsoft.com" `
                -SendInvitationMessage:$true `
                -ErrorAction Stop

            Write-Log "Invitation: $($inv.Id) $($inv.Status)"

            $guestUser = $null
            for ($i = 1; $i -le 12; $i++) {
            #Write-log "3"
                Start-Sleep 10
                $guestUser = Get-MgUser -Filter "mail eq '$email'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
                if ($guestUser) { break }
            }

            if (-not $guestUser) { throw "Guest not found after retries" }
        }

        $updateParams = @{}
        if ($firstName)   { $updateParams.GivenName   = $firstName }
        if ($lastName)    { $updateParams.Surname     = $lastName }
        if ($title)       { $updateParams.JobTitle    = $title }
        if ($companyName) { $updateParams.CompanyName = $companyName }
        if ($email)       { $updateParams.OtherMails  = @($email) }

        if ($employeeId -and $employeeId.Length -le 16) {
            $updateParams.EmployeeId = $employeeId
        }

        if ($state) { $updateParams.State = $state }
        if ($country) { $updateParams.Country = $country }

        if ($updateParams.Count -gt 0) {
            Update-MgUser -UserId $guestUser.Id @updateParams -ErrorAction Stop
        }

        if ($fteManager) {
            $managerUser = Get-MgUser -Filter "mail eq '$fteManager' or userPrincipalName eq '$fteManager'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
            
            if ($managerUser) {
                try {
                    Set-MgUserManagerByRef -UserId $guestUser.Id -BodyParameter @{
                        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($managerUser.Id)"
                    } -ErrorAction Stop
                    Write-Log "Manager set: $fteManager"
                }
                catch {
                    if ($_.Exception.Message -match "already|Conflict") {
                        Write-Log "Manager already set" "INFO"
                    }
                }
            }
            else {
                Write-Log "Manager not found: $fteManager" "WARNING"
            }
        }

        try {
            New-MgGroupMemberByRef -GroupId $groupId -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($guestUser.Id)"
            } -ErrorAction Stop
            Write-Log "Added to group"
        }
        catch {
            if ($_.Exception.Message -match "already exist") {
                Write-Log "Already in group" "INFO"
            }
        }

        Write-Log "SUCCESS: $email" "SUCCESS"
    }
    catch {
        Write-Log "ERROR ${email}: $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Complete. Log: $logPath"

Disconnect-Graph

<#
############################################################################# 

Check Accounts if they're in the group

############################################################################# 

#>

$targetEmails = @(
"johndoe@company.com",
"janedoe@company.com"
)

$groupId = ""

Connect-MgGraph -Scopes "User.Invite.All","User.ReadWrite.All","GroupMember.ReadWrite.All"

$selectProperties = @(
    "Id", "GivenName", "Surname", "Mail", "UserPrincipalName", 
    "EmployeeId", "JobTitle", "State", "Country", "CompanyName"
)

$extractedData = foreach ($email in $targetEmails) {
    $user = Get-MgUser -Filter "mail eq '$email' or userPrincipalName eq '$email'" `
                     -Property $selectProperties `
                     -ConsistencyLevel eventual `
                     -ErrorAction SilentlyContinue

    if ($user) {
        $managerEmail = $null
        $manager = Get-MgUserManager -UserId $user.Id -ErrorAction SilentlyContinue
        
        if ($manager) {
            $managerEmail = if ($manager.Mail) { $manager.Mail } else { $manager.UserPrincipalName }
            if (-not $managerEmail -and $manager.AdditionalProperties) {
                $managerEmail = $manager.AdditionalProperties["mail"] ?? $manager.AdditionalProperties["userPrincipalName"]
            }
        }

        $isMember = $false
        $userGroups = Get-MgUserMemberOf -UserId $user.Id -All -ErrorAction SilentlyContinue
        if ($userGroups.Id -contains $groupId) {
            $isMember = $true
        }

        [PSCustomObject]@{
            'First Name'                    = $user.GivenName
            'Last Name'                     = $user.Surname
            'Email'                         = if ($user.Mail) { $user.Mail } else { $user.UserPrincipalName }
            'Employee ID'                   = $user.EmployeeId
            'Job Title'                     = $user.JobTitle
            'State'                         = $user.State
            'Country'                       = $user.Country
            'FTE Manager'                   = $managerEmail
            'Company name'                  = $user.CompanyName
            'sso-sumtotal-externalad-users' = $isMember
        }
    } else {
        Write-Warning "User not found for email: $email"
    }
}

$extractedData | Format-Table -AutoSize

Disconnect-MgGraph