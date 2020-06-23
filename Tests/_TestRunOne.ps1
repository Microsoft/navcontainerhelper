﻿Param(
    [string] $licenseFile = "C:\Users\freddyk\Dropbox\Shared\nchbuildlicense.flf"
)

. (Join-Path $PSScriptRoot '_TestHelperFunctions.ps1')

$modulePath = Join-Path $PSScriptRoot "..\NavContainerHelper.psm1"
Remove-Module NavContainerHelper -ErrorAction Ignore
Import-Module $modulePath -DisableNameChecking

$credential = [PSCredential]::new("admin", (ConvertTo-SecureString -AsPlainText -String "P@ssword1" -Force))

. (Join-Path $PSScriptRoot '_CreateNavContainer.ps1')
. (Join-Path $PSScriptRoot '_CreateBcContainer.ps1')

. (Join-Path $PSScriptRoot "AppHandling.ps1")
