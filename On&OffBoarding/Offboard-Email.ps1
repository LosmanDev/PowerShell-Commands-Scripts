<#
############################################################################# 

Windows Template

############################################################################# 

#>

$ToEmail = Read-Host "Enter Recipient Email"
$UserName = Read-Host "Enter User Name"
$RawDate = Read-Host "Enter Offboard Date (Format: 12312025)"

try {
    $OffboardDate = [DateTime]::ParseExact($RawDate, 'MMddyyyy', $null).ToString('MM-dd-yyyy')
}
catch {
    $OffboardDate = $RawDate
}

$SigPath = "C:\Users\user.name\AppData\Roaming\Microsoft\Signatures\John Sig (johndoe@company.com).htm"
$ImgFolder = "C:\Users\user.name\AppData\Roaming\Microsoft\Signatures\John Sig (johndoe@company.com)_files"
$Signature = Get-Content -Path $SigPath -Raw
$Signature = $Signature.Replace("John%20Sig%20(johndoe@company.com)_files", $ImgFolder)

$FilePath = "C:\Users\Public\Return_Equipment_$UserName.eml"

$EmlContent = @"
From: johndoe@company.com
To: $ToEmail
Subject: Hardware Return Request
X-Unsent: 1
Content-Type: text/html; charset="utf-8"

<html>
<head>
<style>
    body { font-family: Calibri, sans-serif; font-size: 11pt; color: #000000; }
    .red { color: #C00000; }
</style>
</head>
<body>
    <p>Dear $UserName,</p>
    
    <p>As your employment with Company concluded on $OffboardDate, we kindly request the
    return of specific company-issued IT equipment. To help finalize your
    departure, please return only the following items:</p>
    
    <ul>
        <li class="red"><span class="red">Laptop</span></li>
        <li><span>Laptop Charger</span></li>
        <li class="red"><span class="red">Company-issued mobile devices (iPad/iPhone) (if applicable)</span></li>
        <li>Mobile device chargers (if applicable)</li>
    </ul>
    
    <p>Please confirm your <span class="red">shipping address,</span> best <span class="red">phone number</span> and what <span class="red">equipment</span> you will return to
    make this process as easy as possible.</p>

    <p>A return box, including a pre-paid FedEx label, will be shipped to your address.</p>
    
    <p>Once you receive the box, please pack the equipment listed above and drop it off at any
    FedEx location within <span class="red">5 business days of your termination date.</span></p>
    
    <p>If you have any questions or need assistance, please let me know.</p>
    
    <p>Thank you for your attention to this matter, and we wish you the best in your future
    endeavors.</p>

    <br>
    
    $Signature
    
</body>
</html>
"@

$EmlContent | Out-File -FilePath $FilePath -Encoding utf8
Invoke-Item $FilePath

<#
############################################################################# 

Mac Template

############################################################################# 

#>


$ToEmail = Read-Host "Enter Recipient Email"
$UserName = Read-Host "Enter User Name"
$RawDate = Read-Host "Enter Offboard Date (Format: 12312025)"

try {
    $OffboardDate = [DateTime]::ParseExact($RawDate, 'MMddyyyy', $null).ToString('MM-dd-yyyy')
}
catch {
    $OffboardDate = $RawDate
}

$HtmlContent = @"
<style>
    body, p, span, div, a, td { 
        font-family: 'Aptos', sans-serif !important; 
        font-size: 11pt !important; 
        color: #000000 !important; 
    }
    .red { 
        color: #C00000 !important; 
    }
</style>
<p>Dear $UserName,</p>

<p>As your employment with Company concludes on $OffboardDate, we kindly request the
return of specific company-issued IT equipment. To help finalize your
departure, please return only the following items:</p>

<ul>
    <li class="red"><span class="red">Laptop</span></li>
    <li><span>Laptop Charger</span></li>
    <li class="red"><span class="red">Company-issued mobile devices (iPad/iPhone) (if applicable)</span></li>
    <li>Mobile device chargers (if applicable)</li>
</ul>

<p>Please confirm your <span class="red">shipping address,</span> best <span class="red">phone number</span> and what <span class="red">equipment</span> you will return to
make this process as easy as possible.</p>

<p>A return box, including a pre-paid FedEx label, will be shipped to your address.</p>

<p>Once you receive the box, please pack the equipment listed above and drop it off at any
FedEx location within <span class="red">5 business days of your termination date.</span></p>

<p>If you have any questions or need assistance, please let me know.</p>

<p>Thank you for your attention to this matter, and we wish you the best in your future
endeavors.</p>
"@

$TempHtml = [System.IO.Path]::GetTempFileName() + ".html"
$HtmlContent | Set-Content -Path $TempHtml -Encoding UTF8

bash -c "textutil -format html -convert rtf -stdout '$TempHtml' | pbcopy"

$Subject = [uri]::EscapeDataString("BeOne Medicines Hardware Return Request")
$Mailto = "mailto:$ToEmail`?subject=$Subject"

Start-Process -FilePath "open" -ArgumentList "-a `"Microsoft Outlook`"", "`"$Mailto`""

Remove-Item -Path $TempHtml -Force