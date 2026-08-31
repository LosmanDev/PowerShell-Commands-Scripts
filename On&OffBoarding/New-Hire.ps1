# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

function Show-Notification {
    param (
        [Parameter(Position = 0)]
        [string]$Message,
        [Parameter(Position = 1)]
        [string]$Title = "Company"
    )

    if ([string]:: { return }
    if ([string]:: { $Title = "Company" }

    $balloon = New-Object System.Windows.Forms.NotifyIcon
    $balloon.Icon = [System.Drawing.SystemIcons]::Information
    $balloon.Visible = $true
    try {
        $balloon.ShowBalloonTip(5000, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Milliseconds 600
    }
    finally {
        $balloon.Dispose()
    }
}

function Show-InputDialog {
    param (
        [string]$Message,
        [string]$Title,
        [string]$DefaultValue = ""
    )

    $form = New-Object Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object Drawing.Size @(400, 200)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object Windows.Forms.Label
    $label.Location = New-Object Drawing.Point @(10, 20)
    $label.Size = New-Object Drawing.Size @(360, 40)
    $label.Text = $Message
    $form.Controls.Add($label)

    $textBox = New-Object Windows.Forms.TextBox
    $textBox.Location = New-Object Drawing.Point @(10, 70)
    $textBox.Size = New-Object Drawing.Size @(360, 20)
    $textBox.Text = $DefaultValue
    $form.Controls.Add($textBox)

    $okButton = New-Object Windows.Forms.Button
    $okButton.Location = New-Object Drawing.Point @(120, 120)
    $okButton.Size = New-Object Drawing.Size @(75, 23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)
    $form.AcceptButton = $okButton

    $cancelButton = New-Object Windows.Forms.Button
    $cancelButton.Location = New-Object Drawing.Point @(205, 120)
    $cancelButton.Size = New-Object Drawing.Size @(75, 23)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    $form.Activate()
    $result = $form.ShowDialog()

    if ($result -eq [Windows.Forms.DialogResult]::OK) {
        return $textBox.Text
    }

    return $null
}

function Export-ModifiedPDF {
    param (
        [__ComObject]$WordApp,
        [string]$TemplatePath,
        [string]$OutputPath,
        [hashtable]$Replacements
    )

    $doc = $WordApp.Documents.Open($TemplatePath, $null, $true)

    foreach ($key in $Replacements.Keys) {
        $find = $doc.Content.Find
        $find.Text = $key
        $find.Replacement.Text = $Replacements[$key]
        $find.Forward = $true
        $find.Wrap = 1
        $find.Format = $false
        $find.MatchCase = $false
        $find.MatchWholeWord = $false
        $find.MatchWildcards = $false
        $find.MatchSoundsLike = $false
        $find.MatchAllWordForms = $false

        $null = $find.Execute(
            [ref]$key,
            [ref]$false,
            [ref]$false,
            [ref]$false,
            [ref]$false,
            [ref]$false,
            [ref]$true,
            [ref]1,
            [ref]$false,
            [ref]$Replacements[$key],
            [ref]2
        )
    }

    $doc.SaveAs([ref]$OutputPath, [ref]17)
    $doc.Close([ref]0)
}

# Derive username directly from the script's absolute path to bypass elevation mismatches
if ([string]:: {
    throw "Script must be saved and executed from a file path, not an unsaved buffer."
}

$actualUsername = $PSScriptRoot.Split('\')[2]
$actualUserProfile = "C:\Users\$actualUsername"

$basePaths = @{
    WelcomeLetterTemplate = Join-Path $actualUserProfile "OneDrive - Company\Desktop\Onboarding\Welcome Letters\Company U.S. Welcome Letter Template.docx"
    SecureLetterTemplate  = Join-Path $actualUserProfile "OneDrive - Company\Desktop\Onboarding\Welcome Letters\[name] Secure Company U.S. Welcome Letter.docx"
    DesktopRoot           = Join-Path $actualUserProfile "OneDrive - Company\Desktop\New Hire Folders"
    DownloadsRoot         = Join-Path $actualUserProfile "Downloads"
    SecureEmailGuide      = Join-Path $actualUserProfile "OneDrive - Company\Desktop\Onboarding\Company U.S. Secure Email - Accessing a Secure Email_v2.pdf"
    AutoPilotGuide        = Join-Path $actualUserProfile "OneDrive - Company\Desktop\Onboarding\Company U.S. AutoPilot Laptop Configuration Instructions.pdf"
    EmailTemplate         = Join-Path $actualUserProfile "OneDrive - Company\Desktop\Onboarding\Emails\Secure Welcome to Company.msg"
    TeamsTemplate         = Join-Path $actualUserProfile "AppData\Roaming\Microsoft\Templates\(optional) New Hire IT 11 Introduction.oft"
    TeamsTemplateSource   = Join-Path $actualUserProfile "OneDrive - Company\Desktop\Onboarding\Emails\(optional) New Hire IT 11 Introduction.oft"
    SecurePDFNameTemplate = "{0} Secure Company U.S. Welcome Letter.pdf"
}

# Pre-initialize variables used in the finally block
$outputPDFs = @{}
$username = $null
$userFolder = $null

try {
    if (
        -not (Test-Path -LiteralPath $basePaths.WelcomeLetterTemplate) -or
        -not (Test-Path -LiteralPath $basePaths.SecureLetterTemplate)
    ) {
        throw "Template document paths invalid.`nEnsure $actualUserProfile contains the required files."
    }

    $rawFullName = Show-InputDialog `
        -Message "Enter full name (First Last)`nUsername might differ, edit in PDF if that's the case" `
        -Title "Full Name"

    if ([string]:: {
        throw "Name input cancelled."
    }

    $startDate = Show-InputDialog `
        -Message "Enter start date (MM/DD formats to use 0401, 04/01)" `
        -Title "Start Date"

    if ([string]:: {
        throw "Date input cancelled."
    }

    $ti = (Get-Culture).TextInfo
    $fullName = $ti.ToTitleCase($rawFullName.ToLower())
    $parts = $fullName.Split(' ', [StringSplitOptions]::

    if ($parts.Count -lt 2) {
        throw "First and last name required."
    }

    # Generic example: john.doe
    $username = ("{0}.{1}" -f $parts[0], $parts[-1]).ToLower()

    $initials = ($parts[0][0] + $parts[-1][0]).ToLower()
    $password = "CO-$initials$($startDate.Replace('/', ''))!@"

    Write-Host "Full Name: $fullName" -ForegroundColor Cyan
    Write-Host "Username: $username" -ForegroundColor Cyan
    Write-Host "Initial Password: $password" -ForegroundColor Cyan

    $replacements = @{
        Welcome = @{
            "[[FULL_NAME]]" = $fullName
            "[[USERNAME]]"  = $username
        }
        Secure = @{
            "[[FULL_NAME]]"  = $fullName
            "[[USERNAME]]"   = $username
            "[[PASSWORD]]"   = $password
            "[[START_DATE]]" = $startDate
        }
    }

    $userFolder = Join-Path $basePaths.DesktopRoot $username

    if (-not (Test-Path -LiteralPath $userFolder)) {
        New-Item -ItemType Directory -Path $userFolder | Out-Null
    }

    $outputPDFs = @{
        WelcomeLetter = Join-Path $userFolder "Company U.S. Welcome Letter.pdf"
        SecureLetter  = Join-Path $userFolder ($basePaths.SecurePDFNameTemplate -f $username)
    }

    Write-Host "Processing and converting documents..." -ForegroundColor Yellow

    $wordApp = New-Object -ComObject Word.Application
    $wordApp.Visible = $false
    $wordApp.DisplayAlerts = 0

    try {
        Export-ModifiedPDF `
            -WordApp $wordApp `
            -TemplatePath $basePaths.WelcomeLetterTemplate `
            -OutputPath $outputPDFs.WelcomeLetter `
            -Replacements $replacements.Welcome

        Export-ModifiedPDF `
            -WordApp $wordApp `
            -TemplatePath $basePaths.SecureLetterTemplate `
            -OutputPath $outputPDFs.SecureLetter `
            -Replacements $replacements.Secure
    }
    finally {
        $wordApp.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null
    }

    Write-Host "Process completed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    $pdfsToOpen = @(
        $outputPDFs.WelcomeLetter,
        $basePaths.SecureEmailGuide,
        $basePaths.AutoPilotGuide
    )

    foreach ($pdf in $pdfsToOpen) {
        if (
            -not [string]:: -and
            (Test-Path -LiteralPath $pdf)
        ) {
            Start-Process -FilePath "explorer.exe" -ArgumentList "`"$pdf`""
        }
    }

    if (-not [string]:: {

        # Generic company email.
        # Example: john.doe becomes john.doe@company.com
        $email = "$username@company.com"

        Set-Clipboard -Value $email

        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Company New Hire Quick Links"
        $form.Size = New-Object System.Drawing.Size(500, 200)
        $form.StartPosition = "CenterScreen"

        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "Your Company email (`"$email`") has been copied to the clipboard."
        $lbl.AutoSize = $true
        $lbl.Location = New-Object System.Drawing.Point(10, 20)
        $form.Controls.Add($lbl)

        $emailLink = New-Object System.Windows.Forms.LinkLabel
        $emailLink.Text = "Open Welcome Email Template, attach secure email, and send to new hire"
        $emailLink.LinkColor = [System.Drawing.Color]::Blue
        $emailLink.AutoSize = $true
        $emailLink.Location = New-Object System.Drawing.Point(10, 60)

        [void]$emailLink.Links.Add(
            0,
            $emailLink.Text.Length,
            $basePaths.EmailTemplate
        )

        $emailLink.add_LinkClicked({
            param($control, $linkEvent)
            [System.Diagnostics.Process]::Start($linkEvent.Link.LinkData)
        })

        $form.Controls.Add($emailLink)

        $teamsInvLink = New-Object System.Windows.Forms.LinkLabel
        $teamsInvLink.Text = "Optional New Hire IT 1:1 Introduction [Add Teams invite / Signature]"
        $teamsInvLink.LinkColor = [System.Drawing.Color]::Blue
        $teamsInvLink.AutoSize = $true
        $teamsInvLink.Location = New-Object System.Drawing.Point(10, 90)

        [void]$teamsInvLink.Links.Add(
            0,
            $teamsInvLink.Text.Length,
            $basePaths.TeamsTemplate
        )

        $teamsInvLink.add_LinkClicked({
            param($control, $linkEvent)

            $src = $basePaths.TeamsTemplateSource
            $dest = $basePaths.TeamsTemplate

            try {
                if (-not (Test-Path -LiteralPath $src)) {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Source template not found:`n$src",
                        "Template missing",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning
                    )
                    return
                }

                $destDir = Split-Path -Path $dest -Parent

                if (-not (Test-Path -LiteralPath $destDir)) {
                    New-Item `
                        -ItemType Directory `
                        -Path $destDir `
                        -Force | Out-Null
                }

                Copy-Item `
                    -LiteralPath $src `
                    -Destination $dest `
                    -Force

                Start-Process -FilePath $dest
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Failed to copy/open template:`n$($_.Exception.Message)",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        })

        $form.Controls.Add($teamsInvLink)

        [void]$form.ShowDialog()

        $notif = "New Hire folder created:`nUsername: $username`nFolder: $userFolder`nFiles:`n - $($outputPDFs.WelcomeLetter)`n - $($outputPDFs.SecureLetter)"
        Show-Notification $notif
    }
}