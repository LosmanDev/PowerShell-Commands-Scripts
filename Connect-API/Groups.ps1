<#
############################################################################# 

Extract all members from security group to a csv

############################################################################# 

#>

$GroupId = ""
$CsvPath = ".\_$(Get-Date -Format 'yyyy-MM-dd').csv"

Connect-MgGraph -Scopes "GroupMember.ReadWrite.All"

$Members = Get-MgGroupMember -GroupId $GroupId -All

$Members | Select-Object Id, 
    @{Name="DisplayName"; Expression={$_.AdditionalProperties["displayName"]}}, 
    @{Name="UserPrincipalName"; Expression={$_.AdditionalProperties["userPrincipalName"]}}, 
    @{Name="UserType"; Expression={$_.AdditionalProperties["userType"]}} | 
Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

Write-Host "Export complete: $CsvPath"

<#
############################################################################# 

# Extract all security groups a user is in

############################################################################# 

#>
    
Connect-MgGraph -Scopes "User.ReadWrite.All"

$UserPrincipalName = "johndoe@company.com"

Get-MgUserMemberOf -UserId $UserPrincipalName -All | 
    Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' } |
    Select-Object @{Name="DisplayName"; Expression={$_.AdditionalProperties["displayName"]}}, 
                  Id |
    Sort-Object DisplayName |
    Format-Table -AutoSize


Disconnect-MgGraph

############################################################################# 

# Pull Users from CSV and checks whether enabled/disabled/not found

############################################################################# 

#>


Connect-MgGraph -Scopes "User.ReadWrite.All"

# Define paths
$importPath = ".csv"
$exportPath = ".csv"

$csvData = Import-Csv -Path $importPath
$userLookup = @{}

# Chunk size reduced to 7 to prevent exceeding Graph's 15 OR clause limit
$chunkSize = 7
$totalRows = $csvData.Count

for ($i = 0; $i -lt $totalRows; $i += $chunkSize) {
    $chunkLimit = [math]::Min($i + $chunkSize - 1, $totalRows - 1)
    $chunk = $csvData[$i..$chunkLimit]
    
    # Construct OData filter checking both UPN and Mail (Max 14 clauses)
    $filterArray = foreach ($row in $chunk) {
        $email = $row.Email
        "userPrincipalName eq '$email' or mail eq '$email'"
    }
    $filterString = $filterArray -join " or "
    
    # Fetch chunk from Graph
    $users = Get-MgUser -Filter $filterString -Property Id, UserPrincipalName, Mail, AccountEnabled
    
    # Populate local hash table
    foreach ($user in $users) {
        if (![string]::IsNullOrWhiteSpace($user.UserPrincipalName)) {
            $userLookup[$user.UserPrincipalName] = $user.AccountEnabled
        }
        if (![string]::IsNullOrWhiteSpace($user.Mail)) {
            $userLookup[$user.Mail] = $user.AccountEnabled
        }
    }
}

foreach ($row in $csvData) {
    $targetEmail = $row.Email
    if ($userLookup.ContainsKey($targetEmail)) {
        $row.'Account enabled' = $userLookup[$targetEmail]
    } else {
        $row.'Account enabled' = "Not Found"
    }
}

$csvData | Export-Csv -Path $exportPath -NoTypeInformation

<#
############################################################################# 

Add members from csv to group ID

############################################################################# 

#>

$GroupId    = ""
$InputCsv   = ".csv"
$OutputCsv  = ".csv"

Connect-MgGraph -Scopes "User.ReadWrite.All", "GroupMember.ReadWrite.All"

$Users = Import-Csv -Path $InputCsv
$TotalUsers = $Users.Count
$CurrentIndex = 0

$ProcessedUsers = foreach ($User in $Users) {
    $CurrentIndex++
    Write-Progress -Activity "Adding Users to Graph Group" -Status "Processing $($User.Email)" -PercentComplete (($CurrentIndex / $TotalUsers) * 100)

    $Status = "Failed"
    $IsActive = $false # Default to false until proven otherwise
    $Attempt = 0
    
    do {
        $Attempt++
        try {
            $MgUser = Get-MgUser -Filter "mail eq '$($User.Email)' or userPrincipalName eq '$($User.Email)'" -Select "Id" -ErrorAction Stop
            
            if (-not $MgUser) { 
                $Status = "User Not Found"
                $IsActive = $false
                break 
            }

            # If the script reaches this line, the user exists in Entra ID
            $IsActive = $true 
            $TargetId = @($MgUser)[0].Id

            New-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $TargetId -ErrorAction Stop
            $Status = "Success"
            break
        }
        catch {
            $Exception = $_.Exception
            $StatusCode = $Exception.Response.StatusCode.value__
            
            if ($StatusCode -in 429, 502, 503, 504) {
                $RetryAfter = $Exception.Response.Headers.RetryAfter
                
                if ($RetryAfter.Delta) {
                    $Wait = $RetryAfter.Delta.TotalSeconds
                } elseif ($RetryAfter.Date) {
                    $Wait = ($RetryAfter.Date - [datetime]::UtcNow).TotalSeconds
                } else {
                    $Wait = [Math]::Pow(2, $Attempt)
                }
                
                if ($Wait -lt 1) { $Wait = 1 }
                
                Start-Sleep -Seconds $Wait
                continue
            }
            
            if ($_.ErrorDetails.Message -match '"code":\s*"Request_BadRequest"' -and $Exception.Message -match "already exist") { 
                $Status = "Already Member"
                break 
            } elseif ($Exception.Message -match "already exist") {
                $Status = "Already Member"
                break
            }
            
            $Status = "Error: $($Exception.Message)"
            break
        }
    } while ($Attempt -lt 5)

    $User | Add-Member -MemberType NoteProperty -Name "Active" -Value $IsActive -Force
    $User | Add-Member -MemberType NoteProperty -Name "InvitedStatus" -Value $Status -Force -PassThru
}

$ProcessedUsers | Export-Csv -Path $OutputCsv -NoTypeInformation

Disconnect-MgGraph



