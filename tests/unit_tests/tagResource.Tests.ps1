Describe "Tag resource module tests" -Tag @("tagResourceModule","unit_test") {

    BeforeAll {
        Import-Module .\function\Modules\tagResource -Force   
        Set-Location .\function 
    }
    
    AfterAll {
        Set-Location ..
    }
    

    Context "Checking the referential of resouces supporting tag" {

        it "Resources type not in referential should not support tags" {
            $supportTag = Test-ResourceTypeSupportTags -resourceType "ninja/youcantfindme" -referentialFilePath ".\resourceCreatedFunction\tag-support.csv"
            $supportTag | Should -Be $false
        }

        it "Resources type with matching provider but no serviceName should not support tags" {
            $supportTag = Test-ResourceTypeSupportTags -resourceType "Microsoft.Storage/youcantfindme" -referentialFilePath ".\resourceCreatedFunction\tag-support.csv"
            $supportTag | Should -Be $false
        }

        it "Resources type with matching provider and serviceName and TRUE supportsTags column should support tags" {
            $supportTag = Test-ResourceTypeSupportTags -resourceType "Microsoft.Storage/storageAccounts" -referentialFilePath ".\resourceCreatedFunction\tag-support.csv"
            $supportTag | Should -Be $true
        }

        it "Resources type with matching provider and serviceName and FALSE supportsTags column should not support tags" {
            $supportTag = Test-ResourceTypeSupportTags -resourceType "Microsoft.Storage/usages" -referentialFilePath ".\resourceCreatedFunction\tag-support.csv"
            $supportTag | Should -Be $false
        }

        it "Resources type with matching provider and multi part serviceName and TRUE supportsTags column should support tags" {
            $supportTag = Test-ResourceTypeSupportTags -resourceType "Microsoft.Web/sites/slots" -referentialFilePath ".\resourceCreatedFunction\tag-support.csv"
            $supportTag | Should -Be $true
        }

        it "Resources type with matching provider and multi part serviceName and FALSE supportsTags column should not support tags" {
            $supportTag = Test-ResourceTypeSupportTags -resourceType "Microsoft.Storage/storageAccounts/blobServices" -referentialFilePath ".\resourceCreatedFunction\tag-support.csv"
            $supportTag | Should -Be $false
        }
    }

    Context "Get the event initiator display name" {
        it "Should retrieve the creator display name if created by a service principal" {
            $testQueueItem = @{data = @{
                authorization = @{evidence= @{principalType="ServicePrincipal"}};
                claims = @{appId="c'est moi lol"}}
            }
            $displayName = Get-EventInitiatorDisplayName -queueItem $testQueueItem
            $displayName | Should -Be "Service Principal c'est moi lol"
        }

        it "Should retrieve the creator display name if created by a user" {
            $testQueueItem = @{data = @{claims = @{name="c'est lui"}}
            }
            $displayName = Get-EventInitiatorDisplayName -queueItem $testQueueItem
            $displayName | Should -Be "c'est lui"
        }
    }

    Context "Apply the created tag to the resource" {

        it "Should add the createdBy tag if resource has any tag" {
            $testResourceTags = @{}
            $resourceUri = "/subscription/bim"    
            $creatorDisplayName = "Ambroise"                                
            Mock Set-AzResource {return $null} -Verifiable -ParameterFilter {
                $ResourceId -eq $resourceUri `
                -and $Tag["createdBy"] -eq $creatorDisplayName
            }         
            Set-ResourceCreatedByTag -resourceTags $testResourceTags -creatorDisplayName $creatorDisplayName -resourceUri $resourceUri
            Assert-VerifiableMock
        }

        it "Should append the createdBy tag if resource already has tags" {
            $testResourceTags = @{kikoo="bim"}
            $resourceUri = "/subscription/bim"    
            $creatorDisplayName = "Ambroise"                                
            Mock Set-AzResource {return $null} -Verifiable -ParameterFilter {
                $ResourceId -eq $resourceUri `
                -and $Tag["createdBy"] -eq $creatorDisplayName `
                -and $Tag["kikoo"] -eq "bim"
            }         
            Set-ResourceCreatedByTag -resourceTags $testResourceTags -creatorDisplayName $creatorDisplayName -resourceUri $resourceUri
            Assert-VerifiableMock
        }

        it "Should update the createdBy tag if it has a wrong value" {
            $testResourceTags = @{createdBy="bim"}
            $resourceUri = "/subscription/bim"    
            $creatorDisplayName = "Ambroise"                                
            Mock Set-AzResource {return $null} -Verifiable -ParameterFilter {
                $ResourceId -eq $resourceUri `
                -and $Tag["createdBy"] -eq $creatorDisplayName
            }         
            Set-ResourceCreatedByTag -resourceTags $testResourceTags -creatorDisplayName $creatorDisplayName -resourceUri $resourceUri
            Assert-VerifiableMock
        }

        it "Should not update the createdBy tag if it already has the good value" {
            $creatorDisplayName = "Ambroise" 
            $testResourceTags = @{createdBy=$creatorDisplayName}
            $resourceUri = "/subscription/bim"                         
            Mock Set-AzResource -Verifiable  
            Set-ResourceCreatedByTag -resourceTags $testResourceTags -creatorDisplayName $creatorDisplayName -resourceUri $resourceUri
            Assert-MockCalled Set-AzResource -Times 0
        }
    }

    Context "Update the resources creator referential" {

        it "Should add the creator in the referential if it does not exist" {   
            $resourceUri = "kiKKo/IamAResourCE/Nice" 
            $formatedResourceUri = "kikko-iamaresource-nice" 
            $subscriptionId = "46545645454"
            $creatorDisplayName = "Gabriel"
            $eventTime = "now"
            $cloudTable = @{hello="iamacloudtable"}                   

            $env:storageName = "theStorage"
            $env:resourceGroupName = "theResourceGroup" 
            $env:tableName = "theTableName"       
        
            Mock Get-AzTableTable -Verifiable {return $cloudTable} -ParameterFilter {
                $storageAccountName -eq $env:storageName `
                -and $resourceGroup -eq $env:resourceGroupName `
                -and $TableName -eq $env:tableName 
            }       
            Mock Get-AzTableRow -Verifiable {return $null} -ParameterFilter {
                $Table -eq $cloudTable `
                -and $PartitionKey -eq  $formatedResourceUri `
                -and $RowKey -eq $subscriptionId
            }

            Mock Add-AzTableRow -Verifiable {return $null} -ParameterFilter {
                $Table -eq $cloudTable `
                -and $PartitionKey -eq $formatedResourceUri `
                -and $RowKey -eq $subscriptionId `
                -and $property["createdBy"] -eq $creatorDisplayName `
                -and $property["createdAt"] -eq $eventTime
            } 

            $displayName = Update-referential -resourceUri $resourceUri -subscriptionId $subscriptionId -creatorDisplayName $creatorDisplayName -eventTime $eventTime
            $displayName | Should -Be $creatorDisplayName
            Assert-VerifiableMock 
        }

        it "Should get the creator from the referential if it exists" {   
            $resourceUri = "kiKKo/IamAResourCE/Nice" 
            $formatedResourceUri = "kikko-iamaresource-nice" 
            $subscriptionId = "46545645454"
            $creatorDisplayName = "Gabriel"
            $eventTime = "now"
            $cloudTable = @{hello="iamacloudtable"}                   

            $env:storageName = "theStorage"
            $env:resourceGroupName = "theResourceGroup" 
            $env:tableName = "theTableName"       
        
            Mock Get-AzTableTable -Verifiable {return $cloudTable} -ParameterFilter {
                $storageAccountName -eq $env:storageName `
                -and $resourceGroup -eq $env:resourceGroupName `
                -and $TableName -eq $env:tableName 
            }       
            Mock Get-AzTableRow -Verifiable {return @{createdBy=$creatorDisplayName}} -ParameterFilter {
                $Table -eq $cloudTable `
                -and $PartitionKey -eq  $formatedResourceUri `
                -and $RowKey -eq $subscriptionId
            }

            Mock Add-AzTableRow -Verifiable

            $displayName = Update-referential -resourceUri $resourceUri -subscriptionId $subscriptionId -creatorDisplayName "Francis" -eventTime $eventTime
            $displayName | Should -Be $creatorDisplayName
            
            Assert-MockCalled Add-AzTableRow -Times 0 
            Assert-MockCalled Get-AzTableTable -Times 1
            Assert-MockCalled Get-AzTableRow -Times 1            
        }
    }
}