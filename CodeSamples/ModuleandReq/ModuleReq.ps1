
###########################################################################
#
# <scriptname>.ps1
# Created: 10/11/2018 by cramse22
# Modified: 
#
# v1.0.0:
#   - Created initial script
#
###########################################################################

<#
.Synopsis
    Script to demonstrate requiring powershell, and other components
.Description
    Script to demonstrate requiring powershell, and other components
.Parameter ComputerName
    Optional Parameter to specify a computername
.Example
    ModuleReq.ps1
.NOTES
    This file and the other files in this directory are to demonstrate how to structure scripts and functions and modules.
    This also shows how to define required powershell versions, other modules, .NET Framework versions 
    to define the environment that a script must be executed in
#>

#Requires -Version 4.0

[CmdletBinding()]
param
(
    [parameter(Mandatory=$false)][string]$ComputerName
)

Set-PSDebug -Strict

#region Variables
    #Define Main Variables here.  Included are standard suggested variables
    $CurDir = split-path -parent $MyInvocation.MyCommand.Definition
    $InstappsPath = "C:\INSTAPPS"
    $PathtoLogFile = "$InstappsPath\ScriptLog.log"
    $PathtoConfigFile = "$CurDir\ConfigFile.ini"
    $ModulesToRemove = @()
    if(Test-Path "$CurDir\ModuleReq.psd1"){$ModulesToRemove += Import-Module "$CurDir\ModuleReq.psd1" -PassThru -Force}else{Write-Output "Could not load module (ModuleReq);exiting";exit}
#endregion Variables

#region Functions
    #Define script internal functions here
#endregion Functions

Start-Transcript -Path "$PathtoLogFile" -Append -Force
Invoke-Expression $(Get-Content $PathtoConfigFile | Out-String)

if(!(Test-Path "$ReportLoc"))
{
    mkdir $ReportLoc
}

$Result = "The script and the files in this directory demonstrate setting up the basic framework for a script, config file, module, and requiring certain versions"
$Result | Out-File -FilePath "$CurDir\Results.txt" -Append -Force

$ModulesToRemove | Remove-Module
Stop-Transcript
