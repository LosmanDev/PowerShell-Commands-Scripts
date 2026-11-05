### System Information and Configuration

```powershell
# Displays detailed configuration information about the computer, including OS version, memory, and network adapters.
systeminfo

Get-ComputerInfo

# Quickly check the version of Windows you are running.
winver

(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion

################ Remove Users from Loaner ###############
$ExcludedProfiles = @("admin.losman", "liban.osman", "Public", "Default"); Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.Special -eq $false -and $_.Loaded -eq $false -and $_.LocalPath -notmatch ($ExcludedProfiles -join "|") } | Remove-CimInstance -Confirm:$false

# Local admin Exception Group
Add-LocalGroupMember -Group "Administrators" -Member "AzureAD\"
Get-LocalGroupMember -Group "Administrators"

# ###################################################################################################################
```

### System File and Image Repair

```bash
# ###################################################################################################################
  
  # Performs a detailed scan of the system image for corruption.
 DISM /Online /Cleanup-Image /RestoreHealth

  # System File Checker
 sfc /scannow

  # Scans all system files to detect and repair corrupted or missing files.
 DISM /Online /Cleanup-Image /CheckHealth

  # Quickly checks if there is any corruption in the system image.
 DISM /Online /Cleanup-Image /ScanHealth

  # Repairs detected corruption in the system image by downloading and replacing damaged files.
 DISM /Online /Cleanup-Image /StartComponentCleanup

  # Removes obsolete system files and outdated components from the Windows Component Store (WinSxS folder) to reclaim disk space, but it keeps backup components for uninstalling updates.
 Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore

  # Screen Lock 
 $wsh = New-Object -ComObject Wscript.Shell; WHILE($TRUE){$wsh.SendKeys("{SCROLLLOCK}");$wsh.SendKeys("{SCROLLLOCK}");START-SLEEP -Seconds (Get-Random -Minimum 45.1 -Maximum 110.99)}

################ tail recent DISM entries###############
Get-Content -Path C:\Windows\Logs\DISM\dism.log -Tail 200

################ tail recent Component-Based Servicing log ###############
Get-Content -Path C:\Windows\Logs\CBS\CBS.log -Tail 200

shutdown /r /t 60 /c "Restart Initiated."
shutdown /r /t 3600 /c "System maintenance in progress. This device will restart automatically in 60 minutes."

start ms-cxh:localonly # Create a local windows account
start ms-availablenetworks: # Access Network from CMD
start ms-settings:windowsupdate # Access updates
start ms-settings:workplace # Intune Sync
shutdown /r /o /f /t 0 # Windows Recovery Environment (WinRE),
shutdown /r /fw /t 0 # Motherboard Firmware Interface (UEFI / BIOS)
# ###################################################################################################################
```

### SYSTEM PROCESSES / UP-TIME / GET TEMPERATURE AND OVERALL CPU USAGE

```powershell

################ Uptime ###############

$os = Get-CimInstance Win32_OperatingSystem; New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date) | Select Days,Hours,Minutes

################ Get system Temperature ###############

Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace root/wmi | Where-Object CurrentTemperature -gt 0 | Sort-Object CurrentTemperature -Descending | Select-Object -First 1 | Select-Object InstanceName, @{Name = 'Fahrenheit'; Expression = { [math]::Round((($_.CurrentTemperature / 10 - 273.15) * 9 / 5) + 32, 1) } }

################ CPU / memory per process ###############

Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, CPU, Id

Get-DeliveryOptimizationPerfSnap | Select-Object CacheSizeBytes,AvailableDiskBytes,TotalDiskBytes

################ Kill MS sessions ###############

$TargetApps = @(
    "POWERPNT"
    "EXCEL"
    "WINWORD"
    "OneDrive"
    "OUTLOOK"
    "ms-teams"
    "Teams"
    "msedge"
    "chrome"
) $TargetApps | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Write-Host "Terminated: $($_.Name) (PID $($_.Id))" } catch { Write-Host "Failed to terminate: $($_.Name) (PID $($_.Id))" } } }

################ Reliability Monitor ###############
perfmon /rel

# This diagnostic script checks the "health" of the PC to find hidden installation blockers: it verifies if the system is unstable (low reliability score), hasn't been rebooted in over a week, is waiting for a reboot (registry locks), has the Windows Installer service stuck, or has failed recent Windows Updates.

Write-Host "Reliability Monitor" -f Cyan; $s = (Get-CimInstance Win32_ReliabilityStabilityMetrics | select -f 1).SystemStabilityIndex; Write-Host "Stability (1-10): " -NoNewline; if ($s -lt 5) { Write-Host $s -f Red }else { Write-Host $s -f Green }; $d = ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).Days; Write-Host "Uptime:             $d Days" -f $(if ($d -gt 7) { 'Yellow' }else { 'White' }); $p = @(); if (gp 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ea 0) { $p += 'CBS' }; if (gp 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ea 0) { $p += 'WU' }; if ((gp 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ea 0).PendingFileRenameOperations) { $p += 'Rename' }; Write-Host "Reboot Pending:     " -NoNewline; if ($p) { Write-Host "YES ($($p -join ','))" -f Red }else { Write-Host "NO" -f Green }; $m = (gps msiexec -ea 0); Write-Host "MSI Exec Busy:      " -NoNewline; if ($m) { Write-Host "YES" -f Yellow }else { Write-Host "NO" -f Green }; Write-Host "`nLast 5 Updates:" -f Cyan; (New-Object -Com Microsoft.Update.Searcher).QueryHistory(0, 5) | % { Write-Host ("[{0}] {1}" -f $_.Date.ToString('MM-dd'), $_.Title.SubString(0, [math]::Min(45, $_.Title.Length))) -f $(if ($_.ResultCode -eq 2) { 'Green' }else { 'Red' }) }

# ############## Software Versions installed on system ##########################
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion | Sort-Object DisplayName

# ############## Event Viwer softwares installed by recent date #####################
Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='MsiInstaller';ID=1033,11724;StartTime=(Get-Date).AddDays(-5)} | % { $m=$_.Message; [PSCustomObject]@{Time=$_.TimeCreated.ToString('MM/dd/yyyy HH:mm:ss'); Action=if($_.Id -eq 11724){"Removed"}elseif($m -match "status: 0\."){"Installed"}else{"Failed"}; Name=if($m -match "Product(?: Name)?: (.*?)(?:\. Product Version:| --)"){$Matches[1]}else{"Unknown"}; Version=if($m -match "Product Version: ([0-9.]+)"){$Matches[1]}else{"N/A"}} } | ft -AutoSize


# # ############## Show recent Application and System critical/errors with complete messages.
& { $Hours=24; $Since=(Get-Date).AddHours(-$Hours); foreach ($Log in 'Application','System') { Write-Host "`n$env:COMPUTERNAME | $Log | Last $Hours hour(s) | Latest 20 events" -ForegroundColor Cyan; try { Get-WinEvent -FilterHashtable @{LogName=$Log; Level=1,2; StartTime=$Since} -MaxEvents 20 -ErrorAction Stop | Sort-Object TimeCreated | Format-List TimeCreated,Id,LevelDisplayName,ProviderName,Message | Out-Host } catch { if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { Write-Host 'No matching events.' } else { Write-Warning "$Log query failed: $($_.Exception.Message)" } } } }


# # ############## Show WHEA and power/restart events chronologically, including Event 41 diagnostic fields.
& { $Hours=24; $Since=(Get-Date).AddHours(-$Hours); $Filters=@(@{ProviderName='Microsoft-Windows-WHEA-Logger'},@{ProviderName='Microsoft-Windows-Kernel-Power'; Id=41,42,107,109,506,507},@{ProviderName='Microsoft-Windows-Power-Troubleshooter'; Id=1},@{ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; Id=1001},@{ProviderName='EventLog'; Id=6008},@{ProviderName='User32'; Id=1074}); foreach ($Filter in $Filters) { $Filter.LogName='System'; $Filter.StartTime=$Since }; Write-Host "`n$env:COMPUTERNAME | Hardware and power timeline | Last $Hours hour(s)" -ForegroundColor Cyan; try { $Events=@(Get-WinEvent -FilterHashtable $Filters -ErrorAction Stop | Sort-Object TimeCreated,RecordId) } catch { if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { Write-Host 'No matching events.'; return }; throw }; foreach ($Event in $Events) { $Event | Format-List TimeCreated,Id,LevelDisplayName,ProviderName,Message | Out-Host; if ($Event.ProviderName -eq 'Microsoft-Windows-Kernel-Power' -and $Event.Id -eq 41) { Write-Host 'Event 41 additional data:' -ForegroundColor Cyan; ([xml]$Event.ToXml()).Event.EventData.Data | Select-Object @{Name='Field'; Expression={$_.GetAttribute('Name')}},@{Name='Value'; Expression={if ($_.GetAttribute('Name') -eq 'BugcheckCode') { '{0} (0x{0:X8})' -f [uint32]$_.InnerText } else { $_.InnerText }}} | Format-Table -AutoSize -Wrap | Out-Host } } }

# # ############## List standard Windows dump files; set CopyDumps to true to collect them into a timestamped folder.
& { $CopyDumps=$false; $ErrorActionPreference='Stop'; $Root=$env:SystemRoot.TrimEnd('\'); $Files=@(foreach ($Path in @("$Root\LiveKernelReports","$Root\Minidump","$Root\MEMORY.DMP")) { if (Test-Path -LiteralPath $Path) { Get-ChildItem -LiteralPath $Path -Filter '*.dmp' -Recurse -File -Force } }); Write-Host "`n$env:COMPUTERNAME | Dump inventory" -ForegroundColor Cyan; if ($Files.Count -eq 0) { Write-Host 'No dump files found in the standard locations.'; return }; $Files | Sort-Object LastWriteTime -Descending | Select-Object FullName,@{Name='SizeMB'; Expression={[math]::Round($_.Length/1MB,2)}},LastWriteTime | Format-Table -AutoSize -Wrap | Out-Host; if ($CopyDumps) { $Destination=Join-Path 'C:\CrashAnalysis' ("{0}_{1}_{2}" -f $env:COMPUTERNAME,(Get-Date -Format 'yyyyMMdd-HHmmss-fff'),$PID); foreach ($File in $Files) { $Target=Join-Path $Destination ($File.FullName.Substring($Root.Length+1)); New-Item -ItemType Directory -Path (Split-Path -Path $Target -Parent) -Force | Out-Null; Copy-Item -LiteralPath $File.FullName -Destination $Target; Write-Host "Copied: $($File.FullName)" }; Write-Host "`nCollection complete: $Destination" -ForegroundColor Cyan } }

# ###################################################################################################################
```
### Disk and File System
```powershell

cd "$env:USERPROFILE\downloads"

# MSIX / APPX
Add-AppxProvisionedPackage -Online -PackagePath "C:\path\app.msix" -DependencyPackagePath "C:\path\dependency.msix" -SkipLicense

# MSI
msiexec.exe /i "C:\path\installer.msi" /qn /norestart

<#
Nullsoft -> NSIS (/S)
Inno Setup -> Inno Setup (/VERYSILENT /SUPPRESSMSGBOXES /NORESTART)
InstallShield -> InstallShield (/s /v"/qn")
WiX Toolset -> WiX (-quiet)
#>
(Get-Item -Path "").VersionInfo | Format-List FileDescription, ProductName, LegalCopyright, OriginalFilename
Select-String -Path ".\installer.exe" -Pattern "Inno Setup|Nullsoft|InstallShield|WiX" -AllMatches | Select-Object -ExpandProperty Matches | Select-Object -Unique Value
#Exe 
"" <#InstallShield#> /s /v"/qn /norestart" <#Inno Setup#> /VERYSILENT /SUPPRESSMSGBOXES /NORESTART <#NSIS#> /S <#WiX Toolset#> -quiet

```
```bash
# Downloads size check
Get-ChildItem "$env:USERPROFILE\Downloads" -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum | Select-Object @{N='Folder';E={"$env:USERPROFILE\Downloads"}}, @{N='SizeMB';E={[math]::Round($_.Sum / 1MB, 2)}}, @{N='SizeGB';E={[math]::Round($_.Sum / 1GB, 2)}}

# Checks the file system and disk for errors.
echo y | chkdsk /f; echo y | chkdsk /r
 
 chkdsk
   Use /f # to fix errors.
   Use /r # to locate bad sectors and recover readable data.

  # Clean system files
 cleanmgr

# SysMain pre-loads apps into RAM Disable SysMain
Stop-Service -Name "SysMain" -Force
Set-Service -Name "SysMain" -StartupType Disabled

# Optimize System Drive
Optimize-Volume -DriveLetter C -ReTrim -Verbose

# Empty the Recycle Bin silently
Clear-RecycleBin -Force

# Clear temporary files
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

 # Search for a text string in files
 Select-String -Path  "C:\logs\apps\.log" -Pattern'error'

 # Search for strings in files (More powerful, supports regex)
 findstr /i /s /c:"password" C:\Users\*.txt # Case sensitive, search subdirs, literal string

  # To open an item "C:\".
 Invoke-Item

```
### Clear Windows Update

```powershell

# Automated Windows Update / Install / Additonal Drivers / Restart after completion
& { $AutoRestart=$true; $RestartDelay=120; $MaxMinutes=90; $MaxPasses=3; $QuietSeconds=60; $AcceptEulas=$true; $ErrorActionPreference='Stop'; if ($PSVersionTable.PSEdition -ne 'Desktop' -or -not [Environment]::Is64BitProcess) { throw 'Use 64-bit Windows PowerShell 5.1.' }; $Principal=New-Object Security.Principal.WindowsPrincipal -ArgumentList ([Security.Principal.WindowsIdentity]::GetCurrent()); if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run elevated or as local SYSTEM.' }; $Log=Join-Path $env:TEMP ('WindowsUpdate-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff')); $Started=[DateTimeOffset]::Now; $Clock=[Diagnostics.Stopwatch]::StartNew(); $Known=@{}; $Actions=@{}; $History=@{}; $Eulas=@{}; $Current=@(); $Stopped=$false; $Settled=$false; $Reason=''; function Read-UpdateState { foreach ($Update in $Manager.GetApplicableUpdates()) { $Id=[string]$Update.UpdateId; if ($AcceptEulas -and -not $Update.IsEulaAccepted -and -not $Eulas.ContainsKey($Id)) { $Eulas[$Id]=$true; try { $Update.AcceptEula(); Write-Host ('EULA accepted: {0}' -f $Update.Title) } catch { Write-Warning ('EULA acceptance failed for {0}: {1}' -f $Update.Title,$_.Exception.Message) }; }; $Progress=$Update.ActionProgress; $Attention=$Update.AttentionRequiredInfo; $Result=$Update.ActionResult; $Row=[pscustomobject]@{ Id=$Id; Type=$(if ($Update.IsDriver) {'Driver'} elseif ($Update.IsFeatureUpdate) {'Feature'} else {'Software'}); Action=[string]$Update.CurrentAction; Progress=$(if ($null -ne $Progress -and $Progress.Action -eq $Update.CurrentAction) {'{0:0}%' -f (100*$Progress.Progress)} else {'-'}); Attention=$(if ($null -ne $Attention) {[string]$Attention.Reason} else {'Not reported'}); Update=[string]$Update.Title }; $Known[$Id]=$Row; if ($null -ne $Result -and $Result.Timestamp -ge $Started) { $ErrorText=if ($null -ne $Result.ExtendedError) {'0x{0:X8}: {1}' -f [int]$Result.ExtendedError.HResult,$Result.ExtendedError.Message} else {''}; $Actions[$Id]=[pscustomobject]@{ Time=$Result.Timestamp.UtcDateTime; Action=[string]$Result.Action; Succeeded=[bool]$Result.Succeeded; Detail=$ErrorText }; }; $Row; }; }; Start-Transcript -Path $Log -Force | Out-Null; try { Add-Type -AssemblyName System.Runtime.WindowsRuntime; $Manager=[Windows.Management.Update.WindowsUpdateManager,Windows.Management.Update,ContentType=WindowsRuntime]::new('NativePowerShellUpdate'); Write-Host "`nWINDOWS UPDATE | Native orchestrator | Software + drivers" -ForegroundColor Cyan; Write-Host "Log: $Log"; try { for ($Pass=1; $Pass -le $MaxPasses; $Pass++) { $Current=@(Read-UpdateState); $PassHadUpdates=$Current.Count -gt 0; $Before=$Manager.LastSuccessfulScanTimestamp; $ExistingRestart=(@($Current | Where-Object Attention -eq 'ReadyToReboot').Count -gt 0 -and -not $Manager.IsScanning -and -not $Manager.IsWorking); $IdleFrom=$null; $Previous=''; $LastPrint=-30; $Settled=$false; if ($ExistingRestart) { Write-Host "`nRestart already pending; waiting for a stable idle state." -ForegroundColor Yellow } else { Write-Host "`nPASS $Pass/$MaxPasses - Requesting user-initiated update scan..." -ForegroundColor Cyan; $Manager.StartScan($true) }; while ($Clock.Elapsed.TotalMinutes -lt $MaxMinutes) { $Current=@(Read-UpdateState); $PassHadUpdates=$PassHadUpdates -or ($Current.Count -gt 0); $Scanning=[bool]$Manager.IsScanning; $Working=[bool]$Manager.IsWorking; $Fresh=$ExistingRestart -or ($Manager.LastSuccessfulScanTimestamp -gt $Before); $Table=if ($Current.Count) {($Current | Sort-Object Type,Update | Format-Table Type,Action,Progress,Attention,Update -AutoSize -Wrap | Out-String -Width 180).TrimEnd()} else {'No applicable updates currently listed; verifying scan and activity state.'}; $Signature="$Scanning|$Working|$Fresh|$Table"; $Changed=$Signature -ne $Previous; if ($Changed -or ($Clock.Elapsed.TotalSeconds-$LastPrint) -ge 30) { Write-Host ("`n[{0}] Scanning: {1} | Working: {2} | Scan verified/restart pending: {3}" -f (Get-Date -Format 'HH:mm:ss'),$Scanning,$Working,$Fresh) -ForegroundColor Cyan; if ($Changed) { Write-Host $Table }; $LastPrint=$Clock.Elapsed.TotalSeconds; }; if ($Fresh -and -not $Scanning -and -not $Working) { if ($null -eq $IdleFrom -or $Changed) { $IdleFrom=$Clock.Elapsed.TotalSeconds }; if (($Clock.Elapsed.TotalSeconds-$IdleFrom) -ge $QuietSeconds) { $Settled=$true; break }; } else { $IdleFrom=$null }; $Previous=$Signature; Start-Sleep -Seconds 5; }; if (-not $Settled) { $Stopped=$true; $Reason='Monitoring timed out. Windows Update may still be running; automatic restart suppressed.'; break }; if (@($Current | Where-Object Attention -eq 'ReadyToReboot').Count) { $Reason='Updates are awaiting restart.'; break }; if ($Current.Count) { $Reason='Windows Update is idle with outstanding updates; see results below.'; break }; if (-not $PassHadUpdates) { $Reason='Successful scan finished with no applicable updates listed.'; break }; if ($Pass -eq $MaxPasses) { $Reason='Scan-pass limit reached; additional updates have not been ruled out.'; break }; Write-Host 'Checking for updates made applicable by this installation cycle...'; }; $Current=@(Read-UpdateState); } catch { $Stopped=$true; $Reason='Monitoring failed: '+$_.Exception.GetBaseException().Message; Write-Warning $Reason }; try { $Reader=(New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher(); $Count=$Reader.GetTotalHistoryCount(); if ($Count -gt 0) { foreach ($Entry in $Reader.QueryHistory(0,$Count)) { if ($Entry.Date -lt $Started.UtcDateTime) { break }; if ([int]$Entry.Operation -ne 1) { continue }; $Id='{0}:{1}' -f $Entry.UpdateIdentity.UpdateID,$Entry.UpdateIdentity.RevisionNumber; if ($History.ContainsKey($Id)) { continue }; $History[$Id]=[pscustomobject]@{ Time=$Entry.Date; Code=[int]$Entry.ResultCode; ErrorCode=[int]$Entry.HResult }; if (-not $Known.ContainsKey($Id)) { $Known[$Id]=[pscustomobject]@{ Id=$Id; Type='Update'; Action='History'; Progress='-'; Attention='Not currently listed'; Update=$Entry.Title } }; }; }; } catch { Write-Warning ('Installation history unavailable; missing results remain unconfirmed: '+$_.Exception.Message) }; $Live=@{}; foreach ($Row in $Current) { $Live[$Row.Id]=$Row }; $Names='Not started','In progress','Installed','With errors','Failed','Aborted'; $Report=@(foreach ($Id in $Known.Keys) { $Row=$Known[$Id]; $Status='Unconfirmed'; $Detail='No successful installation result captured.'; $H=$History[$Id]; $A=$Actions[$Id]; if ($null -ne $H -and ($null -eq $A -or $H.Time -ge $A.Time)) { $Status=$Names[$H.Code]; $Detail=if ($H.Code -eq 2) {'Successful installation recorded in local history.'} else {'Installation HRESULT=0x{0:X8}' -f $H.ErrorCode}; } elseif ($null -ne $A) { if (-not $A.Succeeded) { $Status='Failed'; $Detail=$A.Action+': '+$A.Detail } elseif ($A.Action -in 'Install','Commit','PostReboot') { $Status='Install action OK'; $Detail=$A.Action+' succeeded; full update completion not yet confirmed in history.' } else { $Status='Incomplete'; $Detail='Last successful action: '+$A.Action }; }; if ($Live.ContainsKey($Id)) { if ($Live[$Id].Attention -eq 'ReadyToReboot') { $Status='Pending restart'; $Detail='Windows reports that a restart is required.' } elseif ($Live[$Id].Attention -notin 'None','Not reported','') { if ($Status -in 'Failed','With errors','Aborted') { $Detail+=' | Attention: '+$Live[$Id].Attention } else { $Status='Blocked'; $Detail=$Live[$Id].Attention } } elseif ($Status -eq 'Unconfirmed') { $Status='Incomplete'; $Detail='Current action: '+$Live[$Id].Action }; }; [pscustomobject]@{ Type=$Row.Type; Status=$Status; Update=$Row.Update; Detail=$Detail }; }); Write-Host "`nRESULTS | Updates observed during this run" -ForegroundColor Cyan; if ($Report.Count) { $Report | Sort-Object Status,Type,Update | Format-Table Type,Status,Update -AutoSize -Wrap | Out-Host; $Report | Where-Object Status -notin 'Installed','Pending restart' | ForEach-Object { Write-Host ('  {0}: {1}' -f $_.Update,$_.Detail) -ForegroundColor Yellow } } else { Write-Host 'No update installation was observed.' }; $Pending=@($Current | Where-Object Attention -eq 'ReadyToReboot'); $Reboot=$Pending.Count -gt 0; $RebootKnown=$true; try { $SystemInfo=New-Object -ComObject Microsoft.Update.SystemInfo; $Reboot=$Reboot -or $SystemInfo.RebootRequired } catch { $RebootKnown=$false; Write-Warning ('Additional restart-state check failed: '+$_.Exception.Message) }; Write-Host "`nPENDING RESTART" -ForegroundColor Yellow; if ($Pending.Count) { $Pending | ForEach-Object { Write-Host ('  '+$_.Update) } } elseif ($Reboot) { Write-Host '  Windows Update requires a restart; no specific update title was exposed.' } elseif ($RebootKnown) { Write-Host '  No Windows Update restart requirement reported.' } else { Write-Host '  Restart state could not be fully verified.' }; Write-Host ("`nInstalled: {0} | Install action OK: {1} | Pending restart: {2}" -f @($Report | Where-Object Status -eq 'Installed').Count,@($Report | Where-Object Status -eq 'Install action OK').Count,$Pending.Count); Write-Host $Reason; Write-Host "Log: $Log"; if ($Reboot -and $AutoRestart -and $Settled -and -not $Stopped) { if ($Manager.IsScanning -or $Manager.IsWorking) { Write-Warning 'Update activity resumed. Automatic restart was not scheduled.' } else { & "$env:SystemRoot\System32\shutdown.exe" /r /t $RestartDelay /d p:2:17 /c 'Windows updates require a restart. Save your work.'; if ($LASTEXITCODE -ne 0) { throw "Restart scheduling failed; shutdown.exe exit code $LASTEXITCODE." }; Write-Host ("Restart scheduled for {0} ({1} seconds). Cancel with: shutdown.exe /a" -f (Get-Date).AddSeconds($RestartDelay).ToString('HH:mm:ss'),$RestartDelay) -ForegroundColor Yellow; }; } elseif ($Reboot) { Write-Host 'Restart required; no automatic restart scheduled.' -ForegroundColor Yellow } else { Write-Host 'No restart scheduled.' }; } finally { $Clock.Stop(); Stop-Transcript | Out-Null; Write-Host "Saved log: $Log" }; }

 # Windows will immediately create a fresh, empty SoftwareDistribution folder. It forgets all downloaded update files and local history, forcing a full scan against the update server (Intune/WSUS) on the next cycle.
$s = "wuauserv","bits","cryptsvc","dosvc"; Stop-Service $s -Force -ea 0; Remove-Item "$env:windir\SoftwareDistribution.bak" -Recurse -Force -ea 0; Rename-Item "$env:windir\SoftwareDistribution" "SoftwareDistribution.bak" -Force; Start-Service $s -ea 0

# Windows update History
Write-Host ">>> 1. Installed OS Patches (Get-HotFix) <<<" -f Cyan; $hf = Get-HotFix -ea 0 | sort InstalledOn -Desc | select -f 10; if ($hf) { $hf | select HotFixID, Description, InstalledBy, @{N='InstalledOn';E={$_.InstalledOn.ToString('yyyy-MM-dd')}} | ft -Auto | Out-String | Write-Host -f White } else { Write-Host "No hotfix records returned." -f DarkGray }; Write-Host ">>> 2. WUA History (Non-Defender) <<<" -f Cyan; $u = New-Object -Com Microsoft.Update.Searcher; $c = $u.GetTotalHistoryCount(); if ($c -gt 0) { $u.QueryHistory(0, [math]::Min($c, 100)) | ? { $_.Title -and $_.Title -notmatch 'Security Intelligence|Definition Update|Defender' } | select -f 10 | % { $st = switch ($_.ResultCode) { 1 {'InProgress'} 2 {'Succeeded '} 3 {'Warn      '} 4 {'Failed    '} 5 {'Aborted   '} default {'Unknown   '} }; $col = switch ($_.ResultCode) { 1 {'Cyan'} 2 {'Green'} 3 {'Yellow'} 4 {'Red'} default {'Gray'} }; Write-Host ("[{0}] [{1}] {2}" -f $_.Date.ToString('yyyy-MM-dd HH:mm'), $st, $_.Title) -f $col } } else { Write-Host "WUA history is empty." -f DarkGray }; Write-Host "`n>>> 3. WU Event Log (IDs 19/20/43) <<<" -f Cyan; $ev = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-WindowsUpdateClient/Operational'; Id=19,20,43} -MaxEvents 50 -ea 0 | ? { $_.Message -notmatch 'Security Intelligence|Definition Update|Defender' } | select -f 10; if ($ev) { $ev | % { $col = switch ($_.Id) { 19 {'Green'} 20 {'Red'} 43 {'Yellow'} }; Write-Host ("[{0}] [ID {1}] {2}" -f $_.TimeCreated.ToString('yyyy-MM-dd HH:mm'), $_.Id, ($_.Message -replace '[\r\n]+',' ')) -f $col } } else { Write-Host "No WU events found." -f DarkGray }

# Removed targeted driver from windows update
$Target = "49.0.4395.18315";(New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0 and Type='Driver'").Updates | Where-Object { $_.Title -match $Target } | Select-Object Title, DriverHardwareID, DriverModel, DriverClass

$hwId = "usb\vid_03f0&pid_2754&mi_04"; Get-PnpDevice | Where-Object { $_.HardwareID -contains $hwId -or $_.InstanceId -like "*$hwId*" } | Select-Object Status, Present, Problem, Class, FriendlyName, InstanceId

pnputil /remove-device "USB\VID_03F0&PID_2754&MI_04\9&A6C2DB&0&C004"; $Target = "49.0.4395.18315"; (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0 and Type='Driver'").Updates | Where-Object { $_.Title -match $Target } | ForEach-Object { $_.IsHidden = $true }

```
### Network Information

### Advanced WiFi Settings
#### Devmgmt.msc > Network adapters > (e.g., Intel Wi-Fi 6E AX211) and select Properties > Advanced
- Set wireless mode to `802.11n` Isolating a specific 5GHz/6GHz band-steering failure or a known compatibility failure with legacy access points.
- MIMO Power Save Mode set to `No SMPS` Intermittent connection drops / High latency or packet loss during Zoom/Teams calls / Network instability occurring primarily when the device operates on battery power
- Roaming Aggressiveness set to `Highest` The user explicitly reports losing connection while walking between conference rooms or floors

```bash
 ipconfig /all # Shows detailed network configuration, including IP address, DNS, and MAC addresses.
 netstat -an # # Displays active connections and listening ports.
 ipconfig # Displays current network settings.

 ipconfig /release # Releases the current IP address assigned to the device’s network adapter.
 ipconfig /flushdns # Flushes the DNS cache to resolve DNS-related issues.
 ipconfig /renew # Renews the IP address from the DHCP server.

 #Restart Required
 netsh winsock reset # Resets the Winsock catalog to a clean state (fixes network stack issues).
 netsh int ip reset # Resets TCP/IP settings to default (useful for network troubleshooting).

 Start-Process powershell -Verb RunAs -ArgumentList '-NoExit', '-Command', 'ipconfig /release; ipconfig /flushdns; ipconfig /renew; netsh winsock reset' 

ping -f -l 1472 8.8.8.8; ping -f -l 1464 8.8.8.8; ping -f -l 1450 8.8.8.8; ping -f -l 1350 8.8.8.8

netsh interface ipv4 show subinterfaces

netsh interface ipv4 set subinterface "Ethernet 5" mtu=1395 store=persistent

# Test Intune connection
Test-NetConnection -ComputerName manage.microsoft.com -Port 443
Test-NetConnection -ComputerName enterpriseregistration.windows.net -Port 443
 
 # ###################################################################################################################
```

### Group Policy and Intune Policies / Troubleshooting 

```bash
 gpupdate /force # Forces a refresh of Group Policy settings.
 wmic qfe list # Lists all installed Windows updates (useful for checking patch status).
 gpresult /h # List all the policies applied and security groups in HTML.
 dsregcmd /status # Confirm the Device is Enrolled in Intune.
 dsregcmd /refreshprt # Forces the device to immediately refresh its Primary Refresh Token (PRT) re-establishing authentication state
 dsregcmd /forcerecovery

& "$env:windir\system32\deviceenroller.exe" /c /AutoEnrollMDM # utilizes Primary Refresh Token (PRT) endpoints configured as AzureAdJoined:YES and DomainJoined:NO.

```
```powershell

# Force Windows device to immediately check in with Microsoft Intune and sync win32 apps and compliance

Start-Process "intunemanagementextension://syncapp"; Start-Sleep -Seconds 2; Start-Process "intunemanagementextension://synccompliance"

# Trigger Native OMA-DM (CSPs, Policies, Certificates)

$StartTime = Get-Date; Write-Host ">>> Triggering Native OMA-DM Sync (Schedule #3) <<<" -f Cyan; $Tasks = Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\*" -ea 0 | ? { $_.TaskName -match '^Schedule #3' }; if (-not $Tasks) { Write-Host "[!] Schedule #3 task not found." -f Red } else { $Tasks | select TaskPath, TaskName, State, @{N="RunAs";E={$_.Principal.UserId}} | ft -Auto | Out-String | Write-Host -f DarkGray; $Tasks | Start-ScheduledTask; Write-Host "[*] Task executed. Suspending 10 seconds for log generation..." -f Yellow; Start-Sleep 10; Write-Host "`n>>> OMA-DM Admin Events (Post-Trigger) <<<" -f Cyan; Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"; StartTime=$StartTime} -ea 0 | select TimeCreated, Id, LevelDisplayName, @{N='Message';E={$_.Message -replace '[\r\n]+',' '}} | ft -Auto | Out-String | Write-Host -f White; Write-Host "`n>>> Critical AAD & MDM Failures (Last 10 Warnings/Errors) <<<" -f Red; Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-AAD/Operational','Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'; Level=2,3} -MaxEvents 10 -ea 0 | select TimeCreated, Id, LogName, @{N='Message';E={$_.Message -replace '[\r\n]+',' '}} | fl | Out-String | Write-Host -f DarkYellow }

# To force Intune to execute the script again, you must delete the local policy tracking keys. 

Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies" -Recurse -Force; Restart-Service -Name "IntuneManagementExtension" -Force 

Function Reset-Intune { Write-Host ">>> RESETTING INTUNE AGENT <<<"; Stop-Service "IntuneManagementExtension" -Force -ErrorAction SilentlyContinue; "AgentExecutor", "Microsoft.Management.Services.IntuneWindowsAgent" | ForEach-Object { Get-Process $_ -ErrorAction SilentlyContinue | Stop-Process -Force }; Remove-Item "C:\ProgramData\Microsoft\IntuneManagementExtension" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies" -Recurse -Force -ErrorAction SilentlyContinue; dsregcmd /refreshprt; Start-Service "IntuneManagementExtension"; Get-ScheduledTask | Where-Object { $_.TaskName -eq 'PushLaunch' } | Start-ScheduledTask; Write-Host ">>> DONE. Sync Triggered. <<<" }; Reset-Intune

# Search for GUID

$g="b8219c8d-14ec-4ad8-8de1-0ce1550e7a21"; reg query "HKLM\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps" /s /f $g /k

# Remove app GUID that failed to install from Intune.

$g="b8219c8d-14ec-4ad8-8de1-0ce1550e7a21"; reg query "HKLM\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps" /s /f $g /k | Select-String "HKEY_LOCAL_MACHINE" | ForEach-Object { Remove-Item -Path $_.Line.Trim().Replace("HKEY_LOCAL_MACHINE", "HKLM:") -Recurse -Force }; Restart-Service "IntuneManagementExtension" -Force

 # ###################################################################################################################
```

### Power Management

```bash
 powercfg /h on/off # Enables or disables hibernation mode.
 powercfg /batteryreport # Generates a detailed battery health report.
 powercfg /energy # Generates an energy efficiency report.
 powercfg.cpl
 ```

```powershell
# Quick extraction of battery report
 powercfg /batteryreport /output "$env:TEMP\br.html" > $null; $h = Get-Content "$env:TEMP\br.html" -Raw; $o = [regex]::Match($h, '(?s)Since OS install.*?<td class="hms">([^<]+)</td>.*?<div[^>]*>([^<]+)</div>.*?<td class="hms">([^<]+)</td>.*?<div[^>]*>([^<]+)</div>'); [PSCustomObject]@{ 'Design Capacity' = [regex]::Match($h, 'DESIGN CAPACITY</span></td><td>(.*?)\s*mWh').Groups[1].Value; 'Full Charge Capacity' = [regex]::Match($h, 'FULL CHARGE CAPACITY</span></td><td>(.*?)\s*mWh').Groups[1].Value; 'Cycle Count' = [regex]::Match($h, 'CYCLE COUNT</span></td><td>([^<]+)</td>').Groups[1].Value; 'Active (Full Charge)' = $o.Groups[1].Value; 'Standby (Full Charge)' = $o.Groups[2].Value; 'Active (Design Capacity)' = $o.Groups[3].Value; 'Standby (Design Capacity)' = $o.Groups[4].Value }

# Quick extraction of energy report
 powercfg /energy /output "$env:TEMP\energy.html" > $null; $h = Get-Content "$env:TEMP\energy.html" -Raw; [regex]::Matches($h, '(?i)(?s)<div class="[^"]*(error|warning|info)-log-entry[^"]*">.*?<div class="log-entry-header">(.*?)</div>.*?<div class="log-entry-description">(.*?)</div>(.*?)<span></span></div>') | ForEach-Object { $s=$_.Groups[1].Value.ToUpper(); $c=switch($s){'ERROR'{'Red'}'WARNING'{'Yellow'}default{'Cyan'}}; Write-Host ("[{0}] {1}" -f $s, $_.Groups[2].Value.Trim()) -ForegroundColor $c; $d=$_.Groups[3].Value.Trim(); if($d){ Write-Host ("  " + ($d -replace '\s+', ' ')) -ForegroundColor $c }; [regex]::Matches($_.Groups[4].Value, '(?i)(?s)<td[^>]*>(?:<span[^>]*>)?(.*?)(?:</span>)?</td>\s*<td[^>]*>(.*?)</td>') | ForEach-Object { Write-Host ("    {0,-35} : {1}" -f ($_.Groups[1].Value.Trim() -replace '\s+', ' '), ($_.Groups[2].Value.Trim() -replace '\s+', ' ')) -ForegroundColor $c }; Write-Host "" }

# Event Viewer Battery reports [524 Critical]
 Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Kernel-Power'; ID=@(524)} | Select-Object TimeCreated, Id, @{Name='Context'; Expression={switch($_.Id){524{'Critical Battery Depletion'}}}}, Message | Format-Table -AutoSize -Wrap

# Hardware state and identify Plug and Play (PnP) errors
Get-PnpDevice -Class Camera, Image
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' -and $_.Status -ne 'OK' }

# Cleared the corrupted instances 
Get-PnpDevice -Class Camera | Where-Object Status -eq 'Unknown' | ForEach-Object { pnputil /remove-device $_.InstanceId }. 
<# 
Disconnect the external USB dock or hub from the Surface Laptop.
Sever external power to the dock/hub for 15 seconds to drain residual capacitor charge.
Connect a single camera directly into a native port on the Laptop, bypassing all external routing.
Reset Video Subsystem Force clear the Windows video routing service.
#>
Restart-Service -Name FrameServer -Force
pnputil /scan-devices

 # ###################################################################################################################
```
### Drive Encryption

```bash
 manage-bde -status # Displays the BitLocker encryption status of drives.
 manage-bde C: -off # Decrypts the system drive (turns off BitLocker encryption).
 manage-bde -on C: -RecoveryPassword

 # ###################################################################################################################
```

```bash

dsa.msc # AD Run
ncpa.cpl # Network Run
gpmc.msc # Group policy
mmsys.cpl # Audio
compmgmt.msc #computer management
sysdm.cpl # System props (Add more RAM)
appwiz.cpl # control panel applications
certlm.msc # Certificates

# ###################################################################################################################
```

````powershell

# ###################################################################################################################

# ############### System Policies pushed from Intune ###############

gci 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device' -Rec | % { $p=$_.Name; $c=($p -replace '.*\\device\\?','').Split('\')[0]; $_|gp|% { $_.PSObject.Properties | ? Name -notmatch '^PS' | % { [pscustomobject]@{Source='PolicyManager'; Category=$c; Name=$_.Name; Value=$_.Value; Key=$p} } } } | sort Category,Name | ogv -Title 'Policy Manager View'

# ############### Check if 3 agents are running ###############

Get-Service | Where-Object { $_.Name -match "csc_umbrellaagent|stAgentSvc|CSFalconService|IntuneManagementExtension" } | Format-Table Name, Status

Get-Service | Where-Object { $_.Name -match "stAgentSvc" } | Format-Table Name, Status

Get-Process -Name 'stAgent*' -ErrorAction SilentlyContinue | Stop-Process -Force

# ############### Remove Cisco #####################################################################

"csc_ui.exe", "csc_ui_toast.exe", "vpnui.exe", "vpnagent.exe", "ciscod.exe" | ForEach-Object { taskkill /F /IM $_ /T 2>$null }; @("C:\Program Files (x86)\Cisco\Cisco Secure Client", "C:\ProgramData\Cisco\Cisco Secure Client") | Where-Object { Test-Path $_ } | ForEach-Object { takeown /F $_ /R /D Y | Out-Null; icacls $_ /grant Administrators:F /T /C /Q | Out-Null; Remove-Item -Path $_ -Recurse -Force }

@("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall") | Get-ChildItem | Get-ItemProperty | Where-Object { $_.DisplayName -match "Cisco Secure Client" } | ForEach-Object { Remove-Item -Path $_.PSPath -Recurse -Force }; @("HKLM:\SOFTWARE\Cisco\Cisco Secure Client", "HKLM:\SOFTWARE\WOW6432Node\Cisco\Cisco Secure Client") | Where-Object { Test-Path $_ } | Remove-Item -Recurse -Force

Stop-Service -Name "csc_umbrellaagent" -Force -EA SilentlyContinue; sc.exe delete "csc_umbrellaagent" | Out-Null; Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\csc_umbrellaagent" -Recurse -Force -EA SilentlyContinue

# ############### Remove Configmgr/SCCM #####################################################################

if (Test-Path "C:\Windows\ccmsetup\ccmsetup.exe") { Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/uninstall" -Wait -NoNewWindow }

# ###################################################################################################################

# ############### Chrome/Edge Bookmarks ###############

%LOCALAPPDATA%\Google\Chrome\User Data\Default
%LOCALAPPDATA%\Microsoft\Edge\User Data\Default

```bash

################ Local Outlook signatures→ OneDrive backup ###############

%appdata%\Microsoft\Signatures
$src="$env:APPDATA\Microsoft\Signatures";$dst="$env:USERPROFILE\OneDrive - BeiGene\Desktop\Signatures";if(!(Test-Path $dst)){New-Item $dst -ItemType Directory|Out-Null};Copy-Item "$src\*" $dst -Recurse -Force
################ Reverse: OneDrive
$src="$env:USERPROFILE\OneDrive - BeiGene\Desktop\Signatures";$dst="$env:APPDATA\Microsoft\Signatures";if(!(Test-Path $dst)){New-Item $dst -ItemType Directory|Out-Null};Move-Item "$src\*" $dst -Recurse -Force

```
# ############################## Office 365 Full repair ##############################

$c = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'; Start-Process 'C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeClickToRun.exe' -ArgumentList "scenario=Repair platform=$($c.Platform) culture=$($c.ClientCulture) RepairType=FullRepair DisplayLevel=False forceappshutdown=True"; Start-Sleep 5; while ($s = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun' -Name ExecutingScenario -ErrorAction SilentlyContinue).ExecutingScenario) { Write-Host "$(Get-Date -Format 'HH:mm:ss') - Active Scenario: $s"; Start-Sleep 15 }; Write-Host "Repair complete."

# Read logs on progress
& { $dirs=@("$env:windir\Temp",$env:TEMP,"$env:windir\System32\config\systemprofile\AppData\Local\Temp","$env:SystemDrive\Users\*\AppData\Local\Temp"); while($true){ Write-Host "`n========== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') =========="; $svc=Get-CimInstance Win32_Service -Filter "Name='ClickToRunSvc'" -ErrorAction Stop; if($svc){ Write-Host "ClickToRunSvc: $($svc.State) | Service PID: $($svc.ProcessId)" }else{ Write-Host 'ClickToRunSvc not found.' }; $p=@(Get-CimInstance Win32_Process -Filter "Name='OfficeClickToRun.exe' OR Name='OfficeC2RClient.exe'" -ErrorAction Stop); if($p.Count){ $p | Select-Object Name,ProcessId,@{n='Role';e={if($svc -and $_.ProcessId -eq $svc.ProcessId){'Service'}else{'Other C2R process'}}},CreationDate,@{n='CPUSeconds';e={[math]::Round(($_.KernelModeTime+$_.UserModeTime)/10000000,2)}},CommandLine | Format-List | Out-Host }else{ Write-Host 'No matching Click-to-Run processes found; outcome not verified.' }; $logs=@(Get-ChildItem -Path $dirs -Filter "$env:COMPUTERNAME-*.log" -File -ErrorAction SilentlyContinue | Sort-Object FullName -Unique | Sort-Object LastWriteTime -Descending | Select-Object -First 3); if($logs.Count){ foreach($log in $logs){ Write-Host "`nLOG: $($log.FullName) | Last write: $($log.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) | Bytes: $($log.Length)"; Get-Content -LiteralPath $log.FullName -Tail 15 -ErrorAction Continue | Out-Host } }else{ Write-Warning 'No matching Office logs found in accessible checked folders; outcome unknown.' }; Start-Sleep -Seconds 10 } }

# ############################## Delete OST and clear cache Teams/Outlook ##############################

Stop-Process -Name "OUTLOOK" -Force -ea 0; Get-CimInstance Win32_UserProfile | ? { !$_.Special -and $_.Loaded } | % { $l="$($_.LocalPath)\AppData\Local\Microsoft\Outlook"; "$l\*.ost", "$l\RoamCache\*", "$l\HubAppFileCache\*", "$l\Offline Address Books\*" | Remove-Item -Recurse -Force -ea 0 }

Stop-Process -Name "Teams" -Force -ea 0; Get-CimInstance Win32_UserProfile | ? { !$_.Special -and $_.Loaded } | % { $r="$($_.LocalPath)\AppData\Roaming\Microsoft\Teams"; "$r\*" | Remove-Item -Recurse -Force -ea 0 }

# Reduce OST size
Stop-Process -Name "OUTLOOK","SearchProtocolHost","ms-teams" -Force -ea 0; Get-CimInstance Win32_UserProfile | ? { !$_.Special } | % { $l="$($_.LocalPath)\AppData\Local\Microsoft\Outlook"; "$l\*.ost","$l\RoamCache\*","$l\HubAppFileCache\*","$l\Offline Address Books\*" | Remove-Item -Recurse -Force -ea 0 }; Get-ChildItem Registry::HKEY_USERS | ? { $_.Name -match "S-1-(5-21|12-1)-[\d\-]+$" } | % { foreach ($k in "Software\Microsoft\Office\16.0\Outlook\Cached Mode","Software\Policies\Microsoft\Office\16.0\Outlook\Cached Mode") { $p="$($_.PSPath)\$k"; if(!(Test-Path $p)){New-Item $p -Force|Out-Null}; Set-ItemProperty $p -Name "SyncWindowSetting" -Value 3 -Type DWord; Set-ItemProperty $p -Name "SyncWindowSettingDays" -Value 0 -Type DWord } }

# ############################## Outlook Monthly Channel ##############################

"POWERPNT","EXCEL","WINWORD","OUTLOOK" | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Write-Host "Terminated: $($_.Name) (PID $($_.Id))" } catch { Write-Host "Failed to terminate: $($_.Name) (PID $($_.Id))" } } }

Set-Location "C:\Program Files\Common Files\Microsoft Shared\ClickToRun"; .\OfficeC2RClient.exe /changesetting Channel=MonthlyEnterprise; .\OfficeC2RClient.exe /update user

$Monthly = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"; & $Monthly /changesetting Channel=MonthlyEnterprise; & $Monthly /update user

# ############################## Outlook Legacy Room Finder ##############################

$s=(Get-CimInstance Win32_UserProfile | ? LocalPath -match "first.last").SID; $p1="Registry::HKEY_USERS\$s\SOFTWARE\Policies\Microsoft\Office\16.0\Outlook\Options\Calendar"; $p2="Registry::HKEY_USERS\$s\SOFTWARE\Microsoft\Office\16.0\Outlook\Preferences"; if(!(Test-Path $p1)){New-Item $p1 -Force | Out-Null}; New-ItemProperty -Path $p1 -Name "ShowLegacyRoomFinder" -Value 1 -PropertyType DWord -Force | Out-Null; if(!(Test-Path $p2)){New-Item $p2 -Force | Out-Null}; New-ItemProperty -Path $p2 -Name "RoomFinderForceWebView" -Value 0 -PropertyType DWord -Force | Out-Null

# ############################## Edge Fix ##############################

Remove-Item -Path "C:\Program Files (x86)\Microsoft\Edge\Application\149.*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Program Files (x86)\Microsoft\EdgeUpdate\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

$ClientKeys = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}",
    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
)
foreach ($Key in $ClientKeys) { Remove-Item -Path $Key -Recurse -Force -ErrorAction SilentlyContinue }

Start-Process msiexec.exe -ArgumentList '/i "C:\Users\first.last\Downloads\MicrosoftEdgeEnterpriseX64.msi" /qn /norestart /L*V "C:\edge_install.log"' -Wait -NoNewWindow

https://www.microsoft.com/en-us/edge/business/download?form=MA13FJ

# ############################## Teams Add-in Fix ##############################

Set-Location -Path "$env:LOCALAPPDATA\Publishers\8wekyb3d8bbwe\TeamsSharedConfig"; '{"defaultApp":1,"cohort":"","webAccountId_AAD":"","cohortStage":"","userId_AAD":"","previousT1MachineId":"","previousT1SessionId":""}' | Out-File -FilePath ".\app_switcher_settings.json" -Encoding utf8

# Exit Teams(From Tray as well) and outlook completely. Open teams and wait 1 minute then open outlook and the addin in should be there.

# If not close outlook and teams again, repair Teams add-in in settings > apps > teams-addin. reboot both apps. 

# ############################## Chrome CA policy fix ##############################

If you see this issue when open company resources by Chrome, even you have installed the Chrome extension on Windows. You can try to add the following registry key: 
[HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome]"CloudAPAuthEnabled"=dword:00000001 

if (!(Test-Path "HKLM:\Software\Policies\Google\Chrome")) { New-Item -Path "HKLM:\Software\Policies\Google\Chrome" -Force | Out-Null }; Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "CloudAPAuthEnabled" -Value 1 -Type DWord

# ############################## Walk Me removal ##############################

$paths='HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist','HKCU:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist'; $id='hljogmncibpgfgkbbjgjjbfkjdbfkjmn'; $paths|%{if(Test-Path $_){(Get-ItemProperty $_).PSObject.Properties|?{$_.Value -like "*$id*"}|%{Remove-ItemProperty $_.PSPath -Name $_.Name -Force}}}; Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue

````

### AUTOMATED SOFTWARE INSTALLS

```powershell

# Incognito Edge
Start-Process msedge -ArgumentList "-inprivate"

# ############### Lenovo System Update ##############################

Add-Type -A System.Windows.Forms,System.Drawing; function n($m){$b=New-Object System.Windows.Forms.NotifyIcon;$b.Icon=[System.Drawing.SystemIcons]::Information;$b.Visible=$true;$b.ShowBalloonTip(5000,'Software Install',$m,[System.Windows.Forms.ToolTipIcon]::Info);sleep -m 600;$b.Dispose()}; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $u='https://download.lenovo.com/pccbbs/thinkvantage_en/system_update_5.08.03.59.exe'; $p="$env:TEMP\lenovo_update.exe"; n 'Downloading Lenovo System Update...'; (New-Object System.Net.WebClient).DownloadFile($u, $p); n 'Installing Lenovo System Update Client...'; start $p -Arg '/VERYSILENT /NORESTART' -Wait; ri $p -Force; foreach($k in @('HKLM:\SOFTWARE\Policies\Lenovo\System Update\UserSettings\General','HKLM:\SOFTWARE\WOW6432Node\Policies\Lenovo\System Update\UserSettings\General')){if(!(Test-Path $k)){New-Item -Path $k -Force|Out-Null};Set-ItemProperty -Path $k -Name 'AdminCommandLine' -Value '/CM -search A -action INSTALL -includerebootpackages 3 -noicon -noreboot -nolicense -exporttowmi' -Force}; $pref='HKLM:\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\General'; if(Test-Path $pref){Set-ItemProperty -Path $pref -Name 'DisplayLicenseNotice' -Value 'NO' -Force;Set-ItemProperty -Path $pref -Name 'AskBeforeClosing' -Value 'NO' -Force}; $tv="${env:ProgramFiles(x86)}\Lenovo\System Update\tvsu.exe"; if(!(Test-Path $tv)){$tv="$env:ProgramFiles\Lenovo\System Update\tvsu.exe"}; n 'Scanning and installing Lenovo drivers...'; start $tv -Arg '/CM'; for($i=0;$i -lt 15 -and !(Get-Process Tvsukernel -EA SilentlyContinue);$i++){sleep 1}; while(Get-Process Tvsukernel,tvsu -EA SilentlyContinue){sleep 5}; n 'Lenovo Drivers Installed Successfully'; sleep 2

################ Surface Laptop 5 ############### 
# https://www.microsoft.com/en-us/download/details.aspx?id=104679

Add-Type -A System.Windows.Forms,System.Drawing; function n($m){$b=New-Object System.Windows.Forms.NotifyIcon;$b.Icon=[System.Drawing.SystemIcons]::Information;$b.Visible=$true;$b.ShowBalloonTip(5000,'Software Install',$m,[System.Windows.Forms.ToolTipIcon]::Info);sleep -m 600;$b.Dispose()}; if ((Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/details.aspx?id=104679" -UseBasicParsing).Content -match 'href="(https://download\.microsoft\.com/download/[^"]+/SurfaceLaptop5[^"]+\.msi)"') { $u=$matches[1] } else { throw "Link extraction failed" }; $p="$env:TEMP\surface5_update.msi"; n 'Downloading Surface Laptop 5 Drivers...'; (New-Object System.Net.WebClient).DownloadFile($u,$p); n 'Installing Surface Laptop 5 Drivers...'; start msiexec -Arg "/i `"$p`" /qn /norestart" -Wait; ri $p -Force; n 'Surface Laptop 5 Drivers Installed Successfully'; sleep 2


################ Surface Laptop 6 ############### 
# https://www.microsoft.com/en-us/download/details.aspx?id=105946

Add-Type -A System.Windows.Forms,System.Drawing; function n($m){$b=New-Object System.Windows.Forms.NotifyIcon;$b.Icon=[System.Drawing.SystemIcons]::Information;$b.Visible=$true;$b.ShowBalloonTip(5000,'Software Install',$m,[System.Windows.Forms.ToolTipIcon]::Info);sleep -m 600;$b.Dispose()}; if ((Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/details.aspx?id=105946" -UseBasicParsing).Content -match 'href="(https://download\.microsoft\.com/download/[^"]+/SurfaceLaptop6forBusiness[^"]+\.msi)"') { $u=$matches[1] } else { throw "Link extraction failed" }; $p="$env:TEMP\surface6_update.msi"; n 'Downloading Surface Laptop 6 Drivers...'; (New-Object System.Net.WebClient).DownloadFile($u,$p); n 'Installing Surface Laptop 6 Drivers...'; start msiexec -Arg "/i `"$p`" /qn /norestart" -Wait; ri $p -Force; n 'Surface Laptop 6 Drivers Installed Successfully'; sleep 2

################ Surface Laptop 7 ############### 
# https://www.microsoft.com/en-us/download/details.aspx?id=108014

Add-Type -A System.Windows.Forms,System.Drawing; function n($m){$b=New-Object System.Windows.Forms.NotifyIcon;$b.Icon=[System.Drawing.SystemIcons]::Information;$b.Visible=$true;$b.ShowBalloonTip(5000,'Software Install',$m,[System.Windows.Forms.ToolTipIcon]::Info);sleep -m 600;$b.Dispose()}; if ((Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/details.aspx?id=108014" -UseBasicParsing).Content -match 'href="(https://download\.microsoft\.com/download/[^"]+/SurfaceLaptop7withIntel[^"]+\.msi)"') { $u=$matches[1] } else { throw "Link extraction failed" }; $p="$env:TEMP\surface7_update.msi"; n 'Downloading Surface Laptop 7 Drivers...'; (New-Object System.Net.WebClient).DownloadFile($u,$p); n 'Installing Surface Laptop 7 Drivers...'; start msiexec -Arg "/i `"$p`" /qn /norestart" -Wait; ri $p -Force; n 'Surface Laptop 7 Drivers Installed Successfully'; sleep 2

################ Chrome ###############

Add-Type -A System.Windows.Forms,System.Drawing; function n($m){$b=New-Object System.Windows.Forms.NotifyIcon;$b.Icon=[System.Drawing.SystemIcons]::Information;$b.Visible=$true;$b.ShowBalloonTip(5000,'Software Install',$m,[System.Windows.Forms.ToolTipIcon]::Info);sleep -m 600;$b.Dispose()}; $u='https://dl.google.com/chrome/install/latest/chrome_installer.exe'; $p="$env:TEMP\chrome_installer.exe"; n 'Downloading Google Chrome...'; (New-Object System.Net.WebClient).DownloadFile($u, $p); n 'Installing Google Chrome...'; start $p -Arg '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait; ri $p -Force; n 'Google Chrome Installed Successfully'; sleep 2

```
# Zsh/Bash Commands

```bash
############################################# MAC OS Commands ######################################################################

rm ~/Library/Preferences/com.apple.finder.plist

# Kill the process to force regeneration by typing
killall Finder

# System capacity
df -h /   

# Display system memory pressure statistics
memory_pressure

# print the top 20 largest ghost files
sudo lsof +L1 | awk '{print $1, $2, $3, $7, $10}' | sort -nk 4 | tail -n 20

sudo du -sh /System/Volumes/Data/Library/* 2>/dev/null | sort -rh | head -n 10

sudo du -sh /Library/SystemExtensions/.* 2>/dev/null | sort -rh | head -n 5

sudo find /Library/SystemExtensions/.staging -name "*.systemextension" | head -n 20

# Find specific bloated temp folder
sudo du -sh /private/var/folders/*/* | sort -rh | head -n 10

# Size of virtual memory
ls -lh /private/var/vm

# See exactly how much space snapshots are taking by opening Terminal and running:
tmutil listlocalsnapshots /

# Identify large directories within the hidden Library folder:
du -sh ~/Library/* | sort -rh | head -n 15

# To reset Spotlight
sudo mdutil -E /

# Check System Temp Bloat
sudo du -sh /private/var/folders/* | sort -rh


 ############################## JAMF / MDM ############################## 

while true; do osascript -e 'tell application "System Events" to key code 59'; sleep $((45 + RANDOM % 66)); done

# Jamf Log File Diagnostics
cat /var/log/jamf.log

# Retrieves native Apple MDM framework logs generated within the last 60 minutes.
log show --predicate 'subsystem == "com.apple.MDM"' --last 1h 

# Streams real-time execution logs for the Jamf binary.
log stream --predicate 'process == "jamf"' 
log show --predicate 'subsystem CONTAINS "jamfAAD"' --last 1h

# Forces execution of pending policies scoped to the device.
sudo jamf policy 

# Initiates an inventory collection and submits data to the Jamf Pro server.
sudo jamf recon 

# Re-applies the management framework and MDM profile.
sudo jamf manage 

# Prompts for user-level MDM profile installation if missing.
sudo jamf mdm -userLevelMdm 

# Validates that the macOS endpoint holds an active, verified MDM profile.
profiles status -type enrollment

# Forces JamfAAD to authenticate with Entra ID, fetch the Azure Device ID, and report the state to Jamf Pro.
/usr/local/jamf/bin/jamfaad gatherAADInfo

# Removes corrupted Entra ID tokens from the user keychain and clears preferences. Triggers a new JamfAAD authentication prompt to rebuild the compliance state.
/usr/local/jamf/bin/jamfAAD clean

############################### System & Hardware Auditing ############################## 

# Outputs hardware UUID, serial number, processor architecture, and memory configuration.
system_profiler SPHardwareDataType 

# Displays system uptime and load averages.

# Display the installed macOS version.
sw_vers

# Device uptime 
uptime 
```
```powershell

# 1. Verify if the key is still present after a fresh reboot
Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'

# 2. Revert stuck pending servicing actions (safe native method)
DISM.exe /Online /Cleanup-Image /RevertPendingActions


# Attempts DISM/SFC repairs and component-store cleanup, deletes temporary files older than seven days from Windows and executing-account temp folders, empties that account's system-drive Recycle Bin, optimizes the system drive, requests idle-sleep prevention, displays progress, logs results, and forces a restart after a cancellable 120-second countdown when the desktop is available and safety checks pass.

& { [CmdletBinding()] param( [ValidateRange(1,2)][int]$StartStep = 1, [ValidateRange(1,1440)][int]$StepTimeoutMinutes = 360, [ValidateRange(15,300)][int]$StartupTimeoutSeconds = 30, [switch]$Preview ); & { $ErrorActionPreference = 'Stop'; if ($env:OS -ne 'Windows_NT') { throw 'Windows is required.' }; if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5) { throw 'Paste this into elevated Windows PowerShell 5.1 (powershell.exe), not pwsh.' }; $identity = [Security.Principal.WindowsIdentity]::GetCurrent(); $principal = New-Object Security.Principal.WindowsPrincipal($identity); if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'An already elevated PowerShell shell is required.' }; if (-not [Environment]::UserInteractive -or [Diagnostics.Process]::GetCurrentProcess().SessionId -eq 0) { throw 'Use an elevated PowerShell shell on the intended user desktop, not Session 0.' }; $pins = New-Object 'Collections.Generic.List[IDisposable]'; $process = $null; $authorizationAttempted = $false; $d = $null; $security = { $pathNativeCode = 'using System; using System.IO; using System.ComponentModel; using System.Runtime.InteropServices; using System.Security.AccessControl; using Microsoft.Win32.SafeHandles; namespace MaintenanceV20261103 { public static class PathSafety { [StructLayout(LayoutKind.Sequential)] struct FileInfo { public uint Attributes; public System.Runtime.InteropServices.ComTypes.FILETIME CreationTime; public System.Runtime.InteropServices.ComTypes.FILETIME AccessTime; public System.Runtime.InteropServices.ComTypes.FILETIME WriteTime; public uint Volume; public uint SizeHigh; public uint SizeLow; public uint Links; public uint IndexHigh; public uint IndexLow; } [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern SafeFileHandle CreateFileW(string p,uint a,uint share,IntPtr sa,uint creation,uint flags,IntPtr template); [DllImport("kernel32.dll", SetLastError=true)] static extern bool GetFileInformationByHandle(SafeFileHandle h,out FileInfo info); [DllImport("advapi32.dll", SetLastError=true)] static extern uint GetSecurityInfo(SafeFileHandle h,int type,uint what,out IntPtr owner,out IntPtr group,out IntPtr dacl,out IntPtr sacl,out IntPtr descriptor); [DllImport("advapi32.dll")] static extern uint GetSecurityDescriptorLength(IntPtr descriptor); [DllImport("kernel32.dll")] static extern IntPtr LocalFree(IntPtr p); public static SafeFileHandle Pin(string path) { SafeFileHandle h=CreateFileW(path,0x20080,3,IntPtr.Zero,3,0x02200000,IntPtr.Zero); if(h.IsInvalid) {int e=Marshal.GetLastWin32Error();h.Dispose();throw new Win32Exception(e,"Cannot protect directory path: "+path);} try { FileInfo i; if(!GetFileInformationByHandle(h,out i)) throw new Win32Exception(Marshal.GetLastWin32Error()); if((i.Attributes & 16)==0 || (i.Attributes & 1024)!=0) throw new IOException("Not a plain directory: "+path); return h; } catch {h.Dispose();throw;} } public static DirectorySecurity Security(SafeFileHandle h) { IntPtr o,g,d,s,p; uint e=GetSecurityInfo(h,1,5,out o,out g,out d,out s,out p); if(e!=0) throw new Win32Exception((int)e); try { if(d==IntPtr.Zero) throw new IOException("A null DACL is not permitted."); byte[] b=new byte[GetSecurityDescriptorLength(p)]; Marshal.Copy(p,b,0,b.Length); DirectorySecurity acl=new DirectorySecurity(); acl.SetSecurityDescriptorBinaryForm(b,AccessControlSections.Owner|AccessControlSections.Access); return acl; } finally {if(p!=IntPtr.Zero)LocalFree(p);} } } }'; if (-not ('MaintenanceV20261103.PathSafety' -as [type])) { Add-Type -TypeDefinition $pathNativeCode -ErrorAction Stop }; $trustedOwners = @('S-1-5-18','S-1-5-32-544'); try { $trustedOwners += (New-Object Security.Principal.NTAccount('NT SERVICE','TrustedInstaller')).Translate([Security.Principal.SecurityIdentifier]).Value } catch { }; function New-PrivateAcl { $a = New-Object Security.AccessControl.DirectorySecurity; $a.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544'))); $a.SetAccessRuleProtection($true,$false); foreach ($sid in 'S-1-5-18','S-1-5-32-544') { $identity = New-Object Security.Principal.SecurityIdentifier($sid); $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity,'FullControl','ContainerInherit,ObjectInherit','None','Allow'); $a.AddAccessRule($rule) }; return $a }; function Assert-DirectoryAcl($Handle,[string]$Path,[bool]$Private) { $a = [MaintenanceV20261103.PathSafety]::Security($Handle); $owner = $a.GetOwner([Security.Principal.SecurityIdentifier]).Value; $rules = @($a.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier])); if ($Private) { if ($owner -notin @('S-1-5-18','S-1-5-32-544') -or -not $a.AreAccessRulesProtected -or $rules.Count -ne 2) { throw "Private directory has an unexpected owner/DACL; left unchanged: $Path" }; $seen = @(); foreach ($rule in $rules) { $sid = $rule.IdentityReference.Value; if ($sid -notin @('S-1-5-18','S-1-5-32-544') -or $sid -in $seen -or $rule.IsInherited -or $rule.AccessControlType -ne 'Allow' -or [int]$rule.FileSystemRights -ne [int][Security.AccessControl.FileSystemRights]::FullControl -or [int]$rule.InheritanceFlags -ne 3 -or [int]$rule.PropagationFlags -ne 0) { throw "Private directory ACL does not match; left unchanged: $Path" }; $seen += $sid } } else { if ($owner -notin $trustedOwners -or $rules.Count -eq 0) { throw "Untrusted ancestor owner/DACL; no permissions changed: $Path" }; foreach ($rule in $rules) { if ($rule.AccessControlType -ne 'Allow' -or ($rule.PropagationFlags -band [Security.AccessControl.PropagationFlags]::InheritOnly)) { continue }; if ($rule.IdentityReference.Value -notin $trustedOwners -and ([long]$rule.FileSystemRights -band 0x100D0040)) { throw "Ancestor allows non-administrator path modification; no permissions changed: $Path" } } } }; function Open-VerifiedChain([string]$Path,[string]$PrivateRoot) { $full = [IO.Path]::GetFullPath($Path); if ($full -notmatch '^[A-Za-z]:\\' -or $full -match '[%"\r\n]') { throw 'A local, ordinary directory path is required.' }; $chain = New-Object 'Collections.Generic.Stack[string]'; $item = New-Object IO.DirectoryInfo($full); while ($item) { $chain.Push($item.FullName); $item = $item.Parent }; $pins = New-Object 'Collections.Generic.List[IDisposable]'; try { while ($chain.Count) { $pathPart = $chain.Pop(); $h = [MaintenanceV20261103.PathSafety]::Pin($pathPart); $pins.Add($h); $private = $pathPart.TrimEnd('\').Equals($PrivateRoot.TrimEnd('\'),[StringComparison]::OrdinalIgnoreCase) -or $pathPart.StartsWith($PrivateRoot.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase); Assert-DirectoryAcl $h $pathPart $private }; return ,$pins } catch { foreach ($h in $pins) { $h.Dispose() }; throw } }; function Open-PrivateDirectory([string]$Path) { if (-not [IO.Directory]::Exists($Path)) { [void][IO.Directory]::CreateDirectory($Path,(New-PrivateAcl)) }; $h = [MaintenanceV20261103.PathSafety]::Pin($Path); try { Assert-DirectoryAcl $h $Path $true; return $h } catch { $h.Dispose(); throw } }; function Write-AtomicJson([string]$Path,$Value) { $tmp = $Path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'; try { [IO.File]::WriteAllText($tmp,(ConvertTo-Json -InputObject $Value -Depth 8 -Compress),[Text.Encoding]::UTF8); if ([IO.File]::Exists($Path)) { [IO.File]::Replace($tmp,$Path,[System.Management.Automation.Language.NullString]::Value) } else { [IO.File]::Move($tmp,$Path) } } finally { if ([IO.File]::Exists($tmp)) { [IO.File]::Delete($tmp) } } }; function Test-ResultStorage([string]$Directory) { $checkPath = [IO.Path]::Combine($Directory,('ResultWriteTest.'+[guid]::NewGuid().ToString('N')+'.json')); try { Write-AtomicJson $checkPath ([ordered]@{Version=1}); Write-AtomicJson $checkPath ([ordered]@{Version=2}); $check = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($checkPath,[Text.Encoding]::UTF8)) -ErrorAction Stop; if ([int]$check.Version -ne 2) { throw 'Result-file replacement precheck failed.' }; } finally { if ([IO.File]::Exists($checkPath)) { [IO.File]::Delete($checkPath) } }; }; function Read-RunMessage([string]$Path,$Context,[int]$WorkerPID,[string]$WorkerStartTicks) { $m = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)) -ErrorAction Stop; if ([string]$m.RunId -cne [string]$Context.RunId -or [string]$m.Token -cne [string]$Context.Token -or [int]$m.WorkerPID -ne $WorkerPID -or [string]$m.WorkerStartTicks -cne $WorkerStartTicks) { throw "Startup identity mismatch: $Path" }; return $m } }; try { . $security; $base = [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData); if ([string]::IsNullOrWhiteSpace($base)) { throw 'Cannot resolve ProgramData.' }; $root = Join-Path $base 'SystemMaintenance'; $ancestorPins = Open-VerifiedChain $base $root; foreach ($h in $ancestorPins) { $pins.Add($h) }; $pins.Add((Open-PrivateDirectory $root)); $runId = [guid]::NewGuid().ToString('N'); $d = Join-Path $root (('{0:yyyyMMdd-HHmmss-fff}-{1}-{2}' -f (Get-Date),$PID,$runId)); if (Test-Path -LiteralPath $d) { throw 'Run directory unexpectedly exists; no files changed.' }; $pins.Add((Open-PrivateDirectory $d)); Write-Host "Logs: $d"; Write-Host 'Do not close this shell until START AUTHORIZED is printed.'; if (-not $Preview) { Write-Host 'REAL MAINTENANCE: Recycle Bin emptying and an automatic forced restart are enabled.' }; $c = { $d=[string]$Context.RunDirectory; $root=[string]$Context.MaintenanceRoot; $launcherPID=[int]$Context.LauncherPID; $startStep=[int]$Context.StartStep; $StepTimeoutMinutes=[int]$Context.StepTimeoutMinutes; $workerPins=$null; $instanceLock=$null; $records=New-Object 'Collections.Generic.List[object]'; $restartRequested=$false; function Add-Result([int]$Number,[string]$Name,[string]$Status,$Code){$records.Add([pscustomobject]@{Step=$Number; Name=$Name; Status=$Status; ExitCode=$Code; Utc=[DateTime]::UtcNow.ToString('o')})}; function Save-Result([string]$Outcome,[int]$Code,[bool]$Restart){Write-AtomicJson "$d\Result.json" ([ordered]@{RunId=$Context.RunId; WorkerPID=$PID; StartStep=$startStep; Outcome=$Outcome; ExitCode=$Code; IssueCount=$issues; RestartRequested=$Restart; Utc=[DateTime]::UtcNow.ToString('o'); Steps=@($records.ToArray())})}; function Save-ResultBestEffort([string]$Outcome,[int]$Code,[bool]$Restart) { try { Save-Result $Outcome $Code $Restart } catch { $message = "RESULT WRITE WARNING ($Outcome): $($_.Exception.Message)"; try { Log $message } catch {}; try { [IO.File]::AppendAllText("$d\ResultWrite.err.txt",((Get-Date -Format o)+' '+$message+"`r`n"),[Text.Encoding]::UTF8) } catch {}; }; }; function Wait-ForAuthorization { $workerTicks = [Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().Ticks.ToString(); $notice = [ordered]@{ RunId=$Context.RunId; Token=$Context.Token; WorkerPID=$PID; WorkerStartTicks=$workerTicks; Utc=[DateTime]::UtcNow.ToString('o') }; if ([DateTime]::UtcNow.Ticks -ge [long]$Context.StartupDeadlineTicks) { throw 'Startup authorization deadline expired; no maintenance started.' }; if ([IO.File]::Exists("$d\Abort.flag")) { throw 'Launcher cancelled startup; no maintenance started.' }; Write-AtomicJson "$d\Ready.ok" $notice; Log "WORKER READY: PID=$PID; awaiting launcher authorization."; $wait = [Diagnostics.Stopwatch]::StartNew(); while ($wait.Elapsed.TotalSeconds -lt ([int]$Context.StartupTimeoutSeconds+5) -and [DateTime]::UtcNow.Ticks -lt [long]$Context.StartupDeadlineTicks) { if ([IO.File]::Exists("$d\Abort.flag")) { throw 'Launcher cancelled startup; no maintenance started.' }; $parent = $null; try { $parent = [Diagnostics.Process]::GetProcessById($launcherPID); if ($parent.HasExited -or $parent.StartTime.ToUniversalTime().Ticks.ToString() -cne [string]$Context.LauncherStartTicks) { throw 'Launcher no longer matches.' } } catch { throw 'Launcher ended before authorization; no maintenance started.' } finally { if ($parent) { $parent.Dispose() } }; if ([IO.File]::Exists("$d\Start.ok")) { $allow = Read-RunMessage "$d\Start.ok" $Context $PID $workerTicks; if ($allow.Action -cne 'Start' -or [DateTime]::UtcNow.Ticks -ge [long]$Context.StartupDeadlineTicks -or [IO.File]::Exists("$d\Abort.flag")) { throw 'Startup was not authorized within its deadline.' }; if (Get-Process sfc,dism -ErrorAction SilentlyContinue) { throw 'SFC/DISM started during initialization; this run will not start maintenance.' }; Write-AtomicJson "$d\Started.ok" $notice; Log "START AUTHORIZED: run=$($Context.RunId); PID=$PID."; return }; Tick }; throw 'No timely launcher authorization; no maintenance started and no reboot requested.' } ; $ErrorActionPreference='Stop'; $t=$f=$p=$null; $blocked=$false; $reboot=$false; $issues=0; $exitCode=0; function Log($m){$line=("{0:s} {1}`r`n" -f(Get-Date),($m)); [IO.File]::AppendAllText("$d\Run.log",($line),[Text.Encoding]::UTF8)}; function Tick{[Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 100}; function Record-Failure($err){try{Log ("STOPPED: {0} No reboot. See Error.txt." -f($err.Exception.Message)); $txt=("{0}`r`n`r`n{1}`r`n`r`n{2}`r`n`r`n{3}" -f($err.ToString()),($err.InvocationInfo.PositionMessage),($err.ScriptStackTrace),($err.Exception.ToString())); [IO.File]::WriteAllText("$d\Error.txt",($txt),[Text.Encoding]::UTF8)}catch{}}; function Countdown([ValidateRange(1,3600)][int]$seconds=120,[switch]$ValidateOnly){$r=$null; try{Log ("COUNTDOWN UI: creating {0}-second notice." -f($seconds)); $r=New-Object Windows.Forms.Form -Property @{Text='Restart - save your work'; ClientSize=(New-Object Drawing.Size(420,180)); StartPosition='CenterScreen'; TopMost=$true; ShowInTaskbar=$true; ControlBox=$false; MinimizeBox=$false; MaximizeBox=$false; FormBorderStyle='FixedDialog'; Tag='count'}; $title=New-Object Windows.Forms.Label -Property @{Text='Your computer will restart automatically'; Left=15; Top=12; Width=390; Height=25; Font=(New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold))}; $msg=New-Object Windows.Forms.Label -Property @{Text='Save and close your work now. Unsaved work can be lost.'; Left=15; Top=40; Width=390; Height=40; Font=(New-Object Drawing.Font('Segoe UI',9))}; $clock=New-Object Windows.Forms.Label -Property @{Left=15; Top=82; Width=390; Height=50; TextAlign='MiddleCenter'; Font=(New-Object Drawing.Font('Segoe UI',28,[Drawing.FontStyle]::Bold))}; $bar=New-Object Windows.Forms.ProgressBar -Property @{Left=15; Top=140; Width=390; Height=18}; $bar.Minimum=0; $bar.Maximum=($seconds); $bar.Value=($seconds); $r.Add_FormClosing({param($s,$e); if($s.Tag -ne 'done' -and $e.CloseReason -eq 'UserClosing'){$e.Cancel=$true}}); $r.Controls.AddRange(@($title,$msg,$clock,$bar)); if($Context.Preview){$r.Text='TEST ONLY - no restart'; $title.Text='120-second countdown test'; $msg.Text='No repairs, deletion, optimization or restart will run.'}; if($ValidateOnly){Log ("UI PRECHECK OK: Maximum={0}; Value={1}." -f($bar.Maximum),($bar.Value)); return($true)}; function Front{if($t::InputAvailable()){$r.WindowState='Normal'; $area=[Windows.Forms.Screen]::FromPoint([Windows.Forms.Cursor]::Position).WorkingArea; $r.Location=New-Object Drawing.Point(($area.Left+[int](($area.Width-$r.Width)/2)),($area.Top+[int](($area.Height-$r.Height)/2))); [void]$t::ShowWindow($r.Handle,9); $r.BringToFront(); $r.Activate(); [void]$t::SetForegroundWindow($r.Handle); try{[System.Media.SystemSounds]::Exclamation.Play()}catch{}}}; if(!$t::SetThreadExecutionState([uint32]2147483651)){throw 'Countdown keep-awake request failed.'}; $r.Show(); [void]$t::ShowWindow($r.Handle,5); Front; $sw=[Diagnostics.Stopwatch]::StartNew(); $warn30=$warn10=$lockLogged=$false; $wasInput=$t::InputAvailable(); Log ("COUNTDOWN START: {0} seconds (unconditional)." -f($seconds)); while($true){[Windows.Forms.Application]::DoEvents(); $inputNow=$t::InputAvailable(); if($inputNow -and !$wasInput){Front}; $wasInput=$inputNow; if((!$inputNow) -and(!$lockLogged)){$lockLogged=$true; Log 'COUNTDOWN INFO: desktop locked or unavailable; continuing unattended countdown.'}; $left=[int][math]::Max(0,[math]::Ceiling($seconds-$sw.Elapsed.TotalSeconds)); $clock.Text=('{0:00}:{1:00}' -f[int][math]::Floor($left/60),($left%60)); $bar.Value=($left); if($left -le 0){Log 'COUNTDOWN ELAPSED.'; return($true)}; if(($left -le 10) -and(!$warn10)){$warn10=$warn30=$true; Front}elseif(($left -le 30) -and(!$warn30)){$warn30=$true; Front}; Tick}}finally{if($r){$r.Tag='done'; $r.Close(); $r.Dispose()}}}; try{Log ("BUILD: result-write-fix-20261103; StartStep={0}; Preview={1}" -f $startStep,$Context.Preview); $workerPins=Open-VerifiedChain $d $root; $instanceLock=[IO.File]::Open((Join-Path $root 'Instance.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None); Test-ResultStorage $d; Log 'RESULT WRITE PRECHECK OK: create and replace succeeded.'; if([DateTime]::UtcNow.Ticks -ge [long]$Context.StartupDeadlineTicks -or [IO.File]::Exists("$d\Abort.flag")){throw 'Startup expired/cancelled before initialization; no maintenance started.'}; Log ("START: {0}; session={1}; 64-bit={2}; TEMP={3}" -f([Security.Principal.WindowsIdentity]::GetCurrent().Name),([Diagnostics.Process]::GetCurrentProcess().SessionId),([Environment]::Is64BitProcess),($env:TEMP)); $t=Add-Type -MemberDefinition '[DllImport("kernel32.dll")]public static extern uint SetThreadExecutionState(uint f);[DllImport("kernel32.dll")]public static extern uint GetConsoleProcessList([Out] uint[] p,uint n);[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h,int n);[DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);[DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);[DllImport("kernel32.dll")]static extern uint GetCurrentThreadId();[DllImport("user32.dll")]static extern IntPtr GetThreadDesktop(uint id);[DllImport("user32.dll",EntryPoint="GetUserObjectInformationW")]static extern bool Info(IntPtr h,int x,out int v,int n,out int needed);[DllImport("wtsapi32.dll",EntryPoint="WTSQuerySessionInformationW")]static extern bool Query(IntPtr s,int id,int c,out IntPtr b,out int n);[DllImport("wtsapi32.dll")]static extern void WTSFreeMemory(IntPtr b);public static bool InputAvailable(){IntPtr b=IntPtr.Zero;int n;try{if(!Query(IntPtr.Zero,-1,8,out b,out n))return false;if(b==IntPtr.Zero)return false;if(n<4)return false;if(System.Runtime.InteropServices.Marshal.ReadInt32(b)!=0)return false;int io,m;if(!Info(GetThreadDesktop(GetCurrentThreadId()),6,out io,4,out m))return false;return io!=0;}finally{if(b!=IntPtr.Zero)WTSFreeMemory(b);}}' -Name Pwr -PassThru; [uint32[]]$ids=New-Object uint32[] 64; $count=$t::GetConsoleProcessList($ids,64); if((!$count) -or($count -gt 64) -or($ids -contains($launcherPID))){throw 'Console check failed; not started.'}; Log ("Separate console verified: worker PID={0}; launcher PID={1}" -f($PID),($launcherPID)); Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; [Windows.Forms.Application]::EnableVisualStyles(); [void](Countdown -seconds 120 -ValidateOnly); $f=New-Object Windows.Forms.Form -Property @{Text='System Maintenance'; Width=540; Height=185; StartPosition='CenterScreen'; TopMost=$true; ControlBox=$true; MinimizeBox=$true; MaximizeBox=$false; ShowInTaskbar=$true; FormBorderStyle='FixedSingle'}; $l=New-Object Windows.Forms.Label -Property @{Left=15; Top=15; Width=495; Height=40}; $b=New-Object Windows.Forms.ProgressBar -Property @{Left=15; Top=60; Width=495; Style='Marquee'}; $f.Add_FormClosing({param($s,$e); if((!$s.Tag) -and($e.CloseReason -eq 'UserClosing')){$e.Cancel=$true}}); $f.Add_Resize({param($s,$e); if($s.WindowState -eq 'Normal'){$s.Invalidate($true); $s.Update()}}); $f.Controls.AddRange(@($l,$b)); $f.Show(); [void]$t::ShowWindow($f.Handle,5); $f.Activate(); Tick; if(!$t::IsWindowVisible($f.Handle)){throw 'UI unavailable; not started.'}; Log ("UI ready: worker PID={0}" -f($PID)); if(Get-Process sfc,dism -ErrorAction SilentlyContinue){throw 'SFC/DISM already running; not started.'}; if(!$t::SetThreadExecutionState([uint32]2147483651)){throw 'Keep-awake request failed.'}; Wait-ForAuthorization; if($Context.Preview){$f.Hide(); [void](Countdown -seconds 120); Log 'PREVIEW FINISHED: no maintenance or restart executed.'; Save-Result 'PreviewFinished' 0 $false}else{$steps=@(@('DISM','DISM.exe','/Online /Cleanup-Image /RestoreHealth /NoRestart'),@('SFC','sfc.exe','/scannow'),@('Components','DISM.exe','/Online /Cleanup-Image /StartComponentCleanup /NoRestart'),@('Cleanup',{$cutoff=(Get-Date).AddDays(-7); $counts=@(0,0); function Clean($dir){if(!$dir){return}; $r=Get-Item -LiteralPath($dir) -Force -ErrorAction SilentlyContinue; if((!$r) -or(!$r.PSIsContainer) -or($r.Attributes -band[IO.FileAttributes]::ReparsePoint)){return}; if($r.FullName.TrimEnd('\') -eq($r.Root.FullName.TrimEnd('\'))){return}; foreach($i in @(Get-ChildItem -LiteralPath($r.FullName) -Force -ErrorAction SilentlyContinue)){if($i.Attributes -band[IO.FileAttributes]::ReparsePoint){continue}; if($i.PSIsContainer){Clean($i.FullName)}elseif($i.LastWriteTime -lt($cutoff)){try{Remove-Item -LiteralPath($i.FullName) -Force -ErrorAction Stop; $counts[0]++}catch{$counts[1]++}}}}; Clean($env:TEMP); Clean("$env:windir\Temp"); ("Temp deleted={0}; skipped={1}." -f($counts[0]),($counts[1])); Clear-RecycleBin -DriveLetter([char]$env:SystemDrive[0]) -Force -ErrorAction Stop; 'Executing account: system-drive Recycle Bin cleared.'}),@('Optimize',{Optimize-Volume -DriveLetter([char]$env:SystemDrive[0]) -Verbose})); $n=0; foreach($s in @($steps)){$n++; if(($n) -lt($startStep)){Log ("SKIPPED-STARTSTEP step {0}: {1}; StartStep={2}." -f($n),($s[0]),($startStep)); Add-Result $n $s[0] 'SkippedByRequest' $null; continue}; if(($n -le 3) -and(!$blocked) -and(Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction Stop)){$blocked=$true; $reboot=$true; $issues++; Log 'REBOOT REQUIRED: CBS flag found; servicing deferred.'}; if(($n -le 3) -and($blocked)){$state=if($reboot){'DEFERRED-REBOOT'}else{'SKIPPED-AFTER-ERROR'}; Log ("{0} step {1}: {2}; not performed." -f($state),($n),($s[0])); Add-Result $n $s[0] $state $null; continue}; $l.Text=("Step {0}/5: {1}" -f($n),($s[0])); Tick; $o=("{0}\{1:00}-{2}" -f($d),($n),($s[0])); Log ("START step {0}: {1}" -f($n),($s[0])); if($s[1] -is[scriptblock]){$body='$ErrorActionPreference="Stop";$ProgressPreference="SilentlyContinue";try{'+$s[1]+';exit 0}catch{[Console]::Error.WriteLine($PSItem.Exception.ToString());exit 1}'; $tokChild=$errChild=$null; [void][System.Management.Automation.Language.Parser]::ParseInput($body,[ref]$tokChild,[ref]$errChild); if($errChild.Count){throw 'Generated maintenance child failed syntax validation.'}; $enc=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body)); $exe="$PSHOME\powershell.exe"; $arg='-NoProfile -NonInteractive -ExecutionPolicy Bypass -OutputFormat Text -EncodedCommand '+($enc)}else{$exe="$env:windir\System32\"+($s[1]); $arg=($s[2])}; $p=New-Object Diagnostics.Process; $p.StartInfo=New-Object Diagnostics.ProcessStartInfo -Property @{FileName="$env:windir\System32\cmd.exe"; Arguments=('/d /v:off /s /c ""{0}" {1} 1>"{2}.out.txt" 2>"{2}.err.txt""' -f($exe),($arg),($o)); UseShellExecute=$false; CreateNoWindow=$false; WindowStyle='Hidden'; WorkingDirectory=($env:windir)}; if($p.StartInfo.Arguments.Length -gt 8000){throw 'Worker command is too long.'}; if(!$p.Start()){throw 'Could not start maintenance.'}; $w=[Diagnostics.Stopwatch]::StartNew(); $lastBeat=0; while(!$p.HasExited){Tick; $mins=[int][math]::Floor($w.Elapsed.TotalMinutes); if($mins -gt($lastBeat)){$lastBeat=($mins); $l.Text=("Step {0}/5: {1} ({2}m elapsed)" -f($n),($s[0]),($mins)); Log ("HEARTBEAT {0}: elapsed={1}m; cmdPID={2}" -f($s[0]),($mins),($p.Id))}; if($w.Elapsed.TotalMinutes -ge $StepTimeoutMinutes -and !$p.HasExited){throw ("{0} exceeded its per-step limit; tool NOT deliberately killed. Inspect processes; no reboot." -f($s[0]))}}; $p.WaitForExit(); $rc=$p.ExitCode; $p.Dispose(); $p=$null; Log ("END {0}: exit={1}; elapsed={2}" -f($s[0]),($rc),($w.Elapsed)); $text=''; if($s[0] -eq 'SFC'){$r=[IO.File]::ReadAllBytes("$o.out.txt"); if(($r.Length -gt 1) -and(($r[1] -eq 0) -or(($r[0] -eq 255) -and($r[1] -eq 254)))){$text=[Text.Encoding]::Unicode.GetString($r).TrimStart([char]65279)}else{$text=[IO.File]::ReadAllText("$o.out.txt")}; $text+="`r`n"+[IO.File]::ReadAllText("$o.err.txt"); [IO.File]::WriteAllText("$d\02-SFC.txt",($text),[Text.Encoding]::UTF8)}; if(($s[0] -eq 'SFC') -and($rc -eq 1) -and($text -match '(?is)\bsystem\s+repair\s+pending\b.*?\brequires\s+(?:a\s+)?reboot\b')){$blocked=$true; $reboot=$true; $issues++; Log 'DEFERRED-REBOOT SFC; other steps continue.'; Add-Result $n $s[0] 'DeferredForRestart' $rc; continue}; if(($rc -eq 3010) -and($s[1] -eq 'DISM.exe')){$blocked=$true; $reboot=$true; $issues++; Log ("REBOOT REQUIRED: {0} exit=3010; defer servicing." -f($s[0])); Add-Result $n $s[0] 'CompletedRestartRequired' $rc; continue}; if($rc -ne 0){$issues++; if($n -le 3){$blocked=$true}; Log ("ERROR {0}: exit={1}; see {2}.out.txt/{2}.err.txt." -f($s[0]),($rc),($o)); Add-Result $n $s[0] 'Failed' $rc; continue}; Add-Result $n $s[0] 'CompletedExit0' $rc; Log ("OK {0}: exit=0." -f($s[0]))}; Log ("SEQUENCE FINISHED: issues/deferred={0}; rebootRequired={1}." -f($issues),($reboot)); if($blocked){Log 'FOLLOW-UP: rerun skipped servicing.'}; $exitCode=if($issues -gt 0){2}else{0}; Save-ResultBestEffort 'SequenceFinished' $exitCode $false; $f.Hide(); if(Countdown -seconds 120){if(Get-Process sfc,dism -ErrorAction SilentlyContinue){throw 'SFC/DISM running; restart suppressed.'}else{Save-ResultBestEffort 'RestartPending' $exitCode $false; try { Log 'RESTART CALL: invoking Restart-Computer -Force now.' } catch {}; Restart-Computer -Force -Confirm:$false -ErrorAction Stop; $restartRequested=$true; Save-ResultBestEffort 'RestartRequested' $exitCode $true; try { Log 'RESTART CALL RETURNED without a terminating error; reboot completion is not verified.' } catch {}}}}}catch{$exitCode=1; Record-Failure($PSItem); try{Save-Result 'FatalError' 1 $restartRequested}catch{}}finally{if($p){try{$p.Dispose()}catch{}}; if($t){try{[void]$t::SetThreadExecutionState([uint32]2147483648)}catch{}}; if($f){try{$f.Tag=$true; $f.Close(); $f.Dispose()}catch{}}; if($instanceLock){$instanceLock.Dispose()}; if($workerPins){foreach($h in $workerPins){$h.Dispose()}}}; [Environment]::Exit($exitCode) }; $workerPath = Join-Path $d 'Worker.ps1'; $payload = 'param($Context);' + $security.ToString() + ';' + $c.ToString(); $tokens = $parseErrors = $null; [void][System.Management.Automation.Language.Parser]::ParseInput($payload,$workerPath,[ref]$tokens,[ref]$parseErrors); if ($parseErrors.Count) { throw ('Worker parser validation failed: ' + ($parseErrors.Message -join '; ')) }; [IO.File]::WriteAllText($workerPath,$payload,[Text.Encoding]::UTF8); $sha = [Security.Cryptography.SHA256]::Create(); try { $workerHash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($workerPath))).Replace('-','') } finally { $sha.Dispose() }; $random = New-Object byte[] 32; $rng = [Security.Cryptography.RandomNumberGenerator]::Create(); try { $rng.GetBytes($random) } finally { $rng.Dispose() }; $Context = [ordered]@{ RunDirectory=$d; MaintenanceRoot=$root; RunId=$runId; Token=[BitConverter]::ToString($random).Replace('-',''); LauncherPID=$PID; LauncherStartTicks=[Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().Ticks.ToString(); StartStep=$StartStep; StepTimeoutMinutes=$StepTimeoutMinutes; StartupTimeoutSeconds=$StartupTimeoutSeconds; StartupDeadlineTicks=[DateTime]::UtcNow.AddSeconds($StartupTimeoutSeconds).Ticks.ToString(); Preview=[bool]$Preview; WorkerSHA256=$workerHash }; $context64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $Context -Compress))); $bootTemplate = { $ErrorActionPreference='Stop'; $Context=$null; try { $Context=ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__CONTEXT__'))); $bytes=[IO.File]::ReadAllBytes((Join-Path $Context.RunDirectory 'Worker.ps1')); $sha=[Security.Cryptography.SHA256]::Create(); try { $actual=[BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','') } finally { $sha.Dispose() }; if ($actual -cne $Context.WorkerSHA256) { throw 'Worker hash mismatch; execution refused.' }; $raw=[Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]65279); & ([scriptblock]::Create($raw)) $Context } catch { $detail=$PSItem.Exception.ToString()+"`r`n"+$PSItem.InvocationInfo.PositionMessage+"`r`n"+$PSItem.ScriptStackTrace; try { if ($Context) { [IO.File]::WriteAllText((Join-Path $Context.RunDirectory 'Bootstrap.err.txt'),$detail,[Text.Encoding]::UTF8) } } catch { }; [Console]::Error.WriteLine($detail); [Environment]::Exit(1) } }; $boot = $bootTemplate.ToString().Replace('__CONTEXT__',$context64); $tokens = $parseErrors = $null; [void][System.Management.Automation.Language.Parser]::ParseInput($boot,[ref]$tokens,[ref]$parseErrors); if ($parseErrors.Count) { throw 'Bootstrap parser validation failed.' }; $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($boot)); $ps = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"; if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { $ps="$env:windir\Sysnative\WindowsPowerShell\v1.0\powershell.exe" }; $arguments = '-NoProfile -STA -NonInteractive -ExecutionPolicy Bypass -OutputFormat Text -EncodedCommand ' + $encoded; if (($arguments.Length+$ps.Length+8) -gt 32000) { throw 'Bootstrap exceeds the safe command-line limit.' }; $watch = [Diagnostics.Stopwatch]::StartNew(); $process = Start-Process -FilePath $ps -WindowStyle Hidden -ArgumentList $arguments -RedirectStandardOutput "$d\Launcher.out.txt" -RedirectStandardError "$d\Launcher.err.txt" -PassThru -ErrorAction Stop; $workerPID = $process.Id; $workerTicks = $process.StartTime.ToUniversalTime().Ticks.ToString(); [IO.File]::WriteAllText("$d\Launch.log",("{0:s} Launched PID={1}; original shell PID={2}; StartStep={3}; RunId={4}; readinessDeadlineUtc={5:o}`r`n" -f (Get-Date),$workerPID,$PID,$StartStep,$runId,([DateTime]::new([long]$Context.StartupDeadlineTicks,[DateTimeKind]::Utc))),[Text.Encoding]::UTF8); $ready = $false; while ($watch.Elapsed.TotalSeconds -lt $StartupTimeoutSeconds -and [DateTime]::UtcNow.Ticks -lt [long]$Context.StartupDeadlineTicks) { $process.Refresh(); if ($process.HasExited) { throw "Worker exited BEFORE authorization; exit=$($process.ExitCode). See startup logs in $d" }; if ([IO.File]::Exists("$d\Ready.ok")) { $notice = Read-RunMessage "$d\Ready.ok" $Context $workerPID $workerTicks; $process.Refresh(); if ($process.HasExited) { throw "Worker exited BEFORE authorization; exit=$($process.ExitCode). See $d" }; if ($watch.Elapsed.TotalSeconds -ge $StartupTimeoutSeconds -or [DateTime]::UtcNow.Ticks -ge [long]$Context.StartupDeadlineTicks) { break }; $ready = $true; break }; Start-Sleep -Milliseconds 100 }; if (-not $ready) { throw "Worker readiness timed out. Authorization was NOT issued; no maintenance is permitted. See $d" }; $authorization = [ordered]@{RunId=$runId;Token=$Context.Token;WorkerPID=$workerPID;WorkerStartTicks=$workerTicks;Action='Start';Utc=[DateTime]::UtcNow.ToString('o')}; $authorizationAttempted = $true; Write-AtomicJson "$d\Start.ok" $authorization; [IO.File]::AppendAllText("$d\Launch.log",("{0:s} START AUTHORIZED: matching live worker PID={1}.`r`n" -f (Get-Date),$workerPID),[Text.Encoding]::UTF8); $ackWatch=[Diagnostics.Stopwatch]::StartNew(); $ack=$false; while ($ackWatch.Elapsed.TotalSeconds -lt 5) { $process.Refresh(); if ($process.HasExited) { throw "Worker exited AFTER authorization; exit=$($process.ExitCode). Check Result.json and Run.log before another run." }; if ([IO.File]::Exists("$d\Started.ok")) { $null=Read-RunMessage "$d\Started.ok" $Context $workerPID $workerTicks; $ack=$true; break }; Start-Sleep -Milliseconds 100 }; if ($ack) { Write-Host "START AUTHORIZED and acknowledged: maintenance PID=$workerPID. Logs: $d" } else { Write-Warning "START AUTHORIZED for PID=$workerPID, but acknowledgement was not observed. It may be running; do not launch another copy. Logs: $d" } } catch { $failure=$PSItem; if ($d -and [IO.Directory]::Exists($d)) { try { [IO.File]::WriteAllText("$d\Launch.error.txt",$failure.Exception.ToString()+"`r`n"+$failure.InvocationInfo.PositionMessage,[Text.Encoding]::UTF8) } catch { } }; if ($authorizationAttempted) { Write-Warning 'Start authorization may already have reached the worker. Inspect its logs/processes; this message is NOT an assurance that no maintenance ran.' }; throw $failure } finally { if (-not $authorizationAttempted -and $d -and [IO.Directory]::Exists($d)) { try { [IO.File]::WriteAllText("$d\Abort.flag",'Startup ended without authorization.',[Text.Encoding]::UTF8) } catch { } }; if ($process) { $process.Dispose() }; foreach ($h in $pins) { $h.Dispose() } } } } -StartStep 1



& { $ErrorActionPreference = 'Stop'; function Get-LogTimestamp([string]$Path) { try { if (-not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction Stop)) { return 'Not found' }; $tailLines = @(Get-Content -LiteralPath $Path -Tail 200 -ErrorAction Stop); for ($n=$tailLines.Count-1; $n -ge 0; $n--) { $entry = [regex]::Match(([string]$tailLines[$n]).Replace([string][char]0,''),'^\s*(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2})'); if ($entry.Success) { return $entry.Groups[1].Value.Replace('T',' ') } }; return 'No timestamp in last 200 lines' } catch { return 'Unreadable' } }; $root = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'SystemMaintenance'; $run = Get-ChildItem -LiteralPath $root -Directory -ErrorAction Stop | Where-Object { $_.Name -match '^\d{8}-\d{6}-' } | Sort-Object Name -Descending | Select-Object -First 1; if (-not $run) { throw "No maintenance run found in $root" }; $d = $run.FullName; $logFile = Join-Path $d 'Run.log'; $lines = @(); if (Test-Path -LiteralPath $logFile -PathType Leaf) { $lines = @(Get-Content -LiteralPath $logFile -Encoding UTF8 -ErrorAction Stop) }; $keys = @('DISM','SFC','Components','Cleanup','Optimize'); $names = @('DISM image repair','System File Checker','Component-store cleanup','Temporary files / Recycle Bin','Drive optimization'); $rows = @(for ($i=0; $i -lt 5; $i++) { [pscustomobject]@{Step=($i+1); Task=$names[$i]; Status='Not reached'; ExitCode='-'} }); $active = -1; $lastStarted = -1; $began = $null; $lastAt = $null; $lastEvent = ''; $heartbeat = ''; $heartbeatAt = $null; $phase = 'Initializing / no step recorded'; $stopped = $false; $countdownAt = $null; foreach ($line in $lines) { if ($line -notmatch '^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\s+(.+)$') { continue }; $at = [datetime]::ParseExact($Matches[1],'yyyy-MM-ddTHH:mm:ss',[Globalization.CultureInfo]::InvariantCulture); $msg = $Matches[2].Trim(); $lastAt = $at; $lastEvent = $msg; if ($msg -match '^START step ([1-5]): (\w+)') { $active = [int]$Matches[1]-1; $lastStarted = $active; $began = $at; $heartbeat = ''; $heartbeatAt = $null; $rows[$active].Status = 'Started; checking worker'; $phase = 'Step in progress (logged)'; } elseif ($msg -match '^HEARTBEAT (\w+): elapsed=(\d+)m; cmdPID=(\d+)') { if ($active -ge 0 -and $Matches[1] -eq $keys[$active]) { $heartbeat = $msg; $heartbeatAt = $at }; } elseif ($msg -match '^END (\w+): exit=(-?\d+)') { $j = [Array]::IndexOf($keys,$Matches[1]); $rc = [int]$Matches[2]; if ($j -ge 0) { $rows[$j].ExitCode = $rc; $rows[$j].Status = if ($rc -eq 0) { 'Completed (exit 0)' } elseif ($rc -eq 3010) { 'Restart required' } else { 'Exited with error' } }; $active = -1; $phase = 'Step exited / between steps'; } elseif ($msg -match '^(DEFERRED[-_]REBOOT|SKIPPED[-_]AFTER[-_]ERROR|SKIPPED[-_]STARTSTEP|SKIPPED_BY_REQUEST) step ([1-5]):') { $j = [int]$Matches[2]-1; $rows[$j].Status = if ($Matches[1] -like 'DEFERRED*') { 'Deferred: reboot required' } elseif ($Matches[1] -like '*ERROR') { 'Skipped after error' } else { 'Skipped by request' }; if ($active -eq $j) { $active = -1 }; } elseif ($msg -match '^DEFERRED[-_]REBOOT SFC') { $rows[1].Status = 'Deferred: reboot required'; } elseif ($msg -match '^SEQUENCE FINISHED:') { $active = -1; $phase = 'Maintenance sequence ended'; } elseif ($msg -match '^(?:RESTART )?COUNTDOWN(?: START:|: started)') { $active = -1; $phase = 'Restart countdown'; $countdownAt = $at; } elseif ($msg -match '^(?:RESTART )?COUNTDOWN(?: ELAPSED\.|: elapsed)') { $active = -1; $phase = 'Countdown elapsed; restart not yet confirmed'; } elseif ($msg -match '^(RESTART CALL:|Requesting forced restart)') { $active = -1; $phase = 'Restart call stage; acceptance not confirmed'; } elseif ($msg -match '^RESTART (SUPPRESSED|CANCELLED|WAITING):?') { $active = -1; $phase = $msg; } elseif ($msg -match '^PREVIEW FINISHED:') { $active = -1; $phase = 'Preview finished; no restart'; } elseif ($msg -match '^STOPPED:') { if ($active -ge 0) { $rows[$active].Status = 'Controller stopped; inspect tool' }; $active = -1; $stopped = $true; $phase = 'STOPPED - ' + $msg.Substring(8).Trim(); }; }; $workerId = 0; $worker = 'Unknown'; $alive = $false; $identity = $null; try { $readyPath = Join-Path $d 'Ready.ok'; if (Test-Path -LiteralPath $readyPath -PathType Leaf) { $identity = Get-Content -LiteralPath $readyPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop; $workerId = [int]$identity.WorkerPID }; if (-not $workerId) { $launchPath = Join-Path $d 'Launch.log'; if (Test-Path -LiteralPath $launchPath -PathType Leaf) { $launch = Get-Content -LiteralPath $launchPath -Raw -Encoding UTF8; if ($launch -match 'Launched PID=(\d+)') { $workerId = [int]$Matches[1] } }; }; if ($workerId -gt 0) { $wp = Get-Process -Id $workerId -ErrorAction Stop; if ($identity -and $identity.WorkerStartTicks) { if ($wp.StartTime.ToUniversalTime().Ticks.ToString() -ne [string]$identity.WorkerStartTicks) { $worker = "PID $workerId reused / start time does not match" } else { $alive = $true; $worker = "PID $workerId alive; start time matches" }; } else { $worker = "PID $workerId exists; no start-time identity available" }; }; } catch { $worker = "PID $workerId not verified: $($_.Exception.Message)" }; if ($active -ge 0) { if ($alive) { $rows[$active].Status = 'RUNNING (worker verified)'; $phase = 'RUNNING - controller waiting for step' } else { $rows[$active].Status = 'Last started; NOT verified active'; $phase = 'UNCONFIRMED - step start logged, worker not verified' }; }; $outcome = 'Not written yet'; try { $resultPath = Join-Path $d 'Result.json'; if (Test-Path -LiteralPath $resultPath -PathType Leaf) { $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop; $outcome = [string]$result.Outcome; if (-not $stopped -and $active -lt 0) { if ($outcome -eq 'FatalError') { $phase = 'STOPPED - fatal error recorded' } elseif ($outcome -eq 'RestartRequested') { $phase = 'Restart requested; reboot completion not verified' } elseif ($outcome -eq 'PreviewFinished') { $phase = 'Preview finished; no restart' }; }; }; } catch { $outcome = 'Unreadable / being updated' }; $now = Get-Date; $stepText = 'None - see phase'; $elapsed = '-'; $progress = 'Not applicable'; $progressUpdated = '-'; if ($active -ge 0) { $stepText = ('{0}/5 - {1}' -f ($active+1),$names[$active]); $endAt = if ($alive) { $now } else { $lastAt }; if ($began -and $endAt -ge $began) { $elapsed = ($endAt-$began).ToString('c'); if (-not $alive) { $elapsed += ' (through last log only)' } }; $progress = 'No percentage reported'; $outputPath = Join-Path $d ('{0:00}-{1}.out.txt' -f ($active+1),$keys[$active]); try { if (Test-Path -LiteralPath $outputPath -PathType Leaf) { $tail = (@(Get-Content -LiteralPath $outputPath -Tail 60 -ErrorAction Stop) -join "`n").Replace([string][char]0,''); $percent = [regex]::Matches($tail,'(?<![\d.,])(?:100(?:[.,]0+)?|\d{1,2}(?:[.,]\d+)?)\s*%'); if ($percent.Count) { $progress = $percent[$percent.Count-1].Value.Trim() + ' (last tool output, not overall progress)' }; $progressUpdated = (Get-Item -LiteralPath $outputPath -ErrorAction Stop).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'); }; } catch { $progress = 'Output not readable: ' + $_.Exception.Message }; }; $lastText = if ($lastStarted -ge 0) { '{0}/5 - {1}' -f ($lastStarted+1),$names[$lastStarted] } else { 'None recorded' }; $lastUpdate = if ($lastAt) { $lastAt.ToString('yyyy-MM-dd HH:mm:ss') } else { 'Run.log missing or empty' }; Write-Host "`n=== MAINTENANCE STATUS ==="; [pscustomobject][ordered]@{Checked=$now.ToString('yyyy-MM-dd HH:mm:ss'); Phase=$phase; CurrentStep=$stepText; StepElapsed=$elapsed; LastToolPercentage=$progress; OutputFileUpdated=$progressUpdated; CBSLastEntry=(Get-LogTimestamp "$env:windir\Logs\CBS\CBS.log"); DISMLastEntry=(Get-LogTimestamp "$env:windir\Logs\DISM\dism.log"); Worker=$worker; LastStartedStep=$lastText; LastLogUpdate=$lastUpdate; ResultOutcome=$outcome} | Format-List; $rows | Format-Table Step,Task,Status,ExitCode -AutoSize -Wrap; if ($active -ge 0 -and $heartbeatAt) { Write-Host ('Heartbeat: {0:s} {1}' -f $heartbeatAt,$heartbeat); if (($now-$heartbeatAt).TotalSeconds -gt 180) { Write-Warning 'No heartbeat within the last three minutes. This alone does not prove a hang.' } }; if ($phase -eq 'Restart countdown' -and -not $alive) { Write-Warning 'Countdown is only the last logged phase; the worker is not verified active.' }; Write-Host "Last log event: $lastEvent"; Write-Host "Run folder: $d"; Write-Host 'Snapshot only. Tool percentage and worker heartbeat do not prove useful progress or successful repairs.'; };

```


