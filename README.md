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

"POWERPNT","EXCEL","WINWORD","OneDrive","OUTLOOK","ms-teams","Teams","msedge","chrome"

"POWERPNT","EXCEL","WINWORD","OneDrive","OUTLOOK","ms-teams","Teams","msedge","chrome" | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Write-Host "Terminated: $($_.Name) (PID $($_.Id))" } catch { Write-Host "Failed to terminate: $($_.Name) (PID $($_.Id))" } } }


################ Reliability Monitor ###############
perfmon /rel

# This diagnostic script checks the "health" of the PC to find hidden installation blockers: it verifies if the system is unstable (low reliability score), hasn't been rebooted in over a week, is waiting for a reboot (registry locks), has the Windows Installer service stuck, or has failed recent Windows Updates.

Write-Host "Reliability Monitor" -f Cyan; $s = (Get-CimInstance Win32_ReliabilityStabilityMetrics | select -f 1).SystemStabilityIndex; Write-Host "Stability (1-10): " -NoNewline; if ($s -lt 5) { Write-Host $s -f Red }else { Write-Host $s -f Green }; $d = ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).Days; Write-Host "Uptime:             $d Days" -f $(if ($d -gt 7) { 'Yellow' }else { 'White' }); $p = @(); if (gp 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ea 0) { $p += 'CBS' }; if (gp 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ea 0) { $p += 'WU' }; if ((gp 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ea 0).PendingFileRenameOperations) { $p += 'Rename' }; Write-Host "Reboot Pending:     " -NoNewline; if ($p) { Write-Host "YES ($($p -join ','))" -f Red }else { Write-Host "NO" -f Green }; $m = (gps msiexec -ea 0); Write-Host "MSI Exec Busy:      " -NoNewline; if ($m) { Write-Host "YES" -f Yellow }else { Write-Host "NO" -f Green }; Write-Host "`nLast 5 Updates:" -f Cyan; (New-Object -Com Microsoft.Update.Searcher).QueryHistory(0, 5) | % { Write-Host ("[{0}] {1}" -f $_.Date.ToString('MM-dd'), $_.Title.SubString(0, [math]::Min(45, $_.Title.Length))) -f $(if ($_.ResultCode -eq 2) { 'Green' }else { 'Red' }) }

# ############## Software Versions installed on system ##########################

Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion | Sort-Object DisplayName

# ############## Event Viwer softwares installed by recent date #####################

Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='MsiInstaller';ID=1033,11724;StartTime=(Get-Date).AddDays(-5)} | % { $m=$_.Message; [PSCustomObject]@{Time=$_.TimeCreated.ToString('MM/dd/yyyy HH:mm:ss'); Action=if($_.Id -eq 11724){"Removed"}elseif($m -match "status: 0\."){"Installed"}else{"Failed"}; Name=if($m -match "Product(?: Name)?: (.*?)(?:\. Product Version:| --)"){$Matches[1]}else{"Unknown"}; Version=if($m -match "Product Version: ([0-9.]+)"){$Matches[1]}else{"N/A"}} } | ft -AutoSize

################ Scans the Application & System for "Critical" or "Error" level events from the last 24 hours, printing the most recent 20 failures ###############

$scanevnt=24; $s=(Get-Date).AddHours(-$scanevnt); 'Application','System' | % { Write-Host "`nLOG: $_" -f Cyan; Write-Host ('='*60); try { Get-WinEvent -FilterHashtable @{LogName=$_; Level=1,2; StartTime=$s} -MaxEvents 20 -EA Stop | Sort TimeCreated | % { Write-Host ("[{0}] {1:MM-dd HH:mm} ID={2} Src={3}" -f $_.LogName,$_.TimeCreated,$_.Id,$_.ProviderName) -f Magenta; ($_.Message -split "`r?`n" | ?{$_} | select -f 5) | % { Write-Host "    $_" -f White }; Write-Host ('-'*60) -f DarkGray } } catch { Write-Host "  FAIL REASON: $($_.Exception.Message)" -f Red } }

Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WHEA-Logger'; ID=1} -MaxEvents 2 | Format-List TimeCreated, Message

Get-WinEvent -FilterHashtable @{LogName='System'; ID=41,42,109,506,507,1001,6008; StartTime=(Get-Date).AddHours(-12)} -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName, Message | Format-List

Get-ChildItem -Path "C:\Windows\LiveKernelReports" -Recurse -File -ErrorAction SilentlyContinue | Select-Object FullName, Length, LastWriteTime

$kp = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Kernel-Power'; ID=41} -MaxEvents 3; foreach ($ev in $kp) { Write-Host "`n--- Crash Reboot Time: $($ev.TimeCreated) ---" -ForegroundColor Cyan; ([xml]$ev.ToXml()).Event.EventData.Data | Format-Table Name, '#text' -AutoSize }

Copy-Item -Path "C:\Windows\LiveKernelReports\WHEA\*.dmp" -Destination "C:\CrashAnalysis" -Force; Get-ChildItem "C:\CrashAnalysis"

# ###################################################################################################################
```
### Disk and File System
```powershell

cd "$env:USERPROFILE\downloads"

# MSIX / APPX
Add-AppxProvisionedPackage -Online -PackagePath "C:\path\app.msix" -DependencyPackagePath "C:\path\dependency.msix" -SkipLicense

# MSI
msiexec.exe /i "C:\path\installer.msi" /qn /norestart

#Exe "installer.exe /?" to identify
"C:\path\installer.exe" <#InstallShield#> /s /v"/qn /norestart" <#Inno Setup#> /VERYSILENT /SUPPRESSMSGBOXES /NORESTART <#NSIS#> /S <#WiX Toolset#> -quiet

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
# Devmgmt.msc > Network adapters > (e.g., Intel Wi-Fi 6E AX211) and select Properties > Advanced
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

$exePath = "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeClickToRun.exe"
$args = "scenario=Repair RepairType=FullRepair DisplayLevel=False forceappshutdown=True"

Start-Process -FilePath $exePath -ArgumentList $args -Wait

# ############################## Delete OST and clear cache Teams/Outlook ##############################

Stop-Process -Name "OUTLOOK" -Force -ea 0; Get-CimInstance Win32_UserProfile | ? { !$_.Special -and $_.Loaded } | % { $l="$($_.LocalPath)\AppData\Local\Microsoft\Outlook"; "$l\*.ost", "$l\RoamCache\*", "$l\HubAppFileCache\*", "$l\Offline Address Books\*" | Remove-Item -Recurse -Force -ea 0 }

Stop-Process -Name "Teams" -Force -ea 0; Get-CimInstance Win32_UserProfile | ? { !$_.Special -and $_.Loaded } | % { $r="$($_.LocalPath)\AppData\Roaming\Microsoft\Teams"; "$r\*" | Remove-Item -Recurse -Force -ea 0 }

# Reduce OST size
Get-ChildItem Registry::HKEY_USERS | ? { $_.Name -match "S-1-5-21-[\d\-]+$" } | % { $p="$($_.PSPath)\Software\Microsoft\Office\16.0\Outlook\Cached Mode"; if(!(Test-Path $p)){New-Item $p -Force|Out-Null}; Set-ItemProperty $p -Name "SyncWindowSetting" -Value 3 -Type DWord }

# ############################## Outlook Monthly Channel ##############################

"POWERPNT","EXCEL","WINWORD","OUTLOOK" | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Write-Host "Terminated: $($_.Name) (PID $($_.Id))" } catch { Write-Host "Failed to terminate: $($_.Name) (PID $($_.Id))" } } }

Set-Location "C:\Program Files\Common Files\Microsoft Shared\ClickToRun"
.\OfficeC2RClient.exe /changesetting Channel=MonthlyEnterprise
.\OfficeC2RClient.exe /update user

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

Add-Type -A System.Windows.Forms,System.Drawing; function n($m){$b=New-Object System.Windows.Forms.NotifyIcon;$b.Icon=[System.Drawing.SystemIcons]::Information;$b.Visible=$true;$b.ShowBalloonTip(5000,'Software Install',$m,[System.Windows.Forms.ToolTipIcon]::Info);sleep -m 600;$b.Dispose()}; $u='https://download.lenovo.com/pccbbs/thinkvantage_en/system_update_5.08.03.59.exe'; $p="$env:TEMP\lenovo_update.exe"; n 'Downloading Lenovo System Update...'; (New-Object System.Net.WebClient).DownloadFile($u, $p); n 'Installing Lenovo System Update...'; start $p -Arg '/VERYSILENT /NORESTART' -Wait; ri $p -Force; n 'Lenovo System Update Installed Successfully'; sleep 2

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
# Attempts DISM/SFC repairs and component-store cleanup, deletes temporary files older than seven days from Windows and executing-account temp folders, empties that account's system-drive Recycle Bin, optimizes the system drive, requests idle-sleep prevention, displays progress, logs results, and forces a restart after a cancellable 120-second countdown when the desktop is available and safety checks pass.

& {$ErrorActionPreference='Stop';if($env:OS -ne 'Windows_NT'){throw 'Windows is required.'};if(!(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Use an elevated PowerShell window.'};if(![Environment]::UserInteractive -or [Diagnostics.Process]::GetCurrentProcess().SessionId -eq 0){throw 'Use PowerShell on the signed-in desktop, not a service shell.'};$d="$env:SystemDrive\Temp\SystemMaintenance\$(Get-Date -Format yyyyMMdd-HHmmss-fff)-$PID";New-Item -ItemType Directory -Path $d -Force | Out-Null;Write-Host "Logs: $d";$c={$ErrorActionPreference='Stop';$t=$f=$p=$null;$blocked=$false;$reboot=$false;$issues=0;function Log($m){Add-Content -LiteralPath "$d\Run.log" -Encoding UTF8 -Value "$(Get-Date -Format s) $m"};function Tick{[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 100};function Record-Failure($err){try{Log "STOPPED: $($err.Exception.Message) No reboot. See Error.txt.";$detail=@(($err|Format-List * -Force|Out-String -Width 4096),$err.InvocationInfo.PositionMessage,$err.ScriptStackTrace,$err.Exception.ToString());$detail|Set-Content -LiteralPath "$d\Error.txt" -Encoding UTF8}catch{}};function Countdown([ValidateRange(1,3600)][int]$seconds=120,[switch]$Preview,[switch]$ValidateOnly){ $r=$null; try { Log "COUNTDOWN UI: creating $seconds-second notice."; $r=New-Object Windows.Forms.Form -Property @{Text='Restart - save your work';ClientSize=(New-Object Drawing.Size(420,210));StartPosition='CenterScreen';TopMost=$true;ShowInTaskbar=$true;MinimizeBox=$false;MaximizeBox=$false;FormBorderStyle='FixedDialog';Tag='count'}; $title=New-Object Windows.Forms.Label -Property @{Text='Your computer will restart automatically';Left=15;Top=12;Width=390;Height=25;Font=(New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold))}; $msg=New-Object Windows.Forms.Label -Property @{Text='Save and close your work now. Unsaved work can be lost. No confirmation is required.';Left=15;Top=40;Width=390;Height=40;Font=(New-Object Drawing.Font('Segoe UI',9))}; if($Preview){$r.Text='TEST ONLY - no restart';$title.Text='Automatic countdown preview';$msg.Text='No repairs, cleanup or restart. This window closes after the countdown.'}; $clock=New-Object Windows.Forms.Label -Property @{Left=15;Top=82;Width=390;Height=50;TextAlign='MiddleCenter';Font=(New-Object Drawing.Font('Segoe UI',28,[Drawing.FontStyle]::Bold))}; $bar=New-Object Windows.Forms.ProgressBar -Property @{Left=15;Top=140;Width=390;Height=15}; $bar.Minimum=0;$bar.Maximum=$seconds;$bar.Value=$seconds; $later=New-Object Windows.Forms.Button -Property @{Text='Cancel restart';Left=260;Top=169;Width=145;Height=28}; $later.Add_Click({param($sender,$eventArgs);$sender.FindForm().Tag='cancel'}); $r.Add_FormClosing({param($sender,$eventArgs);if($sender.Tag -ne 'done'){$sender.Tag='cancel';if($eventArgs.CloseReason -eq 'UserClosing'){$eventArgs.Cancel=$true}}}); $r.Controls.AddRange(@($title,$msg,$clock,$bar,$later)); if($ValidateOnly){Log "UI PRECHECK OK: Maximum=$($bar.Maximum); Value=$($bar.Value).";return $true}; function Front { $r.WindowState='Normal'; $area=[Windows.Forms.Screen]::FromPoint([Windows.Forms.Cursor]::Position).WorkingArea; $r.Location=New-Object Drawing.Point(($area.Left+[int](($area.Width-$r.Width)/2)),($area.Top+[int](($area.Height-$r.Height)/2))); [void]$t::ShowWindow($r.Handle,9);$r.BringToFront();$r.Activate();[void]$t::SetForegroundWindow($r.Handle); try{[System.Media.SystemSounds]::Exclamation.Play()}catch{} }; $sw=New-Object Diagnostics.Stopwatch;$running=$waiting=$warn30=$warn10=$false; $r.Show();[void]$t::ShowWindow($r.Handle,5);$r.ActiveControl=$later; Log 'COUNTDOWN NOTICE: automatic; no confirmation required.'; while($r.Tag -ne 'cancel'){ [Windows.Forms.Application]::DoEvents();if($r.Tag -eq 'cancel'){break}; if(!$t::InputAvailable()){ if(!$waiting){Log 'RESTART WAITING: desktop unavailable; countdown resets until it returns.'}; $waiting=$true;$running=$false;$sw.Reset(); [void]$t::SetThreadExecutionState([uint32]2147483648); $clock.Text='Waiting for desktop';$bar.Value=$seconds;Tick;continue }; if(!$running){ if(!$t::SetThreadExecutionState([uint32]2147483651)){throw 'Countdown keep-awake request failed.'}; $running=$true;$waiting=$warn30=$warn10=$false;$sw.Restart();Front; if(!$t::IsWindowVisible($r.Handle)){throw 'Countdown window not visible; restart suppressed.'}; Log "COUNTDOWN START: $seconds seconds." }; $left=[int][math]::Max(0,[math]::Ceiling($seconds-$sw.Elapsed.TotalSeconds)); $clock.Text=('{0:00}:{1:00}' -f [int][math]::Floor($left/60),($left%60));$bar.Value=$left; if($left -eq 0){Log 'COUNTDOWN ELAPSED.';return $true}; if($left -le 10 -and !$warn10){$warn10=$warn30=$true;Front}elseif($left -le 30 -and !$warn30){$warn30=$true;Front}; Tick }; Log 'RESTART CANCELLED.';return $false }finally{ if($r){$r.Tag='done';$r.Close();$r.Dispose()};[void]$t::SetThreadExecutionState([uint32]2147483648) } };try {Log "BUILD: reviewed-stopwatch-20261015";Log "START: $([Security.Principal.WindowsIdentity]::GetCurrent().Name); session=$([Diagnostics.Process]::GetCurrentProcess().SessionId); 64-bit=$([Environment]::Is64BitProcess)";$t=Add-Type -MemberDefinition '[DllImport("kernel32.dll")]public static extern uint SetThreadExecutionState(uint f);[DllImport("kernel32.dll")]public static extern uint GetConsoleProcessList([Out] uint[] p,uint n);[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h,int n);[DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);[DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h); [DllImport("kernel32.dll")]static extern uint GetCurrentThreadId(); [DllImport("user32.dll")]static extern IntPtr GetThreadDesktop(uint id); [DllImport("user32.dll",EntryPoint="GetUserObjectInformationW")]static extern bool Info(IntPtr h,int x,out int v,int n,out int needed); [DllImport("wtsapi32.dll",EntryPoint="WTSQuerySessionInformationW")]static extern bool Query(IntPtr s,int id,int c,out IntPtr b,out int n); [DllImport("wtsapi32.dll")]static extern void WTSFreeMemory(IntPtr b); public static bool InputAvailable(){IntPtr b=IntPtr.Zero;int n;try{if(!Query(IntPtr.Zero,-1,8,out b,out n)||b==IntPtr.Zero||n<4||System.Runtime.InteropServices.Marshal.ReadInt32(b)!=0)return false;int io,m;return Info(GetThreadDesktop(GetCurrentThreadId()),6,out io,4,out m)&&io!=0;}finally{if(b!=IntPtr.Zero)WTSFreeMemory(b);}}' -Name Pwr -PassThru;[uint32[]]$ids=New-Object uint32[] 64;$count=$t::GetConsoleProcessList($ids,64);if(!$count -or $count -gt 64 -or $ids -contains $launcherPID){throw 'Console check failed; not started.'};Log "Separate console verified: worker PID=$PID; launcher PID=$launcherPID";Add-Type -AssemblyName System.Windows.Forms;[Windows.Forms.Application]::EnableVisualStyles();[void](Countdown 120 -ValidateOnly);$f=New-Object Windows.Forms.Form -Property @{Text='System Maintenance';Width=540;Height=185;StartPosition='CenterScreen';TopMost=$true;ControlBox=$true;MinimizeBox=$true;MaximizeBox=$false;ShowInTaskbar=$true;FormBorderStyle='FixedSingle'};$l=New-Object Windows.Forms.Label -Property @{Left=15;Top=15;Width=495;Height=40};$b=New-Object Windows.Forms.ProgressBar -Property @{Left=15;Top=60;Width=495;Style='Marquee'};$f.Add_FormClosing({param($s,$e);if(!$s.Tag -and $e.CloseReason -eq 'UserClosing'){$e.Cancel=$true}});$f.Add_Resize({param($sender,$eventArgs);if($sender.WindowState -eq 'Normal'){$sender.Invalidate($true);$sender.Update()}});$f.Controls.AddRange(@($l,$b));$f.Show();[void]$t::ShowWindow($f.Handle,5);$f.Activate();Tick;if(!$t::IsWindowVisible($f.Handle)){throw 'UI unavailable; not started.'};Log "UI ready: worker PID=$PID";if(Get-Process sfc,dism -ErrorAction SilentlyContinue){throw 'SFC/DISM already running; not started.'};if(!$t::SetThreadExecutionState([uint32]2147483651)){throw 'Keep-awake request failed.'};$steps=@( @('DISM','DISM.exe','/Online /Cleanup-Image /RestoreHealth /NoRestart'), @('SFC','sfc.exe','/scannow'), @('Components','DISM.exe','/Online /Cleanup-Image /StartComponentCleanup /NoRestart'), @('Cleanup',{$cutoff=(Get-Date).AddDays(-7);$counts=@(0,0);function Clean($dir){if(!$dir){return};$r=Get-Item -LiteralPath $dir -Force -ErrorAction SilentlyContinue;if(!$r -or !$r.PSIsContainer -or ($r.Attributes -band [IO.FileAttributes]::ReparsePoint)){return};if($r.FullName.TrimEnd('\') -eq $r.Root.FullName.TrimEnd('\')){return};foreach($i in (Get-ChildItem -LiteralPath $r.FullName -Force -ErrorAction SilentlyContinue)){if($i.Attributes -band [IO.FileAttributes]::ReparsePoint){continue};if($i.PSIsContainer){Clean $i.FullName}elseif($i.LastWriteTime -lt $cutoff){try{Remove-Item -LiteralPath $i.FullName -Force;$counts[0]++}catch{$counts[1]++}} } };Clean $env:TEMP;Clean "$env:windir\Temp";"Temp deleted=$($counts[0]); skipped=$($counts[1]); links/unreadable folders excluded.";Clear-RecycleBin -DriveLetter ([char]$env:SystemDrive[0]) -Force -ErrorAction Stop;'Executing account: system-drive Recycle Bin cleared.' }), @('Optimize',{Optimize-Volume -DriveLetter ([char]$env:SystemDrive[0]) -Verbose}) );$n=0;foreach($s in $steps){$n++;if($n -le 3 -and !$blocked -and (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction Stop)){$blocked=$true;$reboot=$true;$issues++;Log 'REBOOT REQUIRED: CBS flag found; servicing deferred, other tasks enabled.' };if($n -le 3 -and $blocked){$state=if($reboot){'DEFERRED_REBOOT'}else{'SKIPPED_AFTER_ERROR'};Log "$state step ${n}: $($s[0]); not performed.";continue };$l.Text="Step $n/5: $($s[0])";Tick;$o="$d\$('{0:00}' -f $n)-$($s[0])";Log "START step ${n}: $($s[0])";if($s[1] -is [scriptblock]){$body='$ErrorActionPreference="Stop";$ProgressPreference="SilentlyContinue";try{'+$s[1]+';exit 0}catch{[Console]::Error.WriteLine(($_|Out-String));exit 1}';$enc=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body));$exe="$PSHOME\powershell.exe";$arg="-NoProfile -NonInteractive -OutputFormat Text -EncodedCommand $enc";}else{$exe="$env:windir\System32\$($s[1])";$arg=$s[2]};$p=New-Object Diagnostics.Process;$p.StartInfo=New-Object Diagnostics.ProcessStartInfo -Property @{FileName="$env:windir\System32\cmd.exe";Arguments=('/d /v:off /s /c ""{0}" {1} 1>"{2}.out.txt" 2>"{2}.err.txt""' -f $exe,$arg,$o);UseShellExecute=$false;CreateNoWindow=$false;WindowStyle='Hidden';WorkingDirectory=$env:windir};if($p.StartInfo.Arguments.Length -gt 8000){throw 'Worker command is too long.'};if(!$p.Start()){throw 'Could not start maintenance.'};$w=[Diagnostics.Stopwatch]::StartNew();while(!$p.HasExited){Tick;if($w.Elapsed.TotalMinutes -ge 180){throw "$($s[0]) timed out; tool NOT killed. Inspect processes; no reboot."}};$p.WaitForExit();$rc=$p.ExitCode;$p.Dispose();$p=$null;Log "END $($s[0]): exit=$rc; elapsed=$($w.Elapsed)";$text='';if($s[0] -eq 'SFC'){$r=[IO.File]::ReadAllBytes("$o.out.txt");if($r.Length -gt 1 -and ($r[1] -eq 0 -or ($r[0] -eq 255 -and $r[1] -eq 254))){$text=[Text.Encoding]::Unicode.GetString($r).TrimStart([char]65279)}else{$text=[IO.File]::ReadAllText("$o.out.txt")};$text+="`r`n"+[IO.File]::ReadAllText("$o.err.txt");[IO.File]::WriteAllText("$d\02-SFC.txt",$text,[Text.Encoding]::UTF8) };if($s[0] -eq 'SFC' -and $rc -eq 1 -and $text -match '(?is)\bsystem\s+repair\s+pending\b.*?\brequires\s+(?:a\s+)?reboot\b'){$blocked=$true;$reboot=$true;$issues++;Log 'DEFERRED_REBOOT SFC; other steps continue.';continue };if($rc -eq 3010 -and $s[1] -eq 'DISM.exe'){$blocked=$true;$reboot=$true;$issues++;Log "REBOOT REQUIRED: $($s[0]) exit=3010; defer servicing, continue other tasks.";continue };if($rc -ne 0){$issues++;if($n -le 3){$blocked=$true};Log "ERROR $($s[0]): exit=$rc; see $o.out.txt/$o.err.txt. Continuing independent tasks.";continue };Log "OK $($s[0]): exit=0; check tool output." };Log "SEQUENCE FINISHED: issues/deferred=$issues; rebootRequired=$reboot.";if($blocked){Log 'FOLLOW-UP: rerun skipped servicing; no automatic resume.'};$f.Hide();if(Countdown 120){if(!$t::InputAvailable()){Log 'RESTART SUPPRESSED: desktop unavailable.'}elseif(Get-Process sfc,dism -ErrorAction SilentlyContinue){throw 'SFC/DISM running; restart suppressed.'}else{Log 'Requesting forced restart after automatic countdown.';Restart-Computer -Force}} }catch{Record-Failure $_}finally{if($p){$p.Dispose()};if($t){[void]$t::SetThreadExecutionState([uint32]2147483648)};if($f){$f.Tag=$true;$f.Close();$f.Dispose()} } };$ps="$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe";if([Environment]::Is64BitOperatingSystem -and ![Environment]::Is64BitProcess){$ps="$env:windir\Sysnative\WindowsPowerShell\v1.0\powershell.exe"};$e=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(('$d='''+$d.Replace("'","''")+''';$launcherPID='+$PID+';')+$c.ToString()));if(($e.Length+$ps.Length+80) -gt 32000){throw 'Encoded command is too long for this launcher.'};$p=Start-Process $ps -WindowStyle Hidden -ArgumentList "-NoProfile -STA -OutputFormat Text -EncodedCommand $e" -PassThru;"$(Get-Date -Format s) Launched PID=$($p.Id); original shell PID=$PID" | Set-Content -LiteralPath "$d\Launch.log" -Encoding UTF8;Write-Host "Maintenance PID: $($p.Id). Logs: $d" }


################ Read logs outputted ###############
& { $root="$env:SystemDrive\Temp\SystemMaintenance"; $run=Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1; if($run){ Write-Host "`nLatest run folder: $($run.FullName)"; foreach($name in 'Launch.log','Run.log','01-DISM.out.txt','01-DISM.err.txt','02-SFC.txt','02-SFC.err.txt'){ $file=Join-Path $run.FullName $name; Write-Host "`n--- $name ---"; if(!(Test-Path -LiteralPath $file -PathType Leaf)){ Write-Host '(not created)'; continue }; try { if((Get-Item -LiteralPath $file -ErrorAction Stop).Length -eq 0){ Write-Host '(empty)' }else{ Get-Content -LiteralPath $file -Tail 40 -ErrorAction Stop } }catch{ Write-Warning "Could not read ${name}: $($_.Exception.Message)" } } }else{ Write-Warning "No maintenance run folder found under $root" }; Write-Host "`n--- Current processes; this shell PID is $PID ---"; Get-Process -Name powershell,pwsh,dism,sfc -IncludeUserName -ErrorAction SilentlyContinue | Sort-Object SessionId,Id | Format-Table ProcessName,Id,SessionId,UserName,MainWindowTitle -AutoSize }



