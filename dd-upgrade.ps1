[CmdletBinding()]
Param(
    [string]   $APIKey=(Get-SSMParameter -Name daik-nonprod-datadog-apikey).Value,

    [ValidateScript ( { Test-Path $_ } ) ]
    [string]   $Location = "C:\Windows\Temp",
    [string]   $Hostname = $env:COMPUTERNAME,
    [string[]] $Tags
)
begin{
    $MSI = "$location\ddog.msi"
    If ( Test-path $MSI ) {
        Remove-Item $MSI -Force
    }
}
process{

Write-Output "Getting versions JSON"
$InstallerJsonUrl ="https://s3.amazonaws.com/ddagent-windows-stable/installers.json"
$Req = Invoke-WebRequest -Uri $InstallerJsonUrl -UseBasicParsing

Write-Output "Calculating latest version"
$VersionsObject = $Req.Content | ConvertFrom-Json
$VersionStrings = $VersionsObject| Get-Member -MemberType NoteProperty | Select Name

$Versions = @()
ForEach ($Version in $VersionStrings){
    $Versions += [version] $Version.Name
}

$LatestVersion = $Versions | Sort-Object -Descending | Select -First 1
Write-Output "Collecting Datadog Version $($LatestVersion.ToString())"
$TargetMSI = $VersionsObject.$($LatestVersion.toString()).amd64

Invoke-WebRequest -Uri $TargetMSI -OutFile $MSI

If ( $Tags ){
    $Expression = "msiexec /qn /i `"$MSI`" APIKEY=`"$APIKEY`" HOSTNAME=`"$HOSTNAME`" TAGS=`"$($TAGS -join ",")`""
}
Else{
    $Expression = "msiexec /qn /i `"$MSI`" APIKEY=`"$APIKEY`" HOSTNAME=`"$HOSTNAME`""
}
Write-Output "Commencing Installation"
Write-Verbose "Installation Command: $Expression"
Invoke-Expression $Expression

}
