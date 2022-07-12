#!/usr/bin/env bash
SUBDOC=w3c

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

set -e

cat <<EOF | save $SUBDOC W3C-VC_unsigned.json
{"my-vc": {
  "@context": [
    "https://www.w3.org/2018/credentials/v1",
    "https://www.w3.org/2018/credentials/examples/v1"
  ],
  "id": "http://example.edu/credentials/1872",
  "type": ["VerifiableCredential", "AlumniCredential"],
  "issuer": "https://example.edu/issuers/565049",
  "issuanceDate": "2010-01-01T19:73:24Z",
  "credentialSubject": {
    "id": "did:example:ebfeb1f712ebc6f1c276e12ec21",
    "alumniOf": {
      "id": "did:example:c276e12ec21ebfeb1f712ebc6f1",
      "name": [{
        "value": "Example University",
        "lang": "en"
      }, {
        "value": "Exemple d'Université",
        "lang": "fr"
      }]
    }
  }
},
"pubkey_url": "https://dyne.org/verification/keys/1"
}
EOF

cat <<EOF | zexe W3C-VC_keygen.zen | save $SUBDOC W3C-VC_keypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Alice'
When I create the ecdh key
Then print my data
EOF

cat <<EOF | zexe W3C-VC_issuerKeygen.zen  | save $SUBDOC W3C-VC_issuerKeypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Authority'
When I create the ecdh key
Then print my data
EOF


cat <<EOF | zexe W3C-VC_pubkey.zen -k W3C-VC_issuerKeypair.json | save $SUBDOC W3C-VC_pubkey.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Authority'
and I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF

cat <<EOF | zexe W3C-VC_sign.zen -a W3C-VC_unsigned.json -k W3C-VC_issuerKeypair.json | save $SUBDOC W3C-VC_signed.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'verifiable credential' named 'my-vc'
Given I have a 'string' named 'pubkey url'
When I sign the verifiable credential named 'my-vc'
When I set the verification method in 'my-vc' to 'pubkey url'
Then print 'my-vc' as 'string'
EOF

cat <<EOF | zexe W3C-VC_verify.zen -a W3C-VC_signed.json -k W3C-VC_pubkey.json | save $SUBDOC W3C-VC_output.json
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
Given I have a 'verifiable credential' named 'my-vc'
When I verify the verifiable credential named 'my-vc'
Then print the string 'W3C CREDENTIAL IS VALID'
EOF

cat <<EOF | zexe W3C-VC_extract.zen -a W3C-VC_signed.json | save $SUBDOC W3C-VC_extracted_verification_method.json
Scenario 'w3c' : extract verification method
Given I have a 'verifiable credential' named 'my-vc'
When I get the verification method in 'my-vc'
Then print 'verification method' as 'string'
EOF


cat <<EOF | save w3c simple_string.json
{ "simple": "once upon a time... there was a wolf" }
EOF

cat <<EOF | zexe W3C-jws_sign.zen -a simple_string.json -k W3C-VC_issuerKeypair.json | save $SUBDOC W3C-jws_signed.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string' named 'simple'
When I create the jws signature of 'simple'
Then print the 'jws'
and print the 'simple'
EOF

cat <<EOF | zexe W3C-jws_verify.zen -a W3C-jws_signed.json -k W3C-VC_pubkey.json
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
and I have a 'string' named 'jws'
and I have a 'string' named 'simple'
When I verify the jws signature of 'simple'
Then print the string 'W3C JWS IS VALID'
EOF

# reading did documents
cat <<EOF | save $SUBDOC did_document.json
{
   "did document":{
      "@context":[
         "https://www.w3.org/ns/did/v1",
         "https://dyne.github.io/W3C-DID/specs/EcdsaSecp256k1_b64.json",
         "https://dyne.github.io/W3C-DID/specs/ReflowBLS12381_b64.json",
         "https://dyne.github.io/W3C-DID/specs/SchnorrBLS12381_b64.json",
         "https://dyne.github.io/W3C-DID/specs/Dilithium2_b64.json",
         "https://w3id.org/security/suites/secp256k1-2020/v1",
         {
            "Country":"https://schema.org/Country",
            "State":"https://schema.org/State",
            "description":"https://schema.org/description",
            "url":"https://schema.org/url"
         }
      ],
      "Country":"de",
      "State":"NONE",
      "alsoKnownAs":"did:dyne:fabchain:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=",
      "description":"restroom-mw",
      "id":"did:dyne:id:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=",
      "service":[
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-announce",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-announce",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain",
            "serviceEndpoint":"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-get-identity",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-http-post",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-http-post",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-ping.zen",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain",
            "serviceEndpoint":"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-update",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-update",
            "type":"LinkedDomains"
         }
      ],
      "verificationMethod":[
         {
            "controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
            "id":"did:dyne:id:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=#key_ecdsa1",
            "publicKeyBase64":"BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=",
            "type":"EcdsaSecp256k1VerificationKey_b64"
         },
         {
            "controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
            "id":"did:dyne:id:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=#key_reflow1",
            "publicKeyBase64":"AoD1VmYjfBP0L26CpsYRnzEkaslI91uBIknP/3bqWEq4S6JdjWIomIe3CfypCCe/Cz3Lsodx/rBlxIxXktpKBYYddjNgwUCWJ4jGUryLNSoBA2WcdY360FV2bu/fUABhC3oQHFSlwwpmltWvoSrMBqZ/6R5UvX2iC+lkI3966jcB3zhJ0dBsIrVkftGhvr3EFHgHafua/XL+IaqbmJ+fIhhq60yjnJ/i3riAcO3+aZX3fcFBkGH/de5NPCyunSeD",
            "type":"ReflowBLS12381VerificationKey_b64"
         },
         {
            "controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
            "id":"did:dyne:id:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=#key_schnorr1",
            "publicKeyBase64":"GCz+aD+oqmm/aA9GM0mauJjEL3a2sJuTcuOGgmkqMD7869PpTHsh8VmfNvfY20p1",
            "type":"SchnorrBLS12381VerificationKey_b64"
         },
	 {
            "controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
            "id":"did:dyne:id:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=#key_eddsa",
            "publicKeyBase58":"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
            "type":"Ed25519VerificationKey2018"
         },
         {
            "controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
            "id":"did:dyne:id:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=#key_dilithium1",
            "publicKeyBase64":"xJ27Sc28WRK7VuDInQbb+YwtiS++tycCYGKMVmoXMmnuHO4JAFWJd+t4EwCndchQCXRlY4dh3e2Y97LfcOYC4vxYYzMx6btyhkwOeLZduKqyRco3V5M6QfnxPGdJeSOmbxoCq+Akkwg1wnOCUOhQ7KB/106w1Na+UWYuqLXtKWjrqJWyKdZx8alTn7nYDGWzr5sjnBXnTFGEpfjbiJvYcIstBd24KropNIndVxKuFvG97Kg8w4XrEknPDK1ELTJydeN9mEw7DXrMLPnmf1rILh3Fr4dVfN7ac+ujT87eqs5vRlgnBdJNuV7I/lpuoR2MX0SeqfSGtXB0ksuYPTylmYTmDg0OOzQ86Pm27Fq9VWu9QSX/7feESlY0tVFPYi0N8n+RudAFKjDyC9jy9lUOmJ5uSUCL7PAT4hsgtAhNyXdBlwEkeTwBdQPpzgyC+wYKLe8bKKRaUOrJzmRVBaZBngqKIX8olMy1R09EkcSOs/OlORQ00Mzb1lRGvAbZ7BO4N+Dd8UVlwK3W6cDp9EWrWZ1QhRktNyaUwW0bgMjiak65c9Rl3ZY8wUye/COsit1vrHkS1635wAeFFyHKPoa9pGSenhzp2weAEIWhlXJcziGMc0gfZs8UdIUxk62jhby9wDfPwz6Jn0cmeQvOWRYbYKBg/OKFAIXN4jIENZFh8fIZ3o2zli6POlifbWnTqvAa+FB/W86p+ndAhTwoSXmp1A8LYn2kUkCRGaiZAm2hUBcoa/7QVAhOoJ/zqw+zv1v789kBGG8Mww/T2gc8ZvOLS6ZBhRbnEcgOFNyXttnNzEkWXAdbO69JN3jSPBSwRxYxgeO+uGrL6UukDpjgjEvHd59jAo30zPLfX+d3qzQypikzKRZyLqBvn2LTS991JRtHWBXSQC2fGT23MlfyLnW7l0391Iz6Qcs+zxQkaroPZRc2RZTAgPpH9VxCp5CSx91hKYT4HzUuBA0+is1g5yG1k7p2qQTYPvzf292Gj6301B7+lvji9LKb1029VHS227C+rtZwlO/nauLlMUvSWgsyyw8nhnmVP0jNCDwILIUg+XQ/gUCM63N024Wooa79+52nJo2rnrq9qQzTMkHTbS+V0eajpg2HD8TfOtjJH0FNqIsinq7m4Ntrny56t+JtWkrJumVMUBd8O9c0LhuD9iYPFEhWYEUfPyO0ocnw6BLb2ehigh0cLBfAMOSIrtrZhC/PHzQM1L/zyY+WRtnBucMRWMevOS/SkxwF7coTqh8c72yimdQqHbF7clF9c6pIpL5QnobBCNj1kgBv+9M7gztyoLUZUlb1FgonS1HHEU1804BkFWZpGxalTVbpk8H5/ZXs2JT0A2FkBX1OdsgavsrxryBg3sbWrWbIDqVabrku1tH58WDZau+YY0cWEDIccoKx04I+s5fJKaxvm32SsCK9/bWzmQGQmM9LQl4P6Q3fNDQ7mVtAYbYzkYJUFtP5TV/ErTQIlJhZAHm87f6lZXllg/kWwCPB37C3W+p7OIjNFNAbfIJASQhga/1BIFBqWnViToysVCU0l4y7y1V2qhkcHAdNlsC61DyVRdbbdlF/DwpT+0mVfDmX1UUgXlqkoYDDEg03GCTrweN/7GLJAfUB3p+YRddjUK13wfy/4hd7KneEMB571pqxGH6cSUkULreVQiLhr0YzV+gwQl8IZ60pwLTZs4wBFg6U/kJY1pyQ1oCfqjGaJLYD4KjVeaoUDPDGcZsrPeP34QNpw05k+mrIwQ==",
            "type":"Dilithium2VerificationKey_b64"
         },
         {
            "blockchainAccountId":"eip155:1717658228:0x0af4f27fc04063ab8238402b1362c58f52a480a5",
            "controller":"did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
            "id":"did:dyne:id:BMryTzTcMC42F4dOWdXM5mVAZr0dvS0jV84oBt/SQBePhxH2p3/NilU9siTfdNWv7iPcViIPDtz3JxFiQY/Gu5s=#fabchainAccountId",
            "type":"EcdsaSecp256k1RecoveryMethod2020"
         }
      ]
   }
}
EOF


cat <<EOF | zexe did_document.zen -a did_document.json | jq
Scenario 'w3c': did document manipulation

Given I have a 'did document'

When I create the verificationMethod
When I create the serviceEndpoint

Then print the 'verificationMethod'
Then print the 'serviceEndpoint'
EOF

cat <<EOF | zexe did_document-jws_sign.zen -a did_document.json -k W3C-VC_issuerKeypair.json | save $SUBDOC did_document_signed.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'did document'

When I create the jws signature of 'did document'
When I create the 'string dictionary' named 'proof'
When I insert 'jws' in 'proof'
When I insert 'proof' in 'did document'

Then print the 'did document'
EOF

cat <<EOF | zexe did_document-jws_verify.zen -a did_document_signed.json -k W3C-VC_pubkey.json | jq
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
and I have a 'string dictionary' named 'did document'

When I verify the did document named 'did document'

Then print the string 'W3C JWS IS VALID'
EOF

success
rm *.json *.zen
