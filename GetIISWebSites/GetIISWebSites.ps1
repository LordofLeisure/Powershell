Import-Module PSRemoteRegistry
Import-Module Webadministration

$Servers = Get-Content D:\Servers.txt

Function getIISversion 
{param ([string]$RemoteComputer)
try{
$IISversion = Get-RegValue -ComputerName $RemoteComputer -Hive LocalMachine -Key SOFTWARE\Microsoft\InetStp -Value VersionString | Select-Object Data
Return $IISversion.data}
catch
    {
    }
}

Function Windows2008
{param ([string]$RemoteComputer)
$websites = invoke-command -ComputerName $RemoteComputer -ScriptBlock {Import-Module Webadministration; Get-ChildItem -Path IIS:\Sites | select-object name, @{n="Bindings"; e= { ($_.bindings | select -expa collection) -join ';' }}}
Return $websites
}

Function Windows2003
{param ([string]$RemoteComputer)
#ADSI
#$iis = [ADSI]"IIS://localhost/W3SVC" 
#$iis.psbase.children | where { $_.schemaClassName -eq "IIsWebServer"} | select ServerComment

#WMI
Get-WmiObject -ComputerName $RemoteComputer -Class IIsWebServerSetting -Namespace "root\microsoftiisv2" | Select ServerComment, @{L="Bindings";E={[string]::join(';',($_.ServerBindings | select -expand hostname))}}
}

foreach ($server in $Servers)
{$IISversion = getIISversion $server

If ($IISversion -eq "Version 6.0")
    {Write-Host "IIS version returned for $server is $IISversion"
     $IIS6Info = Windows2003 $server | select-object –property ServerComment,Bindings
    foreach ($site in $IIS6Info)
     {New-Object -TypeName PSCustomObject -Property @{WebSiteName = $site.ServerComment
     Bindings = $site.bindings 
     IIS = $IISversion
     ServerName = $Server} | export-csv -NoTypeInformation D:\IIS.csv -append}}
ElseIf ($IISversion -eq "Version 7.0")
     {Write-Host "IIS version returned for $server is $IISversion"
     $IIS7Info = Windows2008 $server
     foreach ($site in $IIS7Info)
     {New-Object -TypeName PSCustomObject -Property @{WebSiteName = $site.Name 
     Bindings = $site.bindings
     IIS = $IISversion 
     ServerName = $Server} | export-csv -NoTypeInformation D:\IIS.csv -append}
    }
ElseIf ($IISversion -eq "Version 7.5")
     {Write-Host "IIS version returned for $server is $IISversion"
     $IIS7Info = Windows2008 $server
     foreach ($site in $IIS7Info)
     {New-Object -TypeName PSCustomObject -Property @{WebSiteName = $site.Name 
     Bindings = $site.bindings
     IIS = $IISversion 
     ServerName = $Server} | export-csv -NoTypeInformation D:\IIS.csv -append}
    }
Else {Write-Host "IIS Not present or could not connect to $server, skipping..."}
    
}