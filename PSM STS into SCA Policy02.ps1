# === Configuration ===

# Use environment variable or secure method for secrets
$clientId = "scaapiuser@przd-test3"
$clientSecret = "sTo@w7iZpD>WP~|T"
if (-not $clientSecret) {
    throw "Client secret not found. Set CYBERARK_CLIENT_SECRET environment variable."
}

$tenantId = "abt4530"
$ispss_subdomain = "przd-test3"
$cyberarkBaseUrl = "https://$ispss_subdomain.cyberark.cloud"
$tokenUrl = "https://$tenantId.id.cyberark.cloud/oauth2/platformtoken"
$accountId = "15_4"
$AWSOrganizationManagemntID = "897729140478"
$SCApolicyIdentity = "przemek@cyberark.cloud.33154"
$SCApolicyDirectoryID = "09B9A9B0-6CE8-465F-AB03-65766D33B05E"
$SCApolicyIdType = "user"

# === Function: Get Access Token ===
function Get-AccessToken {
    try {
        $body = @{
            client_id     = $clientId
            client_secret = $clientSecret
            grant_type    = "client_credentials"
        }

        $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Host "Access token acquired."
        return $response.access_token
    } catch {
        throw "Failed to get access token: $_"
    }
}

# === Function: Get Account Info ===
function Get-AccountInfo($token, $id) {
    try {
        $headers = @{ Authorization = "Bearer $token" }
        $url = "https://$ispss_subdomain.privilegecloud.cyberark.cloud/PasswordVault/API/Accounts/$id"
        $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers -ContentType "application/json"
        Write-Host "Account information retrieved."
        return $response
    } catch {
        throw "Failed to retrieve account info: $_"
    }
}

# === Function: Create SCA Policy ===
function Create-SCAPolicy($token, $account) {
    try {
        $headers = @{ Authorization = "Bearer $token" }
        $url = "https://$ispss_subdomain.sca.cyberark.cloud/api/policies/create-policy"

        $body = @{
            csp = "AWS"
            name = "Policy $($account.userName) for account $($account.platformAccountProperties.AWSAccountID)"
            description = "Test description"
            startDate = $null
            endDate = $null
            roles = @(
                @{
                    entityId = $account.platformAccountProperties.AWSARNRole
                    entitySourceId = $account.platformAccountProperties.AWSAccountID
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

        $response = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ContentType "application/json"
        Write-Host "SCA Policy created. Job ID: $($response.job_id)"
    } catch {
        throw "Failed to create SCA policy: $_"
    }
}

# === Execution Flow ===
try {
    $accessToken = Get-AccessToken
    $accountInfo = Get-AccountInfo -token $accessToken -id $accountId

    # Optional debug info
    Write-Host "Account ID: $($accountInfo.id)"
    Write-Host "User: $($accountInfo.userName)"
    Write-Host "Role ARN: $($accountInfo.platformAccountProperties.AWSARNRole)"

    Create-SCAPolicy -token $accessToken -account $accountInfo

} catch {
    Write-Error "Script failed: $_"
}
#just checking 