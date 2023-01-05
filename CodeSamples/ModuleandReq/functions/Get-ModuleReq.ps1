
###########################################################################
#
# Get-moduleReq.ps1
# Created: 10/11/2018 by cramse22
# Modified: 
#
# v1.0.0:
#   - First cmdlet for module
#
###########################################################################

<#
.Synopsis
    Brief synopsis of function of script
.Description
    Description of function/usage of script
.Parameter <ParameterName>
    Description of parameter, it's function and usage
    Repeat for each parameter
.Example
    Usage examples
    Repeat for different type of usage of script
.OUTPUTS
    List the information (including logs) that is output by the script
.NOTES
    General notes related to the usage of the script and needed information such as what to expect, etc.
#>

#Requires -Version 4.0

Function Get-ModuleReq
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true)][string]$ComputerName
    )

    Set-PSDebug -Strict

    Write-Output "This is a module for to show module requirements"
}
