#!/bin/bash

workDir="$(dirname "$0")"
masTokenFile="$workDir/masToken"
scriptInput="$1"

if [[ -n "$LOOKUP_MATRIX_USER_CONFIG_FILE" ]]; then
    configFile="$LOOKUP_MATRIX_USER_CONFIG_FILE"
else
    configFile="$workDir/config.env"
fi

if [[ ! -f "$configFile" ]]; then
    echo "Config file $workDir/config.env not found"
    exit 1
fi
source "$configFile"

# Check if we have a valid MAS Admin token stored and authenticate if not
touch "$masTokenFile"
chmod 600 "$masTokenFile"
masAdminToken="$(head -n 1 "$masTokenFile")"
masTestResult="$(
    curl \
        --header "Authorization: Bearer $masAdminToken" \
        --request GET \
        --silent \
        --url "$masEndpoint/api/admin/v1/users/by-username"
)"

if echo "$masTestResult" \
    | grep -E '"(Unknown access token|Invalid authorization header)"' \
    &>/dev/null
then
    masAdminToken="$(
        curl \
            --data grant_type=client_credentials \
            --data scope=urn:mas:admin \
            --request POST \
            --silent \
            --url "$masEndpoint/oauth2/token" \
            --user "$masClientId:$masClientSecret" \
            | jq -r '.access_token'
        )"
    echo "$masAdminToken" > "$masTokenFile"
fi

# Process script input
if [[ "$scriptInput" != "@"* ]] && [[ $scriptInput == *"@"* ]]; then
    # Script input does not start with @ so not a full Matrix ID,
    # but contains an @, so might be an email address
    emailAddress="$scriptInput"
    emailAddressEncoded=${emailAddress//+/%2B}
    emailResult="$(
        curl \
            --header "Authorization: Bearer $masAdminToken" \
            --request GET \
            --silent \
            --url "$masEndpoint/api/admin/v1/user-emails?filter%5Bemail%5D=$emailAddressEncoded"
    )"

    emailCount="$(echo "$emailResult" | jq --raw-output '.meta.count')"
    if [[ "$emailCount" -eq 0 ]]; then
        echo "No MAS account found with the email address $emailAddress"
        exit 1
    fi

    echo "MAS Admin API: Get user by email"
    echo "$emailResult" | jq .

    masUserId="$(
        echo "$emailResult" | jq --raw-output '.data[0].attributes.user_id'
    )"
else
    if [[ "$scriptInput" == "@"* ]]; then
        # Script input starts with an @ so probably a full Matrix ID
        matrixId="$scriptInput"
        localpart=${matrixId//@/}
        # shellcheck disable=SC2001
        localpart=$(echo "$localpart" | sed "s/:$serverName//g")
    else
        # Script input was probably a localpart
        localpart="$scriptInput"
    fi
    localpartResult="$(
        curl \
            --header "Authorization: Bearer $masAdminToken" \
            --request GET \
            --silent \
            --url "$masEndpoint/api/admin/v1/users/by-username/$localpart"
    )"

    if echo "$localpartResult" | grep " not found" &>/dev/null; then
        echo "No MAS account found with the localpart $localpart"
        exit 1
    fi

    echo "MAS Admin API: Get user by localpart"
    echo "$localpartResult" | jq .

    masUserId="$(echo "$localpartResult" | jq --raw-output '.data.id')"

fi

# Get MAS user details
userResult="$(
    curl \
        --header "Authorization: Bearer $masAdminToken" \
        --request GET \
        --silent \
        --url "$masEndpoint/api/admin/v1/users/$masUserId" \
        | jq .
    )"
echo -e "\nMAS Admin API: Get user info"
echo "$userResult" | jq .
if [[ "$scriptInput" != "@"* ]]; then
    localpart="$(
        echo "$userResult" | jq --raw-output '.data.attributes.username'
    )"
    matrixId="@$localpart:$serverName"
fi

# Get MAS user emails
echo -e "\nMAS Admin API: Get user emails"
curl \
    --header "Authorization: Bearer $masAdminToken" \
    --request GET \
    --silent \
    --url "$masEndpoint/api/admin/v1/user-emails?filter%5Buser%5D=$masUserId" \
    | jq .

# Get MAS user upstream oauth
echo -e "\nMAS Admin API: Get user upstream oauth"
curl \
    --header "Authorization: Bearer $masAdminToken" \
    --request GET \
    --silent \
    --url "$masEndpoint/api/admin/v1/upstream-oauth-links?filter%5Buser%5D=$masUserId" \
    | jq .

# Get user info from Synapse
echo -e "\nSynapse Admin API: Get user info"
curl \
    --header "Authorization: Bearer $synapseAdminToken" \
    --request GET \
    --silent \
    --url "$synapseEndpoint/_synapse/admin/v2/users/$matrixId" \
    | jq .
