function Test-ResourceTypeSupportTags {    
    param(
        [Parameter(Mandatory=$true)]
        [string]$resourceType,
        [Parameter(Mandatory=$true)]
        [string]$referentialFilePath
    )
    $resourceInfo = $resourceType.split("/",2)
    $provider = $resourceInfo[0]
    $serviceName = $resourceInfo[1]

    # This file is coming from https://github.com/tfitzmac/resource-capabilities/blob/master/tag-support.csv
    $tagSupportedResources = Import-Csv -Path $referentialFilePath
    $currentResourceSupport = $tagSupportedResources | Where-Object {($_.providerName -eq $provider) -and ($_.resourceType -eq $serviceName)} | Select-Object -first 1

    if (-not ($currentResourceSupport)) {
        Write-Host "$resourceType not found in tag support referential"
        return $false
    }

    if ($currentResourceSupport.supportsTags -eq "FALSE") {
        Write-Host "$resourceType does not support tags"
        return $false
    }

    Write-Host "$resourceType does support tags"
    $true
}

function Get-EventInitiatorDisplayName {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$queueItem
    )

    if ($queueItem.data.authorization.evidence.principalType -eq "ServicePrincipal") {
        #Created by a service principal
        Write-Host "Created by a service principal"
        $applicationId = $queueItem.data.claims.appid        
        $displayName = "Service Principal $applicationId"
    }
    else {
        #Created by a user
        Write-Host "Created by a user"
        $displayName = $QueueItem.data.claims.name
    }

    Write-Host "Resource was created by $displayName"
    $displayName
}

function Update-referential{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$resourceUri,
        [Parameter(Mandatory=$true)]
        [string]$subscriptionId,
        [Parameter(Mandatory=$true)]
        [string]$creatorDisplayName,
        [Parameter(Mandatory=$true)]
        [string]$eventTime
    )
    $cloudTable = Get-AzTableTable -storageAccountName $env:storageName -resourceGroup $env:resourceGroupName -TableName $env:tableName 
    $formatedResourceUri = ($resourceUri -replace "/","-").ToLower()
    $row = Get-AzTableRow -Table $cloudTable -PartitionKey $formatedResourceUri -RowKey $subscriptionId
    if (-not $row) {
        Write-Host "No creator found in referential - Add it"   
        Add-AzTableRow -Table $cloudTable -PartitionKey $formatedResourceUri -RowKey $subscriptionId -property @{"createdBy"=$creatorDisplayName; "createdAt"=$eventTime} | Out-Null
        $displayName = $creatorDisplayName
    } else {
        Write-Host "Creator found in referential : $($row.createdBy)"   
        $displayName = $row.createdBy
    }
    $displayName
}

function Set-ResourceCreatedByTag {
    param(
        [Parameter(Mandatory=$false)]
        [Hashtable]$resourceTags,
        [Parameter(Mandatory=$true)]
        [string]$resourceUri,
        [Parameter(Mandatory=$true)]
        [string]$creatorDisplayName
    )

    if(-not $resourceTags) {
        $resourceTags = @{}
    }
    if ($resourceTags.ContainsKey("createdBy") -and $resourceTags["createdBy"] -eq $creatorDisplayName) {
        Write-Host "Tag createdBy already set with the right creator"
        return
    }
    $resourceTags["createdBy"] = $creatorDisplayName
    Set-AzResource -ResourceId $resourceUri -Tag $resourceTags -Force | Out-Null
    Write-Host "Tag createdBy appended"

}

Export-ModuleMember -Function Test-ResourceTypeSupportTags
Export-ModuleMember -Function Get-EventInitiatorDisplayName
Export-ModuleMember -Function Update-referential
Export-ModuleMember -Function Set-ResourceCreatedByTag