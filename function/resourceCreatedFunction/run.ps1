# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

function Test-ResourceTypeSupportTags {    
    param(
        [Parameter(Mandatory=$true)]
        $resourceType
    )
    $resourceInfo = $resourceType.split("/",2)
    $provider = $resourceInfo[0]
    $serviceName = $resourceInfo[1]

    # This file is coming from https://github.com/tfitzmac/resource-capabilities/blob/master/tag-support.csv
    $tagSupportedResources = Import-Csv -Path .\resourceCreatedFunction\tag-support.csv
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

function Get-ResourceCreatorDisplayName {
    param(
        [Parameter(Mandatory=$true)]
        $queueItem
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

# Write out the queue message and insertion time to the information log.
Write-Host "Processing message"
$resourceUri = $QueueItem.data.resourceUri
$subscriptionId = $QueueItem.data.subscriptionId
$eventTime = $QueueItem.eventTime

Write-Host "resourceUri is $resourceUri"

$resource = Get-AzResource -ResourceId $resourceUri -ErrorAction SilentlyContinue
if (-not $resource) {
    Write-Host "Can't get resource with id $resourceUri"
    return
}
$resourceType = $resource.ResourceType

if (-not $resourceType) {
    Write-Host "No Resource Type"
    return
}

Write-Host "ResourceType is $resourceType"
if(-not (Test-ResourceTypeSupportTags -resourceType $resourceType)) {
    return
}

$displayName = Get-ResourceCreatorDisplayName -queueItem $QueueItem

$cloudTable = Get-AzTableTable -storageAccountName $env:storageName -resourceGroup $env:resourceGroupName -TableName $env:tableName 
$formatedResourceUri = ($resourceUri -replace "/","-").ToLower()
$row = Get-AzTableRow -Table $cloudTable -PartitionKey $formatedResourceUri -RowKey $subscriptionId
if (-not $row) {
    Write-Host "No creator found in referential - Add it"   
    Add-AzTableRow -Table $cloudTable -PartitionKey $formatedResourceUri -RowKey $subscriptionId -property @{"createdBy"=$displayName; "createdAt"=$eventTime} | Out-Null
} else {
    Write-Host "Creator found in referential : $($row.createdBy)"   
    $displayName = $row.createdBy
}



$resourceTags = $resource.Tags
if(-not $resourceTags) {
    $resourceTags = @{}
}
if ($resourceTags.ContainsKey("createdBy") -and $resourceTags["createdBy"] -eq $displayName) {
    Write-Host "Tag createdBy already set with the right creator"
    return
}
$resourceTags["createdBy"] = $displayName
Set-AzResource -ResourceId $resourceUri -Tag $resourceTags -Force | Out-Null
Write-Host "Tag createdBy appended"

