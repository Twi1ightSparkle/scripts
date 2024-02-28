# Print well-known data for a Matrix server domain

Example:

```plaintext
$ ./well-known.sh
Usage: ./well-known.sh <homeserver.domain> [additional cURL options]

cURL options --location (follow redirects) and --silent (no progress output) are always set.


$ ./well-known.sh element.io


###########################################
##                                       ##
##  element.io Federation Tester result  ##
##                                       ##
###########################################


{
  "WellKnownResult": {
    "m.server": "element.ems.host:443",
    "CacheExpiresAt": 1709122293
  },
  "DNSResult": {
    "SRVSkipped": true,
    "SRVCName": "",
    "SRVRecords": null,
    "SRVError": null,
    "Hosts": {
      "element.ems.host": {
        "CName": "k8s-core-coreingr-b3a4d5441e-11aa9fe745bc6bd9.elb.eu-central-1.amazonaws.com.",
        "Addrs": [
          "3.73.156.240"
        ],
        "Error": null
      }
    },
    "Addrs": [
      "3.73.156.240:443"
    ]
  },
  "ConnectionReports": {
    trimmed...
  },
  "ConnectionErrors": {},
  "Version": {
    "name": "Synapse",
    "version": "1.101.0"
  },
  "FederationOK": true
}


##############################
##                          ##
##  element.io DNS records  ##
##                          ##
##############################


element.io.		30	IN	A	104.22.49.198
element.io.		30	IN	A	104.22.48.198
element.io.		30	IN	A	172.67.12.112


############################################################
##                                                        ##
##  https://element.io/.well-known/matrix/client headers  ##
##                                                        ##
############################################################


HTTP/2 200
date: Wed, 28 Feb 2024 11:34:54 GMT
content-type: application/json
access-control-allow-origin: *
trimmed...


#############################################
##                                         ##
##  matrix.redirection.domain DNS records  ##
##                                         ##
#############################################
<this section is only printed if the client file is a redirect>

aleph.ems.host redirects to matrix.redirection.domain

matrix.redirection.domain.	30	IN	A	1.2.3.4


############################################################
##                                                        ##
##  https://element.io/.well-known/matrix/client content  ##
##                                                        ##
############################################################


{
  "m.homeserver": {
    "base_url": "https://element.ems.host"
  },
  "m.identity_server": {
    "base_url": "https://vector.im"
  },
  "org.matrix.msc2965.authentication": {
    "issuer": "https://element.ems.host/",
    "account": "https://mas.element.io/account"
  },
  "org.matrix.msc3575.proxy": {
    "url": "https://element.ems.host"
  }
}


############################################################
##                                                        ##
##  https://element.io/.well-known/matrix/server headers  ##
##                                                        ##
############################################################


HTTP/2 200
date: Wed, 28 Feb 2024 11:34:54 GMT
content-type: application/json
cache-control: max-age=1800
trimmed...


#############################################
##                                         ##
##  matrix.redirection.domain DNS records  ##
##                                         ##
#############################################
<this section is only printed if the server file is a redirect>

aleph.ems.host redirects to matrix.redirection.domain

matrix.redirection.domain.	30	IN	A	1.2.3.4


############################################################
##                                                        ##
##  https://element.io/.well-known/matrix/server content  ##
##                                                        ##
############################################################


{
  "m.server": "element.ems.host:443"
}
```
