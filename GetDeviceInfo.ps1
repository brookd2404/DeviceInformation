<#PSScriptInfo
 
.VERSION 4.0
 
.AUTHOR David Brook
 
.COMPANYNAME EUC 365
 
.COPYRIGHT
 
.TAGS Microsoft Endpoint Manager; Intune, Azure AD, AAD
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
Version 4.0: Converted Setting to JSON for ease of editing
Version 3.0: Added Branding 
Version 2.0: Added Dynamic Formatting
Version 1.0: Original published version.
 
#>


<#
.SYNOPSIS
This script will gather information to assist in troubleshooting 
 
.DESCRIPTION
This will display the device name, serial number, model, manufacturer, Intune Device ID, Azure AD Device ID and IP Information 

.PARAMETER SettingsFile
The location of a custom settings file
Default: '$PSScriptRoot\settings.json'

.EXAMPLE
.\GetDeviceInfo.ps1 -SettingsFile '.\Settings2.json'
#>


[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNull()] 
    [ValidateScript({Test-Path $_})]
    [string]
    $SettingsFile = "$PSScriptRoot\settings.json"
)

#Sets the title of the powershell window
$host.UI.RawUI.WindowTitle = "$ENV:Computername Machine Information" 
#This is to dispaly an output to the shell window when launching as an EXE
Write-Host "Gathering Information" -ForegroundColor Green
$CurrentFolder = Get-Location | Select-Object -ExpandProperty Path #Gets the current folder, Used for the icon 
$Settings = Get-Content $SettingsFile | ConvertFrom-Json #Import the Settings file


#Import the system assemblies
Add-Type -Assembly System.Windows.Forms
Add-Type -Assembly System.Drawing

#form alignments and height ad width variables
$colleft = 15
$colright = 195

$DateWhen = (Get-Date).ToShortDateString() #The date when an action is performed
$TimeWhen = (Get-Date).ToLongTimeString() #The time when an action is performed 
$IPinfo = Get-NetIPConfiguration -All | Where-Object {($_.Name -notlike "*Bluetooth*") -and ($($_.NetAdapter.Status) -notlike "*Disconnected*")} | Select-Object InterfaceAlias, InterfaceDescription, NetProfile, IPv4Address, IPv6Address # This IP Information from the client excluding disconnected sessions and bluetooth

# These sections format the output depending on the user (i.e Window or Clipboard)
$IPinfoForWindow = $IPinfo | ForEach-Object {
    Write-Output  "
    
Interface Name:               $($_.InterfaceAlias)
Interface Description:      $($_.InterfaceDescription)
Profile Name:                   $($_.NetProfile.Name)
IPv4 Address:                    $($_.IPv4Address.IpAddress)
IPv6 Address:                         $($_.IPv6Address.IpAddress)"
} 

$IPinfoForCB = $IPinfo | ForEach-Object {
    Write-Output  "
Interface Name: $($_.InterfaceAlias)
Interface Description: $($_.InterfaceDescription)
Profile Name: $($_.NetProfile.Name)
IPv4 Address: $($_.IPv4Address.IpAddress)
IPv6 Address: $($_.IPv6Address.IpAddress)
"
} 

$DeviceSerial = Get-WmiObject win32_bios | Select-Object -ExpandProperty Serialnumber #Get the deivce serial number
$DeviceInfo = Get-WmiObject -Class:Win32_ComputerSystem #Get deivce info for Manufacturer and Model
$IntuneDeviceID = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot\EstablishedCorrelations" #get the intune device ID from the registry 
$AADID = dsregcmd /status | Select-String -Pattern "DeviceID" | Out-String #Get the information for AzureDeivce ID
$User = $($env:USERNAME.ToUpper()).ToString()

#The form as a function
Function Information-Form{

#This information is what is coppied to the clipboard
$ClipboardInfo = "Current User: $User
Computer Name: $($ENv:Computername.ToUpper())
Device Serial: $DeviceSerial
Device Manufacturer: $($DeviceInfo.Manufacturer)
Device Model: $($DeviceInfo.Model)
Logon Server: $($($ENV:LOGONSERVER.ToUpper()).SubString(2))
Intune Device ID: $($IntuneDeviceID.EntDMID)
AzureAD Device ID: $($($($AADID.Split(":")[1]).SubString(1).Trim()))

IP Information: 
$IPInfoForCB

Information gathered $DateWhen $TimeWhen
"

    SET-Clipboard $ClipboardInfo #Copy the above info to the clipboiard
    
    # Build Form
    $InfoForm = New-Object System.Windows.Forms.Form
    $InfoForm.icon = "$($Settings.Branding.FormICON)"
    $InfoForm.Text = "$ENV:Computername Machine information"
    $InfoForm.Size = New-Object System.Drawing.Size(0,0)
    $InfoForm.BackColor = "White"
    #$InfoForm.MinimumSize = New-Object -TypeName Drawing.Size (0,0)
    #$InfoForm.MaximumSize = New-Object -TypeName Drawing.Size (1000,1000)
    $InfoForm.FormBorderStyle = "FixedDialog"
    $InfoForm.MaximizeBox = $false
    $InfoForm.SizeGripStyle = "Hide"
    $InfoForm.StartPosition = "CenterScreen"
    $InfoForm.Topmost = $false
    $InfoForm.KeyPreview = $True
    $InfoForm.AutoSize = $True

    # Create the 'Information gathered' label
    $iGLabel = New-Object -TypeName windows.Forms.Label
    $iGLabel.Text = "Information gathered $DateWhen $TimeWhen"
    $iGLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $iGLabel.Location = New-Object -TypeName Drawing.Point $colleft, 20
    $iGLabel.AutoSize = $true
    $iGLabel.Visible = $true
    $InfoForm.Controls.Add($iGLabel)

    # Create the Image Brandind 
    $brandLogo = New-Object -TypeName windows.Forms.PictureBox
    $brandLogo.Image = [System.Drawing.Image]::Fromfile("$($Settings.Branding.logo.image)")
    $brandLogo.Location = New-Object -TypeName Drawing.Point 385, 20
    $brandLogo.Height = $($Settings.Branding.logo.height)
    $brandLogo.Width = $($Settings.Branding.logo.width)
    $brandLogo.Visible = $true
    $InfoForm.Controls.Add($brandLogo)

    # Create the 'URL' label
    $uRLLabel = New-Object -TypeName windows.Forms.LinkLabel
    $uRLLabel.Text = "$($Settings.Branding.URL)"
    $uRLLabel.LinkColor = "BLUE"
    $uRLLabel.ActiveLinkColor = "PURPLE"
    $uRLLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $uRLLabel.Location = New-Object -TypeName Drawing.Point $colleft, 45
    $uRLLabel.AutoSize = $true
    $uRLLabel.Visible = $true
    $uRLLabel.add_Click({[system.Diagnostics.Process]::start("$($Settings.Branding.URL)")}) 
    $InfoForm.Controls.Add($uRLLabel)

    # Create the 'NOTE' label
    $cBNoteLabel = New-Object -TypeName windows.Forms.Label
    $cBNoteLabel.Text = "NOTE: This information has been copied to your clipboard"
    $cBNoteLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",8, [System.Drawing.FontStyle]::Regular)
    $cBNoteLabel.Location = New-Object -TypeName Drawing.Point $colleft, 70
    $cBNoteLabel.AutoSize = $true
    $cBNoteLabel.Visible = $true
    $InfoForm.Controls.Add($cBNoteLabel)

    # Create the 'Current User' label
    $cULabel = New-Object -TypeName windows.Forms.Label
    $cULabel.Text = "Current User:"
    $cULabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $cULabel.Location = New-Object -TypeName Drawing.Point $colleft, 100
    #$cULabel.TextAlign = "MiddleCenter"
    $cULabel.AutoSize = $true
    $cULabel.Visible = $true
    $InfoForm.Controls.Add($cULabel)
    #Create the Current User Value Field
    
    $cUValue = New-Object -TypeName windows.Forms.Label
    $cUValue.Text = $User
    $cUValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $cUValue.Location = New-Object -TypeName Drawing.Point $colright, 100
    $cUValue.AutoSize = $true
    $cUValue.Visible = $true
    $InfoForm.Controls.Add($cUValue)

    # Create the 'Computer Name' label
    $cNLabel = New-Object -TypeName windows.Forms.Label
    $cNLabel.Text = "Computer Name:"
    $cNLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $cNLabel.Location = New-Object -TypeName Drawing.Point $colleft, 130
    #$cNLabel.TextAlign = "MiddleCenter"
    $cNLabel.AutoSize = $true
    $cNLabel.Visible = $true
    $InfoForm.Controls.Add($cNLabel)
    #Create the Computer Name Value Field
    $cNValue = New-Object -TypeName windows.Forms.Label
    $cNValue.Text = "$($env:Computername.ToUpper())"
    $cNValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $cNValue.Location = New-Object -TypeName Drawing.Point $colright, 130
    $cNValue.AutoSize = $true
    $cNValue.Visible = $true
    $InfoForm.Controls.Add($cNValue)

    # Create the Device Serial Number label
    $dSLabel = New-Object -TypeName windows.Forms.Label
    $dSLabel.Text = "Device Serial Number:"
    $dSLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $dSLabel.Location = New-Object -TypeName Drawing.Point $colleft, 160
    #$dSLabel.TextAlign = "MiddleCenter"
    $dSLabel.AutoSize = $true
    $dSLabel.Visible = $true
    $InfoForm.Controls.Add($dSLabel)
    #Create the Device Serial Number Value Field
    $dSValue = New-Object -TypeName windows.Forms.Label
    $dSValue.Text = "$DeviceSerial"
    $dSValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $dSValue.Location = New-Object -TypeName Drawing.Point $colright, 160
    $dSValue.AutoSize = $true
    $dSValue.Visible = $true
    $InfoForm.Controls.Add($dSValue)

    # Create the 'Device Manufacturer' label
    $dMaLabel = New-Object -TypeName windows.Forms.Label
    $dMaLabel.Text = "Device Manufacturer:"
    $dMaLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $dMaLabel.Location = New-Object -TypeName Drawing.Point $colleft, 190
    #$dMaLabel.TextAlign = "MiddleCenter"
    $dMaLabel.AutoSize = $true
    $dMaLabel.Visible = $true
    $InfoForm.Controls.Add($dMaLabel)
    #Create the Device Manufacturer Value Field
    $dMaValue = New-Object -TypeName windows.Forms.Label
    $dMaValue.Text = "$($DeviceInfo.Manufacturer)"
    $dMaValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $dMaValue.Location = New-Object -TypeName Drawing.Point $colright, 190
    $dMaValue.AutoSize = $true
    $dMaValue.Visible = $true
    $InfoForm.Controls.Add($dMaValue)

    # Create the 'Device Model' label
    $dMoLabel = New-Object -TypeName windows.Forms.Label
    $dMoLabel.Text = "Device Model:"
    $dMoLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $dMoLabel.Location = New-Object -TypeName Drawing.Point $colleft, 220
    #$dMoLabel.TextAlign = "MiddleCenter"
    $dMoLabel.AutoSize = $true
    $dMoLabel.Visible = $true
    $InfoForm.Controls.Add($dMoLabel)
    #Create the Device Model Value Field
    $dMoValue = New-Object -TypeName windows.Forms.Label
    $dMoValue.Text = "$($DeviceInfo.Model)"
    $dMoValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $dMoValue.Location = New-Object -TypeName Drawing.Point $colright, 220
    $dMoValue.AutoSize = $true
    $dMoValue.Visible = $true
    $InfoForm.Controls.Add($dMoValue)

    # Create the 'Logon Server' label
    $lSLabel = New-Object -TypeName windows.Forms.Label
    $lSLabel.Text = "Logon Server:"
    $lSLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $lSLabel.Location = New-Object -TypeName Drawing.Point $colleft, 260
    #$lSLabel.TextAlign = "MiddleCenter"
    $lSLabel.AutoSize = $true
    $lSLabel.Visible = $true
    $InfoForm.Controls.Add($lSLabel)
    #Create the Logon Server Value Field
    $lSValue = New-Object -TypeName windows.Forms.Label
    $lSValue.Text = "$($env:LOGONSERVER.Substring(2))"
    $lSValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $lSValue.Location = New-Object -TypeName Drawing.Point $colright, 260
    $lSValue.AutoSize = $true
    $lSValue.Visible = $true
    $InfoForm.Controls.Add($lSValue)

    # Create the 'Intune Device ID' label
    $inDLabel = New-Object -TypeName windows.Forms.Label
    $inDLabel.Text = "Intune Device ID:"
    $inDLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $inDLabel.Location = New-Object -TypeName Drawing.Point $colleft, 290
    $inDLabel.AutoSize = $true
    $inDLabel.Visible = $true
    $InfoForm.Controls.Add($inDLabel)
    #Create the Intune Device ID Value Field
    $inDValue = New-Object -TypeName windows.Forms.Label
    $inDValue.Text = "$($IntuneDeviceID.EntDMID)"
    $inDValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $inDValue.Location = New-Object -TypeName Drawing.Point $colright, 290
    $inDValue.AutoSize = $true
    $inDValue.Visible = $true
    $InfoForm.Controls.Add($inDValue)

    # Create the 'AzureAD Device ID' label
    $aADLabel = New-Object -TypeName windows.Forms.Label
    $aADLabel.Text = "AzureAD Device ID:"
    $aADLabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $aADLabel.Location = New-Object -TypeName Drawing.Point $colleft, 320
    $aADLabel.AutoSize = $true
    $aADLabel.Visible = $true
    $InfoForm.Controls.Add($aADLabel)
    #Create the AzureAD Device ID Value Field
    $aADValue = New-Object -TypeName windows.Forms.Label
    $aADValue.Text = "$($($AADID.Split(":")[1]).SubString(1))"
    $aADValue.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $aADValue.Location = New-Object -TypeName Drawing.Point $colright, 320
    $aADValue.AutoSize = $true
    $aADValue.Visible = $true
    $InfoForm.Controls.Add($aADValue)

    # Create the 'IP Information' label
    $iPILabel = New-Object -TypeName windows.Forms.Label
    $iPILabel.Text = "IP Information:"
    $iPILabel.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $iPILabel.Location = New-Object -TypeName Drawing.Point $colleft, 350
    $iPILabel.AutoSize = $true
    $iPILabel.Visible = $true
    $InfoForm.Controls.Add($iPILabel)
    #Create the IP Information Value Field
    $iPIValue = New-Object -TypeName windows.Forms.Label
    $iPIValue.Text = $IPinfoForWindow
    $iPIValue.Font = New-Object -TypeName Drawing.Font('Segoe ui',12, [System.Drawing.FontStyle]::Regular)
    $iPIValue.Location = New-Object -TypeName Drawing.Point $colleft, 350
    $iPIValue.AutoSize = $true
    $iPIValue.Visible = $true
    $InfoForm.Controls.Add($iPIValue)

    
    $ButtonHeight = $InfoForm.Height # Get current form Height
    # Close Button
    $CloseButton = New-Object System.Windows.Forms.Button
    $CloseButton.Location = New-Object Drawing.Size(285,$ButtonHeight)
    $CloseButton.Size = New-Object Drawing.Size(80,30)
    $CloseButton.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $CloseButton.Text = "Close"
    $CloseButton_OnClick = {
        Information-Form-CloseButClick
    }
    $CloseButton.Add_Click($CloseButton_OnClick)
   $InfoForm.Controls.Add($CloseButton)
   $InfoForm.Add_KeyDown({if (($_.KeyCode -eq "Enter") -or ($_.KeyCode -eq "Escape")){Information-Form-CloseButClick}})

    # Copy Button
    $reCopyButton = New-Object System.Windows.Forms.Button
    $reCopyButton.Location = New-Object Drawing.Size(135,$ButtonHeight)
    $reCopyButton.Size = New-Object Drawing.Size(80,30)
    $reCopyButton.Font = New-Object -TypeName Drawing.Font("Segoe ui",12, [System.Drawing.FontStyle]::Regular)
    $reCopyButton.Text = "Copy" 
    $reCopyButton_OnClick = {
        Set-Clipboard $ClipboardInfo
    }
    $reCopyButton.Add_Click($reCopyButton_OnClick)
   $InfoForm.Controls.Add($reCopyButton)

   #Show the Form 
    $InfoForm.ShowDialog()| Out-Null 
} #End Function
#Actions to perform when the click button is pressed  
Function Information-Form-CloseButClick
{
   $InfoForm.Close()
   $InfoForm.Dispose()
}
#Call the Form
Information-Form