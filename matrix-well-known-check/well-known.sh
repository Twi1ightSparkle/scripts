#!/bin/bash

repeatchar() {
    character="$1"
    count="$2"
    string=""
    for i in $(seq "$count"); do
        string+="$character"
    done
    echo "$string"
}

prettyHeader() {
    string="$1"
    length="${#string}"
    hashes="$(repeatchar "#" "$length")"
    spaces="$(repeatchar " " "$length")"
    cat <<EOF


####$hashes####
##  $spaces  ##
##  $string  ##
##  $spaces  ##
####$hashes####


EOF
}

domain="$1"
if [ -z "$domain" ]; then
    cat <<EOT
Usage: ./well-known.sh <homeserver.domain> [additional cURL options]

cURL options --location (follow redirects) and --silent (no progress output) are always set.
EOT
else
    shift
    curlParams=("$@")
    matrixUrl="https://$domain/.well-known/matrix"

    prettyHeader "$domain Federation Tester result"
    federationTesterResult="$(curl --location --silent "${curlParams[@]}" \
        "https://federationtester.matrix.org/api/report?server_name=$domain")"
    echo "$federationTesterResult" | jq .

    synapseDomain="$(echo "$federationTesterResult" | jq '.WellKnownResult."m.server"' --raw-output)"
    if [[ -z "$synapseDomain" ]]; then
        synapseDomain="$(echo "$federationTesterResult" | jq '.DNSResult.SRVRecords[0].Target' --raw-output)"
    fi

    prettyHeader "$domain Login flows"
    curl --header 'content-type: application/json' --silent "${curlParams[@]}" \
        "https://$synapseDomain/_matrix/client/v3/login" | jq .

    prettyHeader "$domain Registration flows"
    curl --data '{}' --header 'content-type: application/json' --request POST --silent "${curlParams[@]}" \
        "https://$synapseDomain/_matrix/client/v3/register" | jq .

    prettyHeader "$domain DNS records"
    dig +noall +answer all "$domain"

    files=(client server support)
    for file in "${files[@]}"; do
        prettyHeader "$matrixUrl/$file headers"
        headers="$(curl --location --silent "${curlParams[@]}" --dump-header - --output /dev/null "$matrixUrl/$file")"
        echo "$headers"

        redirectURL="$(echo "$headers" | grep "location: ")"
        if [[ -n "$redirectURL" ]]; then
            redirectDomain="$(echo "$redirectURL" | sed -E 's#location: http(s)?://##g' | sed -E 's#/.*##g')"
            prettyHeader "$redirectDomain DNS records"
            echo -e "$domain redirects to $redirectDomain\n"
            dig +noall +answer all "$redirectDomain"
        fi

        prettyHeader "$matrixUrl/$file content"
        if ! curl --location --silent "${curlParams[@]}" "$matrixUrl/$file" | jq . 2>/dev/null; then
            echo -e "$matrixUrl/$file content is not valid JSON\n\n"
            curl --location --silent "${curlParams[@]}" "$matrixUrl/$file"
        fi
    done
fi
