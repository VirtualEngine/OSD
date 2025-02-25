<#
.SYNOPSIS
Opens the ms-setting: URI that is specified in the Setting parameter

.DESCRIPTION
Opens the ms-setting: URI that is specified in the Setting parameter

.PARAMETER Settings
The Windows Setting URI

.PARAMETER DisableWSUS
Sets the Group Policy 'Download repair content and optional features directly from Windows Update instead of Windows Server Update Services (WSUS)'
Restarts the Windows Update Service
This setting will be enabled after restart by Group Policy

.LINK
https://osd.osdeploy.com

.LINK
https://4sysops.com/wiki/list-of-ms-settings-uri-commands-to-open-specific-settings-in-windows-10/history/?revision=1555539

.NOTES
#>
function Show-MsSettings {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateSet(
            'About',
            'AdvancedScaling',
            'DateTime',
            'DefaultApps',
            'Display',
            'Ethernet',
            'Graphics',
            'Language',
            'Network',
            'NetworkStatus',
            'Notifications',
            'OptionalFeatures',
            'PowerSleep',
            'Privacy',
            'Proxy',
            'Region',
            'Sound',
            'SoundDevices',
            'VPN',
            'WiFi',
            'WiFiAvailable',
            'WiFiNetworks',
            'WindowsUpdate'

        )]
        [string]$Setting,

        [switch]$DisableWSUS
    )
    #=================================================
    #	Block
    #=================================================
    Block-WinPE
    #=================================================
    #	Switch
    #=================================================
    switch ($Setting)
    {
        About               {$SettingURI = 'ms-settings:about'}
        AdvancedScaling     {$SettingURI = 'ms-settings:display-advanced'}
        DateTime            {$SettingURI = 'ms-settings:dateandtime'}
        DefaultApps         {$SettingURI = 'ms-settings:defaultapps'}
        Display             {$SettingURI = 'ms-settings:display'}
        Ethernet            {$SettingURI = 'ms-settings:network-ethernet'}
        Graphics            {$SettingURI = 'ms-settings:display-advancedgraphics'}
        Language            {$SettingURI = 'ms-settings:regionlanguage'}
        Network             {$SettingURI = 'ms-settings:network'}
        NetworkStatus       {$SettingURI = 'ms-settings:network-status'}
        Notifications       {$SettingURI = 'ms-settings:notifications'}
        OptionalFeatures    {$SettingURI = 'ms-settings:optionalfeatures'}
        PowerSleep          {$SettingURI = 'ms-settings:powersleep'}
        Privacy             {$SettingURI = 'ms-settings:privacy'}
        Proxy               {$SettingURI = 'ms-settings:network-proxy'}
        Region              {$SettingURI = 'ms-settings:regionformatting'}
        Sound               {$SettingURI = 'ms-settings:sound'}
        SoundDevices        {$SettingURI = 'ms-settings:sounddevices'}
        VPN                 {$SettingURI = 'ms-settings:network-vpn'}
        WiFi                {$SettingURI = 'ms-settings:network-wifi'}
        WiFiAvailable       {$SettingURI = 'ms-availablenetworks:'}
        WiFiNetworks        {$SettingURI = 'ms-settings:network-wifisettings'}
        WindowsUpdate       {$SettingURI = 'ms-settings:windowsupdate'}
        Default             {$SettingURI = 'ms-settings:'}
    }
    #=================================================
    #   UseWUServer
    #   Original code from Martin Bengtsson
    #   https://www.imab.dk/deploy-rsat-remote-server-administration-tools-for-windows-10-v2004-using-configmgr-and-powershell/
    #   https://github.com/imabdk/Powershell/blob/master/Install-RSATv1809v1903v1909v2004v20H2.ps1
    #=================================================
    if ($Setting -eq 'WindowsUpdate') {
        $WUServer = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name WUServer -ErrorAction Ignore).WUServer
        $UseWUServer = (Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction Ignore).UseWuServer

        if (($WUServer -ne $null) -and ($UseWUServer -eq 1) -and ($DisableWSUS -eq $false)) {
            Write-Warning "This computer is configured to receive updates from WSUS Server $WUServer"
            Write-Warning "Add the DisableWSUS parameter to update from Windows Update"
        }
        if (($DisableWSUS -eq $true) -and ($UseWUServer -eq 1)) {
            Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Value 0
            Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWuServer" -Value 0
            Restart-Service wuauserv
        }
    }
    #=================================================
    #	Execute
    #=================================================
    if ($Setting.IsPresent) {
        Write-Host -ForegroundColor Cyan $Setting
    }
    else {
        Write-Host -ForegroundColor Cyan 'Windows Settings'
    }
    Write-Host -ForegroundColor Cyan "Start-Process $SettingURI"
    Start-Process $SettingURI
    #=================================================
}
<#
.SYNOPSIS
Opens Windows Update and checks for WSUS configuration

.DESCRIPTION
Opens Windows Update and checks for WSUS configuration

.PARAMETER DisableWSUS
Sets the Group Policy 'Download repair content and optional features directly from Windows Update instead of Windows Server Update Services (WSUS)'
Restarts the Windows Update Service
This setting will be enabled after restart by Group Policy

.PARAMETER EnableDrivers
Allows Driver Updates in Windows Update

.LINK
https://osd.osdeploy.com


.NOTES
#>
function Unblock-WindowsUpdate {
    [CmdletBinding()]
    param (
        [switch]$DisableWSUS,
        [switch]$EnableDrivers
    )
    #=================================================
    #	Block
    #=================================================
    Block-WinPE
    #=================================================
    #   UseWUServer
    #   Original code from Martin Bengtsson
    #   https://www.imab.dk/deploy-rsat-remote-server-administration-tools-for-windows-10-v2004-using-configmgr-and-powershell/
    #   https://github.com/imabdk/Powershell/blob/master/Install-RSATv1809v1903v1909v2004v20H2.ps1
    #=================================================
    $WUServer = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name WUServer -ErrorAction Ignore).WUServer
    $UseWUServer = (Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction Ignore).UseWuServer
    $WUDrivers = (Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction Ignore).ExcludeWUDriversInQualityUpdate

    if (($WUServer -ne $null) -and ($UseWUServer -eq 1) -and ($DisableWSUS -eq $false)) {
        Write-Warning "This computer is configured to receive updates from WSUS Server $WUServer"
        Write-Warning "Add the DisableWSUS parameter to update from Windows Update"
    }

    if (($WUDrivers -eq 1) -and ($EnableDrivers -eq $false)) {
        Write-Warning "This computer is not configured to receive Driver updates from Windows Update"
        Write-Warning "Add the EnableDrivers parameter to enable Driver updates from Windows Update"
    }
    #=================================================
    #	Execute
    #=================================================
    if (($DisableWSUS -eq $true) -and ($UseWUServer -eq 1)) {
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWuServer" -Value 0
    }

    if (($EnableDrivers -eq $true) -and ($WUDrivers -eq 1)) {
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Value 0
    }

    if (($DisableWSUS -eq $true) -or ($EnableDrivers -eq $true)) {
        Restart-Service wuauserv
    }

    Write-Host -ForegroundColor Cyan "Start-Process ms-settings:windowsupdate"
    Start-Process ms-settings:windowsupdate
    #=================================================
}