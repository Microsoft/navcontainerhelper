﻿<# 
 .Synopsis
  Sort an array of app folders
 .Description
  Sort an array of app folders with dependencies first, for compile and publish order
 .Parameter appFolders
  Array of folders including an app.json
 .Parameter baseFolder
  If specified, all appFolders in the array are subFolders to this folder.
 .Parameter unknownDependencies
  If specified, this reference parameter will contain unresolved dependencies after sorting
 .Example
  $folders = Sort-AppFoldersByDependencies -appFolders @($folder1, $folder2)
#>
function Sort-AppFoldersByDependencies {
    Param(
        [Parameter(Mandatory=$true)]
        [string[]] $appFolders,
        [Parameter(Mandatory=$false)]
        [string] $baseFolder = "",
        [Parameter(Mandatory=$false)]
        [ref] $unknownDependencies
    )

    if ($baseFolder) {
        $baseFolder = $baseFolder.TrimEnd('\')+'\'
    }

    # Read all app.json objects, populate $apps
    $apps = $()
    $folders = @{}
    $appFolders | ForEach-Object {
        $appFolder = "$baseFolder$_"
        $appJsonFile = Join-Path $appFolder "app.json"
        if (-not (Test-Path -Path $appJsonFile)) {
            Write-Warning "$appFolder doesn't contain app.json"
        }
        else {
            $appJson = Get-Content -Path $appJsonFile | ConvertFrom-Json
            $folders += @{ "$($appJson.Id)" = $appFolder }
            $apps += @($appJson)
        }
    }
    
    # Populate SortedApps and UnresolvedDependencies
    $script:sortedApps = @()
    $script:unresolvedDependencies = $()

    function AddAnApp { Param($anApp) 
        $alreadyAdded = $script:sortedApps | Where-Object { $_.Id -eq $anApp.Id }
        if (-not ($alreadyAdded)) {
            AddDependencies -anApp $anApp
            $script:sortedApps += $anApp
        }
    }
    
    function AddDependency { Param($dependency)
        $dependentApp = $apps | Where-Object { $_.Id -eq $dependency.Id }
        if ($dependentApp) {
            AddAnApp -AnApp $dependentApp
        }
        else {
            if (-not ($script:unresolvedDependencies | Where-Object { $_ -and $_.Id -eq $dependency.Id })) {
                Write-Warning "Dependency $($dependency.Id):$($dependency.publisher.Replace('/',''))_$($dependency.name.Replace('/',''))_$($dependency.version)).app not found"
                $script:unresolvedDependencies += @($dependency)
            }
        }
    }
    
    function AddDependencies { Param($anApp)
        if (($anApp) -and ($anApp.Dependencies)) {
            $anApp.Dependencies | ForEach-Object { AddDependency -Dependency $_ }
        }
    }
    
    $apps | ForEach-Object { AddAnApp -AnApp $_ }

    $script:sortedApps | ForEach-Object {
        ($folders[$_.id]).SubString($baseFolder.Length)
    }
    if ($unknownDependencies) {
        $unknownDependencies.value = @($script:unresolvedDependencies | ForEach-Object { if ($_) { "$($_.Id):$($_.publisher.Replace('/',''))_$($_.name.Replace('/',''))_$($_.version).app" } })
    }
}
Export-ModuleMember -Function Sort-AppFoldersByDependencies
