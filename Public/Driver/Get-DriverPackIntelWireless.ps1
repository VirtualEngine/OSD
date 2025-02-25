<#
.SYNOPSIS
Returns a Intel Wireless Driver Object

.DESCRIPTION
Returns a Intel Wireless Driver Object

.LINK
https://osddrivers.osdeploy.com
#>
function Get-DriverPackIntelWireless {
    [CmdletBinding()]
    param (
        [ValidateSet('x64','x86')]
        [string]$CompatArch,
        [ValidateSet('Win7','Win10')]
        [string]$CompatOS
    )
    #=================================================
    #   Uri
    #=================================================
    $Uri = 'https://www.intel.com/content/www/us/en/support/articles/000017246/network-and-i-o/wireless-networking.html'
    #=================================================
    #   Import Base Catalog
    #=================================================
    $BaseCatalog = Get-Content -Path "$($MyInvocation.MyCommand.Module.ModuleBase)\Catalogs\DriverPacks\DriverPackIntelWireless.json" -Raw | ConvertFrom-Json
    #=================================================
    #   Online
    #=================================================
    if (Test-WebConnection $Uri) {
        Write-Verbose "Catalog is Online"
        #All Drivers are from the same URL
        $BaseCatalog = $BaseCatalog | Select-Object -First 1
        #=================================================
        #   ForEach
        #=================================================
        $ZipFileResults = @()
        $DriverResults = @()
        $DriverResults = foreach ($BaseCatalogItem in $BaseCatalog) {
            #Write-Verbose "$($BaseCatalogItem.DriverGrouping) $($BaseCatalogItem.OsArch)" -Verbose
            #Write-Verbose "     $($BaseCatalogItem.DriverInfo)" -Verbose
            #=================================================
            #   WebRequest
            #=================================================
            $DriverInfoWebRequest = Invoke-WebRequest -Uri $BaseCatalogItem.DriverInfo -Method Get
            $DriverInfoWebRequestContent = $DriverInfoWebRequest.Content

            $DriverInfoHTML = $DriverInfoWebRequest.ParsedHtml.childNodes | Where-Object {$_.nodename -eq 'HTML'} 
            $DriverInfoHEAD = $DriverInfoHTML.childNodes | Where-Object {$_.nodename -eq 'HEAD'}
            $DriverInfoMETA = $DriverInfoHEAD.childNodes | Where-Object {$_.nodename -like "meta*"} | Select-Object -Property Name, Content
            $OSCompatibility = $DriverInfoMETA | Where-Object {$_.name -eq 'DownloadOSes'} | Select-Object -ExpandProperty Content
            Write-Verbose "     $OSCompatibility"
            #=================================================
            #   Driver Filter
            #=================================================
            $ZipFileResults = @($DriverInfoWebRequestContent -split " " -split '"' -match 'http' -match "downloadmirror" -match ".zip")

            $ZipFileResults = $ZipFileResults | Where-Object {$_ -match 'Driver'}

            if ($BaseCatalogItem.OsArch -match 'x64') {
                $ZipFileResults = $ZipFileResults | Where-Object {$_ -notmatch 'win32'}
            }
            if ($BaseCatalogItem.OsArch -match 'x86') {
                $ZipFileResults = $ZipFileResults | Where-Object {$_ -notmatch 'win64'}
            }
            $ZipFileResults = $ZipFileResults | Select-Object -Unique
            #=================================================
            #   Driver Details
            #=================================================
            foreach ($DriverZipFile in $ZipFileResults) {
                Write-Verbose "     $DriverZipFile"
                #=================================================
                #   Defaults
                #=================================================
                $OSDVersion = $(Get-Module -Name OSD | Sort-Object Version | Select-Object Version -Last 1).Version
                $LastUpdate = [datetime] $(Get-Date)
                $OSDStatus = $null
                $OSDGroup = 'IntelWireless'
                $OSDType = 'Driver'

                $DriverName = $null
                $DriverVersion = $null
                $DriverReleaseId = $null
                $DriverGrouping = $null

                if ($DriverZipFile -match 'Win7') {$OsVersion = '6.0'}
                if ($DriverZipFile -match 'Win8') {$OsVersion = '6.3';Continue}
                if ($DriverZipFile -match 'Win10') {$OsVersion = '10.0'}
                if ($DriverZipFile -match 'Driver32') {$OsArch = 'x86'}
                if ($DriverZipFile -match 'Driver64') {$OsArch = 'x64'}
                $OsBuildMax = @()
                $OsBuildMin = @()
        
                $Make = @()
                $MakeNe = @()
                $MakeLike = @()
                $MakeNotLike = @()
                $MakeMatch = @()
                $MakeNotMatch = @()
        
                $Generation = $null
                $SystemFamily = $null
        
                $Model = @()
                $ModelNe = @()
                $ModelLike = @()
                $ModelNotLike = @()
                $ModelMatch = @()
                $ModelNotMatch = @()
        
                $SystemSku = @()
                $SystemSkuNe = @()
        
                $DriverBundle = $null
                $DriverWeight = 100
        
                $DownloadFile = $null
                $SizeMB = $null
                $DriverUrl = $null
                $DriverInfo = $BaseCatalogItem.DriverInfo
                $DriverDescription = $null
                $Hash = $null
                $OSDGuid = $(New-Guid)
                #=================================================
                #   LastUpdate
                #=================================================
                #$LastUpdateRaw = $DriverInfoMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                #$LastUpdate = [datetime]::ParseExact($LastUpdateRaw, "MM/dd/yyyy HH:mm:ss", $null)

                $LastUpdateRaw = $DriverInfoMETA | Where-Object {$_.name -eq 'LastUpdate'} | Select-Object -ExpandProperty Content
                Write-Verbose "LastUpdateRaw: $LastUpdateRaw"

                $LastUpdateSplit = ($LastUpdateRaw -split (' '))[0]
                Write-Verbose "LastUpdateSplit: $LastUpdateSplit"

                $LastUpdate = [datetime]::Parse($LastUpdateSplit)
                Write-Verbose "LastUpdate: $LastUpdate"
                #=================================================
                #   DriverVersion
                #=================================================
                $DriverVersion = ($DriverZipFile -split ('-'))[1]
                #=================================================
                #   DriverUrl
                #=================================================
                $DriverUrl = $DriverZipFile
                #=================================================
                #   Values
                #=================================================
                $DriverGrouping = $BaseCatalogItem.DriverGrouping
                $DriverName = "$DriverGrouping $OsArch $DriverVersion $OsVersion"
                $DriverDescription = $DriverInfoMETA | Where-Object {$_.name -eq 'Description'} | Select-Object -ExpandProperty Content
                $DownloadFile = Split-Path $DriverUrl -Leaf
                $OSDPnpClass = 'Net'
                $OSDPnpClassGuid = '{4D36E972-E325-11CE-BFC1-08002BE10318}'
                #=================================================
                #   Create Object
                #=================================================
                $ObjectProperties = @{
                    OSDVersion              = [string] $OSDVersion
                    LastUpdate              = [datetime] $LastUpdate
                    OSDStatus               = [string] $OSDStatus
                    OSDType                 = [string] $OSDType
                    OSDGroup                = [string] $OSDGroup
        
                    DriverName              = [string] $DriverName
                    DriverVersion           = [string] $DriverVersion
                    DriverReleaseId         = [string] $DriverReleaseID
        
                    OperatingSystem         = [string[]] $OperatingSystem
                    OsVersion               = [string[]] $OsVersion
                    OsArch                  = [string[]] $OsArch
                    OsBuildMax              = [string] $OsBuildMax
                    OsBuildMin              = [string] $OsBuildMin
        
                    Make                    = [string[]] $Make
                    MakeNe                  = [string[]] $MakeNe
                    MakeLike                = [string[]] $MakeLike
                    MakeNotLike             = [string[]] $MakeNotLike
                    MakeMatch               = [string[]] $MakeMatch
                    MakeNotMatch            = [string[]] $MakeNotMatch
        
                    Generation              = [string] $Generation
                    SystemFamily            = [string] $SystemFamily
        
                    Model                   = [string[]] $Model
                    ModelNe                 = [string[]] $ModelNe
                    ModelLike               = [string[]] $ModelLike
                    ModelNotLike            = [string[]] $ModelNotLike
                    ModelMatch              = [string[]] $ModelMatch
                    ModelNotMatch           = [string[]] $ModelNotMatch
        
                    SystemSku               = [string[]] $SystemSku
                    SystemSkuNe             = [string[]] $SystemSkuNe
        
                    SystemFamilyMatch       = [string[]] $SystemFamilyMatch
                    SystemFamilyNotMatch    = [string[]] $SystemFamilyNotMatch
        
                    SystemSkuMatch          = [string[]] $SystemSkuMatch
                    SystemSkuNotMatch       = [string[]] $SystemSkuNotMatch
        
                    DriverGrouping          = [string] $DriverGrouping
                    DriverBundle            = [string] $DriverBundle
                    DriverWeight            = [int] $DriverWeight
        
                    DownloadFile            = [string] $DownloadFile
                    SizeMB                  = [int] $SizeMB
                    DriverUrl               = [string] $DriverUrl
                    DriverInfo              = [string] $DriverInfo
                    DriverDescription       = [string] $DriverDescription
                    Hash                    = [string] $Hash
                    OSDGuid                 = [string] $OSDGuid
        
                    OSDPnpClass             = [string] $OSDPnpClass
                    OSDPnpClassGuid         = [string] $OSDPnpClassGuid
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
        }
    }
    #=================================================
    #   Offline
    #=================================================
    else {
        Write-Verbose "Catalog is Offline"
        $DriverResults = $BaseCatalog
    }
    #=================================================
    #   Remove Duplicates
    #=================================================
    $DriverResults = $DriverResults | Sort-Object DriverUrl -Unique
    #=================================================
    #   Select-Object
    #=================================================
    $DriverResults = $DriverResults | Select-Object OSDVersion, LastUpdate, OSDStatus, OSDType, OSDGroup,`
    DriverName, DriverVersion,`
    OsVersion, OsArch,`
    DriverGrouping,`
    DownloadFile, DriverUrl, DriverInfo, DriverDescription,`
    OSDGuid,`
    OSDPnpClass, OSDPnpClassGuid
    #=================================================
    #   Sort-Object
    #=================================================
    $DriverResults = $DriverResults | Sort-Object -Property LastUpdate -Descending
    $DriverResults | ConvertTo-Json | Out-File "$env:TEMP\DriverPackIntelWireless.json"
    #=================================================
    #   Filter
    #=================================================
    switch ($CompatArch) {
        'x64'   {$DriverResults = $DriverResults | Where-Object {$_.OSArch -match 'x64'}}
        'x86'   {$DriverResults = $DriverResults | Where-Object {$_.OSArch -match 'x86'}}
    }
    switch ($CompatOS) {
        'Win7'   {$DriverResults = $DriverResults | Where-Object {$_.OsVersion -match '6.0'}}
        'Win8'   {$DriverResults = $DriverResults | Where-Object {$_.OsVersion -match '6.3'}}
        'Win10'   {$DriverResults = $DriverResults | Where-Object {$_.OsVersion -match '10.0'}}
    }
    #=================================================
    #   Return
    #=================================================
    Return $DriverResults
    #=================================================
}