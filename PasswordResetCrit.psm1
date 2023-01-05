
###############################################################################
#
# PasswordResetCrit.psm1
# Created:  10/10/2021 by cramse22: v1.0.0
# Modified:
#
# v1.0.0
#   - Created base module for PasswordResetCrit
#
###############################################################################

<#
.Synopsis
    Module of critical password reset functions
.Description
    Module of critical password reset functions
#>

Set-PSDebug -Strict

$ModuleBase = $PSScriptRoot

Get-ChildItem $ModuleBase\functions *.ps1 | ForEach-Object{
    . $_.FullName
}
