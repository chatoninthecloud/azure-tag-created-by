Describe "A resource is created in the subscription" -Tag @("resourceCreatedFunction","unit_test") {
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
        eventTime = "now";
        data = @{
            resourceUri = "myresourceuri/toto/publicip";
            subscriptionId = "172545785462556";
        }
    }

    Context "The resource can't be tagged" {

        It "The resource can't be retrieved by its Id" {           

            Mock Get-AzResource -Verifiable {return $null} -ParameterFilter {$resourceUri -eq $testQueueItem.data.resourceUri}

            .\resourceCreatedFunction\run.ps1 -QueueItem $testQueueItem

            Assert-VerifiableMock
        }

        It "The resource has no resource type" {

            $resource = @{
                resourceType = $null
            }
            Mock Get-AzResource -Verifiable {return $resource} -ParameterFilter {$resourceUri -eq $testQueueItem.data.resourceUri}

            .\resourceCreatedFunction\run.ps1 -QueueItem $testQueueItem

            Assert-VerifiableMock
        }

        It "The resource does not support tag" {

            $resource = @{
                resourceType = "kebab/salade/tomate/ognion"
            }
            Mock Get-AzResource -Verifiable {return $resource} -ParameterFilter {$resourceUri -eq $testQueueItem.data.resourceUri}
            Mock Test-ResourceTypeSupportTags -Verifiable {return $false} -ParameterFilter {$resourceType -eq $resource.resourceType}

            .\resourceCreatedFunction\run.ps1 -QueueItem $testQueueItem

            Assert-VerifiableMock
        }
    }
    Context "The resource can be tagged" {

        It "The resource does support tag, no entry in referential" {

            $resource = @{
                resourceType = "kebab/salade/tomate/ognion"
            }
            Mock Get-AzResource -Verifiable {return $resource} -ParameterFilter {$resourceUri -eq $testQueueItem.data.resourceUri}
            Mock Test-ResourceTypeSupportTags -Verifiable {return $true} -ParameterFilter {$resourceType -eq $resource.resourceType}
            Mock Get-EventInitiatorDisplayName -Verifiable {return "didier"} -ParameterFilter {$queueItem -eq $testQueueItem}
            $updateReferentialParameterFilter = {
                ($resourceUri -eq $testQueueItem.data.resourceUri) `
                -and ($subscriptionid -eq $testQueueItem.data.subscriptionId) `
                -and ($creatorDisplayName -eq "didier") `
                -and ($eventTime -eq $testQueueItem.eventTime)
            }
            Mock Update-referential -Verifiable {return "didier"} -ParameterFilter $updateReferentialParameterFilter
            Mock Set-ResourceCreatedByTag -Verifiable -ParameterFilter {$resourceTags -eq $null -and $creatorDisplayName -eq "didier"}
            .\resourceCreatedFunction\run.ps1 -QueueItem $testQueueItem

            Assert-VerifiableMock
        }

        It "The resource does support tag, entry already in referential" {

            $resource = @{
                resourceType = "kebab/salade/tomate/ognion"
            }
            Mock Get-AzResource -Verifiable {return $resource} -ParameterFilter {$resourceUri -eq $testQueueItem.data.resourceUri}
            Mock Test-ResourceTypeSupportTags -Verifiable {return $true} -ParameterFilter {$resourceType -eq $resource.resourceType}
            Mock Get-EventInitiatorDisplayName -Verifiable {return "didier"} -ParameterFilter {$queueItem -eq $testQueueItem}
            $updateReferentialParameterFilter = {
                ($resourceUri -eq $testQueueItem.data.resourceUri) `
                -and ($subscriptionid -eq $testQueueItem.data.subscriptionId) `
                -and ($creatorDisplayName -eq "didier") `
                -and ($eventTime -eq $testQueueItem.eventTime)
            }
            Mock Update-referential -Verifiable {return "françis"} -ParameterFilter $updateReferentialParameterFilter
            Mock Set-ResourceCreatedByTag -Verifiable -ParameterFilter {$resourceTags -eq $null -and $creatorDisplayName -eq "françis"}
            .\resourceCreatedFunction\run.ps1 -QueueItem $testQueueItem

            Assert-VerifiableMock
        }
    }    
}