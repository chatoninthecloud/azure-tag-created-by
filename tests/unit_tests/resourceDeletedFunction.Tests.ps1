Describe "A resource is deleted in the subscription" -Tag @("resourceDeletedFunction","unit_test") {
    # Remove Write-Host message from test running

    BeforeAll {
        Import-Module .\function\Modules\tagResource -Force   
        Set-Location .\function 
    }
    
    AfterAll {
        Set-Location ..
    }
    
    # The queueitem input message
    $testQueueItem = @{
        data = @{
            resourceUri = "myresourceurI/HellO/pubLIcIp";
            subscriptionId = "172545785462556";
        }
    }

    $formatedResourceUri = "myresourceuri-Hello-publicip" 

    Context "Update the referential" {

        It "Should remove entry in referential if it exists" {   
            
            $env:storageName = "theStorage"
            $env:resourceGroupName = "theResourceGroup" 
            $env:tableName = "theTableName"  
            
            $cloudTable = @{hello="iamacloudtable"}  
            $row = @{hello="iamthetablerow"}

            Mock Get-AzTableTable -Verifiable {return $cloudTable} -ParameterFilter {
                $storageAccountName -eq $env:storageName `
                -and $resourceGroup -eq $env:resourceGroupName `
                -and $TableName -eq $env:tableName 
            }       
            Mock Get-AzTableRow -Verifiable {return $row} -ParameterFilter {
                $Table -eq $cloudTable `
                -and $PartitionKey -eq  $formatedResourceUri `
                -and $RowKey -eq $testQueueItem.data.subscriptionId
            }

            Mock Remove-AzTableRow -Verifiable {return $null} -ParameterFilter {
                $cloudTable -eq $cloudTable `

            }

            .\resourceDeletedFunction\run.ps1 -QueueItem $testQueueItem

            Assert-VerifiableMock
        }

        It "Should do nothing if entry is not in referential" {   
            
            $env:storageName = "theStorage"
            $env:resourceGroupName = "theResourceGroup" 
            $env:tableName = "theTableName"  
            
            $cloudTable = @{hello="iamacloudtable"}  
            $row = @{hello="iamthetablerow"}

            Mock Get-AzTableTable -Verifiable {return $cloudTable} -ParameterFilter {
                $storageAccountName -eq $env:storageName `
                -and $resourceGroup -eq $env:resourceGroupName `
                -and $TableName -eq $env:tableName 
            }       
            Mock Get-AzTableRow -Verifiable {return $null} -ParameterFilter {
                $Table -eq $cloudTable `
                -and $PartitionKey -eq  $formatedResourceUri `
                -and $RowKey -eq $testQueueItem.data.subscriptionId
            }

            Mock Remove-AzTableRow -Verifiable 

            .\resourceDeletedFunction\run.ps1 -QueueItem $testQueueItem

            Assert-MockCalled Get-AzTableTable -Times 1    
            Assert-MockCalled Get-AzTableRow -Times 1                
            Assert-MockCalled Remove-AzTableRow -Times 0 
        }
    }
}