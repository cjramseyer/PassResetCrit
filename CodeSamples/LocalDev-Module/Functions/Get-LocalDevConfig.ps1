<#
.Synopsis
    Quick note about Localdev environment
.DESCRIPTION
   Quick note about Localdev environment
.EXAMPLE
   Get-LocalDevConfig -verbose
.EXAMPLE
   Get-LocalDevConfig -source
#>
Function Get-LocalDevConfig {
  [cmdletbinding()]
  param(
    $PROFILEDIR = "$($env:USERPROFILE)\documents\WindowsPowerShell" ,
    [switch]$Source
  )

  $ErrorActionPreference = "Stop"
  Set-StrictMode -Version 1.0 #Option explicit

  if ($Source) {
    $config_path = $(join-path $PSScriptRoot "../files/config.json")
  }
  else {
    $config_path = $(join-path $PROFILEDIR config.json)
  }

  if (-not(test-path $config_path)) {
    write-error "Can't find $config_path!" -ErrorAction Stop
  }
  
  $config = get-content -raw $config_path|ConvertFrom-Json
  Write-Output $Config  
}
