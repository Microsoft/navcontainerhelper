﻿<# 
 .Synopsis
  Creates a new Tenant in a multitenant Nav container
 .Description
  Creates a tenant database in the Nav container and mounts it as a new tenant
 .Parameter containerName
  Name of the container in which you want to install the app (default navserver)
 .Parameter tenantId
  Name of tenant you want to create in the container
 .Example
  New-NavContainerTenant -containerName test2 -tenantId mytenant
#>
function New-NavContainerTenant {
    Param
    (
        [Parameter(Mandatory=$false)]
        [string]$containerName = "navserver",
        [Parameter(Mandatory=$true)]
        [string]$tenantId,
        [System.Management.Automation.PSCredential]$sqlCredential = $null
    )

    Write-Host "Creating Tenant $tenantId on $containerName"

    $sqlCredential = Get-DefaultSqlCredential -containerName $containerName -sqlCredential $sqlCredential

    if ($tenantId -eq "tenant") {
        throw "You cannot add a tenant called tenant"
    }

    $session = Get-NavContainerSession -containerName $containerName -silent
    Invoke-Command -Session $session -ScriptBlock { Param($tenantId, $sqlCredential)

        $customConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
        [xml]$customConfig = [System.IO.File]::ReadAllText($customConfigFile)
        if ($customConfig.SelectSingleNode("//appSettings/add[@key='Multitenant']").Value -ne "true") {
            throw "The NAV Container is not setup for multitenancy"
        }
        $databaseServer = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseServer']").Value
        $databaseInstance = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseInstance']").Value

        # Setup tenant
        Copy-NavDatabase -SourceDatabaseName "tenant" -DestinationDatabaseName $TenantId -DatabaseServer $databaseServer -DatabaseInstance $databaseInstance -DatabaseCredentials $sqlCredential
        Mount-NavDatabase -TenantId $TenantId -DatabaseName $TenantId -DatabaseServer $databaseServer -DatabaseInstance $databaseInstance -DatabaseCredentials $sqlCredential

    } -ArgumentList $tenantId, $sqlCredential
    Write-Host -ForegroundColor Green "Tenant successfully created"
}
Export-ModuleMember -Function New-NavContainerTenant
