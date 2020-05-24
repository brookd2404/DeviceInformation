<a href="https://github.com/brookd2404/DeviceInformation/issues"><img alt="GitHub issues" src="https://img.shields.io/github/issues/brookd2404/DeviceInformation?style=for-the-badge"></a>
<a href="https://twitter.com/intent/tweet?text=Look%20at%20This:&url=https%3A%2F%2Fgithub.com%2Fbrookd2404%2FDeviceInformation"><img alt="Twitter" src="https://img.shields.io/twitter/url?label=TWEET%20US&style=social&url=https%3A%2F%2Fgithub.com%2Fbrookd2404%2FDeviceInformation"></a>
# Get Device Information
<div style="text-align:center"><img src="https://i.imgur.com/DHffDxv.png?1" title="Device Info Form" style="float"/></div>

## Introduction
This Windows Form is written in PowerShell to gather information to aid in troubleshooting devices that are either Hybrid or Only Azure AD Joined. This script will also Get the Intune Device ID if it exists. 

This was initially only intended to be used in the organization I work for, however a colleague said I should share it with the Tech Community.  

NOTE: This is far from a finished or polished script and it still has a long way to go, however this script still functions even if some of the information is not obtainable. 

## How To's
### Running the Script
The script can be run as it stands from a Powershell prompt, you may however need to change the execution policy within your Powershell session by running **Set-ExecutionPolicy Bypass**. This however may be restricted by your Administrator. 

### Branding
Settings for branding can be changed in the Settings.json file, This includes;
- URL 
- Icon
- Logo (Including Height and Width)

 When amending the Logo and Icon, you can use a file is in the same directory by using **.\\\\** (This is because we are in JSON and using .\ does not suffice) before the file name intead of using a full path.

You may need to change the size parameters for the logo or you could resize the logo itself... Personally I wouldn't reccomend having the icon much larger as it would take over too much of the form. These settings can however be amended in the settings.json file. 

### Making the script an EXE
The script works when bundled into a .EXE file, I would reccomend [PS2EXE-GUI](https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-GUI-Convert-e7cb69d5). 

A few things to **NOTE** when creating the EXE. 
- It is not reccomended to select **Complie a graphic windows program (parameter -noConsole)**, The form will still load however you will see a lot of windows flashing up and closing before the application actually opens
- This can only be created using the **STA** Thread Apartment State 
- This application does not require admin right to run so you do not need to select **Require administrator rights at runtime**

