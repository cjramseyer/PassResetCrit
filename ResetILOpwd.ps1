###########################################################################
#ResetILOpwd.ps1
# Created: 02/27/2019 by <mjah1>
# Modified: 01/22/2020 by <mjah1t> #When modified after first version
#
# Version <CurrentVersion 1.0.1>:
#    Itemized list of changes for the latest version
#
###########################################################################

<#
.Synopsis
    Reset ILO password on hp servers.
.Description
       

    .Example
    .\ResetILOpwd.ps1 ./serverlist.txt
    
#>

#region Variables
#Define main variables here
#endregion Variables

$serverlist = get-content .\serverlist.txt
$pwdresetinfo = get-item .\reset_pwd.xml
$port2012 = 9507
$port2016 = 5985

Foreach($server in $serverlist){

    #Set-Content -Path “C:\eigtools\reset_pwd.xml” -Value $using:pwdresetinfo
    $path = "\\"+$server+"\c`$\eigtools"
    
    Copy-Item $pwdresetinfo -Destination $path 

    if ([int]((((Get-WmiObject -class Win32_OperatingSystem -computer $server).version).split("."))[0]) -gt 9)
    {$port = $port2016}
    else
    {$port = $port2012}

    Invoke-Command -ComputerName $server -port $port -ScriptBlock {

        if (Test-Path -Path "c:\Program Files\hp\hponcfg\hponcfg.exe”) {

            Write-Host “Resetting iLO password for $server”

            & “C:\Program Files\hp\hponcfg\hponcfg.exe” /f “C:\eigtools\reset_pwd.xml”

        }
        else
        {

        Write-Host “Resetting iLO password for $server”

        & “C:\Program Files\hewlett Packard enterprise\hponcfg\hponcfg.exe” /f “C:\eigtools\reset_pwd.xml”

        }
      
	  Remove-Item “C:\eigtools\reset_pwd.xml” -Force
    }
Start-Sleep -Seconds 5

}