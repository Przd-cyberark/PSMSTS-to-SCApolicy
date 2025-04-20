# === Configuration ===
# Tenant related config
$clientId = "scaapiuser@przd-test3" # service user
$clientSecret = "*********"  # hardcoding secrets!!! dont do it! (this is just a lab)
$tenantId = "abt4530"
$ispss_subdomain = "przd-test3"
$cyberarkBaseUrl = "https://$ispss_subdomain.cyberark.cloud"  
$tokenUrl = "https://$tenantId.id.cyberark.cloud/oauth2/platformtoken" # Token Endpoint for IS-PSS

#id of the account in priv cloud that stores the AWS role
$accountId = "15_4"  # Replace with a real Privilege  account ID 
#### in my tenant this account ^^^ has the role stored. Its a not working stub but it should fit

# config of organization - since onbaorded accounts are part of an org, creation of the policy needs management account id as a parameter
$AWSOrganizationManagemntID = "897729140478" #this needs to be Account Number of the management account where AWS account is

# config of who the policy will be created for, in the more advanced version these should be variables read from the safe authorization
# i am hardcoding them for now
$SCApolicyIdentity = "przemek@cyberark.cloud.33154"
$SCApolicyDirectoryID = "09B9A9B0-6CE8-465F-AB03-65766D33B05E" #this is the cyberark cloud directory id on  tenant przd-test3
$SCApolicyIdType = "user"

# === Step 1: Get Access Token ===
$tokenBody = @{
    client_id     = $clientId
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $tokenBody -ContentType "application/x-www-form-urlencoded"
$accessToken = $tokenResponse.access_token

Write-Host "Access token acquired."

# === Step 2: Retrieve Account Content ===
# Use the Account ID


$headers = @{
    Authorization = "Bearer $accessToken"
}
$accountUrl = "https://$ispss_subdomain.privilegecloud.cyberark.cloud/PasswordVault/API/Accounts/$accountId"
$accountResponse = Invoke-RestMethod -Method Get -Uri $accountUrl -Headers $headers -ContentType "application/json"

Write-Host "platformId: $($accountResponse.platformId)"
Write-Host "safeName: $($accountResponse.safeName)"
Write-Host "id: $($accountResponse.id)"
Write-Host "name: $($accountResponse.name)"
Write-Host "address: $($accountResponse.address)"
Write-Host "userName: $($accountResponse.userName)"
Write-Host "AWSARNRole: $($accountResponse.platformAccountProperties.AWSARNRole)"
Write-Host "AWSAccountAliasName: $($accountResponse.platformAccountProperties.AWSAccountAliasName)"
Write-Host "AWSAccountID: $($accountResponse.platformAccountProperties.AWSAccountID)"

# === Step 3 Create SCA Policy ===

# I'm acreating in the same tenant
$SCAPolicyPostURL = "https://$ispss_subdomain.sca.cyberark.cloud/api/policies/create-policy"


$SCApolicyPOSTBody = @{
    csp = "AWS"
    #name = "Policy 123456"
    name = "Policy $($accountResponse.userName) for account $($accountResponse.platformAccountProperties.AWSAccountID)"
    description = "Test description"
    startDate = $null
    endDate = $null
    roles = @(
        @{
            entityId = $accountResponse.platformAccountProperties.AWSARNRole
            entitySourceId = $accountResponse.platformAccountProperties.AWSAccountID
            workspaceType = $null
            organization_id = $AWSOrganizationManagemntID
        }
    )
    identities = @(
        @{
            entityName = $SCApolicyIdentity
            entitySourceId = $SCApolicyDirectoryID
            entityClass = $SCApolicyIdType
        }
    )
    accessRules = @{
        days = @("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
        fromTime = $null
        toTime = $null
        maxSessionDuration = 3
        timeZone = "Europe/London"
    }
} | ConvertTo-Json -Depth 5


$SCApolicyResponse = Invoke-RestMethod -Uri $SCAPolicyPostURL -Method Post -Headers $headers -Body $SCApolicyPOSTBody -ContentType "application/json"
Write-Host "Job ID is: $($SCApolicyResponse.job_id)"

#### job_id should be queried to see what came out if this
