Describe "Created resources supporting Tag are tagged with their creator" -Tag @("acceptance_test") {

    BeforeAll { 
        $resourceGroupName = "tag-test-rg"
        $location = "NorthEurope"
        $publicIPName = "testpublicip01"
        $servicePrincipalId = "ee6e2b3b-3af5-4c2d-a0db-84f1b688c552"
        $maxRetry = 20
        $delay = 10
        Write-Host "Creating test Resource Group $resourceGroupName"
        New-AzResourceGroup -Name $resourceGroupName -Location $location | Out-Null        
    }
     
    AfterAll { 
        Write-Host "Removing test Resource Group $resourceGroupName"
        Remove-AzResourceGroup -Name "tag-test-rg" -Force | Out-Null
    }

    Function Get-ResourceCreatedByTag {
        param(
            [Parameter(Mandatory=$true)]
            [int]$maxRetry,
            [Parameter(Mandatory=$true)]
            [int]$delay,
            [Parameter(Mandatory=$true)]
            [string]$resourceName,
            [Parameter(Mandatory=$true)]
            [string]$resourceGroupName
        )

        $currentTry = 0
        $tagAdded = $false
        $tagValue = $null
        while ($currentTry -le $maxRetry -and -not $tagAdded) {
            $resource = Get-AzResource -Name $resourceName -ResourceGroupName $resourceGroupName
            if($resource.Tags -and $resource.Tags.ContainsKey("createdBy")) {
                Write-Host "Tag created"
                $tagAdded = $true
                $tagValue = $resource.Tags["createdBy"]
            } 
            else {
                Write-Host "Tag createdBy not present after $($currentTry * $delay) seconds"
                $currentTry++
                Start-Sleep -Seconds $delay
            }                      
        }                          
        $tagAdded 
        $tagValue 
    }

    Context "A new Public IP is created" {       

        It "The Public IP is tagged with its creator" {                
            New-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic
            $tagCheck = Get-ResourceCreatedByTag -maxRetry $maxRetry -delay $delay -resourceName $publicIpName -resourceGroupName $resourceGroupName
            $tagCheck[0] | Should -Be $true
            $tagCheck[1] | Should -Be "Service Principal $servicePrincipalId"                    
        }

        It "The tag is added if it is removed" {                                  
            $publicIp = Get-AzResource -Name $publicIpName -ResourceGroupName $resourceGroupName
            Set-AzResource -ResourceId $publicIp.ResourceId -Tag @{}
            $tagCheck = Get-ResourceCreatedByTag -maxRetry $maxRetry -delay $delay -resourceName $publicIpName -resourceGroupName $resourceGroupName
            $tagCheck[0] | Should -Be $true
            $tagCheck[1] | Should -Be "Service Principal $servicePrincipalId"   
        }        
    }    
}