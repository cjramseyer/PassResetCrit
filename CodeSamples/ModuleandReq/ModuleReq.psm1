
###############################################################################
#
# ModuleReq.psm1
# Created:  10/11/2018 by cramse22: v1.0.0
# Modified:
#
# v1.0.0
#   - Created module for script
#
###############################################################################

<#
.Synopsis
    Module of required supportive functions
.Description
    Module of required supportive functions
#>

Set-PSDebug -Strict

$ModuleBase = $PSScriptRoot

Get-ChildItem $ModuleBase\functions *.ps1 | ForEach-Object{
    . $_.FullName
}
