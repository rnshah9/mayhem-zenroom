#!/usr/bin/env bash

DEBUG=1
####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

set -e

cat <<EOF | zexe array_32_256.zen > arr.json
rule output encoding url64
Given nothing
When I create the array of '32' random objects of '256' bits
and I rename the 'array' to 'bonnetjes'
Then print the 'bonnetjes'
EOF

cat << EOF | zexe array_length.zen -a arr.json
Given I have a 'url64 array' named 'bonnetjes'
When I create the length of 'bonnetjes'
Then print the 'length'
EOF

cat <<EOF | zexe array_rename_remove.zen -a arr.json
rule input encoding url64
rule output encoding hex
Given I have a 'url64 array' named 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I rename the 'random object' to 'lucky one'
and I remove the 'lucky one' from 'bonnetjes'
# redundant check
and the 'lucky one' is not found in 'bonnetjes'
Then print the 'lucky one'
EOF

# cat <<EOF | zexe array_hashtopoint.zen -a arr.json > ecp.json
# rule input encoding url64
# rule output encoding url64
# Given I have a 'array' named 'bonnetjes'
# When I create the hash to point 'ECP' of each object in 'bonnetjes'
# # When for each x in 'bonnetjes' create the of 'ECP.hashtopoint(x)'
# Then print the 'hashes'
# EOF

# cat <<EOF | zexe array_ecp_check.zen -a arr.json -k ecp.json > hashes.json
# rule input encoding url64
# rule output encoding url64
# Given I have a 'array' named 'bonnetjes'
# and I have a 'ecp array' named 'hashes'
# # When I pick the random object in array 'hashes'
# # and I remove the 'random object' from array 'hashes'
# When for each x in 'hashes' y in 'bonnetjes' is true 'x == ECP.hashtopoint(y)'
# Then print the 'hashes'
# EOF
# # 'x == ECP.hashtopoint(y)'


cat <<EOF | zexe left_array_from_hash.zen -a arr.json > left_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'left array'
Then print the 'left array'
EOF


cat <<EOF | zexe right_array_from_hash.zen -a arr.json > right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'right array'
Then print the 'right array'
EOF

# comparison

cat <<EOF | zexe array_comparison.zen -a left_arr.json -k right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'left array'
and I have a 'url64 array' named 'right array'
When I verify 'left array' is equal to 'right array'
Then print the string 'OK'
EOF

cat <<EOF | zexe array_remove_object.zen -a arr.json > right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I remove the 'random object' from 'bonnetjes'
and I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'right array'
Then print the 'right array'
EOF

# verify that arrays are not equal
cat <<EOF | zexe array_not_comparison.zen -a left_arr.json -k right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'left array'
and I have a 'url64 array' named 'right array'
When I verify 'left array' is not equal to 'right array'
Then print the string 'OK'
EOF


# 'x == ECP.hashtopoint(y)'

cat <<EOF > nesting.json
{
  "first" : { "inside" : "first.inside" },
  "second" : { "inside" : "second.inside" },
  "third" : "three"
}
EOF

cat <<EOF | zexe pick_nested.zen -a nesting.json
rule check version 1.0.0
rule input encoding string
Given I have a 'string' named 'inside' inside 'first'
and I have a 'string' named 'third'
When I write string 'first.inside' in 'test'
and I write string 'three' in 'tertiur'
and I verify 'third' is equal to 'tertiur'
Then print the 'test' as 'string'
EOF

cat <<EOF | zexe random_from_array.zen
rule check version 1.0.0
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
and the 'random object' is not found in 'array'
Then print the 'random object'
EOF

cat <<EOF | zexe leftmost_split.zen
rule check version 1.0.0
Given nothing
When I set 'whole' to 'Zenroom works great' as 'string'
and I split the leftmost '3' bytes of 'whole'
Then print the 'leftmost' as 'string'
and print the 'whole' as 'string'
EOF

cat <<EOF | zexe random_numbers.zen | tee array_random_nums.json
Given nothing
When I create the array of '64' random numbers
Then print the 'array' as 'number'
EOF


cat <<EOF | zexe random_numbers.zen | tee array_random_nums.json
Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array' as 'number'
and print the 'aggregation' as 'number'
EOF

# cat << EOF > array_public_bls.json
# { "public_keys": {
#  "Alice":{"reflow_public_key": "KrfEl2HFpml3di0N5vnrN+yrbSgiSClGBgz9zEmp2BihHOejIuOrTsOS573Fh6ciCxv6jI3syiF7mfGKUKXurUruj1kUtJfRpXHXa4d22LlioeB9uv+l14qhecrFojboOGrxZulFoDKVVWVCB0/bAD6HquSmvX4+jyPl/BLt6TUnNDLeWK8vm6zu9sR8/XFtKqEfCgQB4u0vbDhqOKhRNut8MjLtMcxYgWZTunmszNAZdAGMcYSod/0p1AzOnAUi"},
#  "Bob"  :{"reflow_public_key": "HA5WkWcTL0bJRRtjaTlW67SxTKBvuMniEOuao+jeuKA/2PT5965hvJgeDuTc2dHjGkCUzTjYhruOmY8puiF6s+8LRttJo17utYtsDNtNPNpaNdDSg8Dsg+wljGnqDUW8Jy29GQtuse2nqCOhGDzx9XC9pRCcu7hxAlIQsivpI2D9vXvi6BrVEniFG/kOrzzaUXXWNzBEuLhkwgvHcjLwC4Ph6ynrcsFIwEZycKuJKCaoOJu/ZQRT/nyfSf/Bom2k"}
# } }
# EOF

# cat <<EOF | debug array_schema.zen -a array_public_bls.json
# Scenario reflow
# Given I have a 'reflow public key array' named 'public keys'
# Then print all data
# EOF

cat << EOF > array_matches.json
{ "haystack": [ "Approved", "Not approved", "Approved", "Not approved", "Approved","Not approved", "Approved","Not approved", "Approved" ] }
EOF
cat << EOF > quorum.json
{ "quorum": 5,
  "needle": "Approved" }
EOF

cat << EOF | zexe needle_in_haystack.zen -a array_matches.json -k quorum.json
Given I have a 'string array' named 'haystack'
and I have a 'number' named 'quorum'
and I have a 'string' named 'needle'
When the 'needle' is found in 'haystack' at least 'quorum' times
Then Print the string 'Success' 
EOF

cat <<EOF >timestamp_stats.json
{
	"1": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://50.116.53.12:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787666",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "c633408f9d364740bec696456d5f1ae2",
		"version": "1"
	},
	"2": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://172.105.83.46:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787611",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "c1da19c60b7a4bf7a66f60825bec7a82",
		"version": "1"
	},
	"3": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://212.71.234.197:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787367",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "cc95dbf6a3d340fb95452f452a23aa40",
		"version": "1"
	},
	"4": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://192.46.209.107:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787754",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "3d0fa08a6d034d01a820ea05cbf93831",
		"version": "1"
	},
	"5": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://172.105.18.196:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787679",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "3794a7c3d1734dc8abcb57c82c972549",
		"version": "1"
	},
	"6": {
		"announce": "/api/consensusroom-announce",
		"baseUrl": "http://45.79.92.158:3300",
		"get-6-timestamps": "/api/consensusroom-get-6-timestamps",
		"myTimestamp": "1644878787692",
		"public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
		"timestampAPI": "/api/consensusroom-get-timestamp",
		"uid": "11e06cf7615a43f08ebd31c97e1ef9cb",
		"version": "1"
	},
        "non numero": "quarantadue"
}
EOF


cat <<EOF | zexe timestamp_stats.zen -a timestamp_stats.json
Given I have a 'string dictionary' named '1'
Given I have a 'string dictionary' named '2'
Given I have a 'string dictionary' named '3'
Given I have a 'string dictionary' named '4'
Given I have a 'string dictionary' named '5'
Given I have a 'string dictionary' named '6'

Given I have the 'string' named 'non numero'

When I create the copy of 'myTimestamp' from dictionary '1'
When I rename the 'copy' to 'time1'

When I create the copy of 'myTimestamp' from dictionary '2'
When I rename the 'copy' to 'time2'

When I create the copy of 'myTimestamp' from dictionary '3'
When I rename the 'copy' to 'time3'

When I create the copy of 'myTimestamp' from dictionary '4'
When I rename the 'copy' to 'time4'

When I create the copy of 'myTimestamp' from dictionary '5'
When I rename the 'copy' to 'time5'

When I create the copy of 'myTimestamp' from dictionary '6'
When I rename the 'copy' to 'time6'

# Insert timestamps in array to create average and variance

When I create the 'string array'
When I rename the 'string array' to 'allTimestamps'

When I insert 'time1' in 'allTimestamps'
When I insert 'time2' in 'allTimestamps'
When I insert 'time3' in 'allTimestamps'
When I insert 'time4' in 'allTimestamps'
When I insert 'time5' in 'allTimestamps'
When I insert 'time6' in 'allTimestamps'
# When I insert 'non numero' in 'allTimestamps'

When I create the average of elements in array 'allTimestamps'
When I create the variance of elements in array 'allTimestamps'
When I create the standard deviation of elements in array 'allTimestamps'

Then print the 'average'
Then print the 'variance'
Then print the 'standard deviation'
Then print the 'allTimestamps'
EOF

cat <<EOF > not_flat_array.json
{
"identities": [
	[
	     	"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	],
	[
		"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	],
	[
		"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	],
	[
		"https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
	]
]
}
EOF

cat <<EOF | zexe flat_array.zen -a not_flat_array.json | jq .
Rule check version 2.0.0
Given I have a 'string array' named 'identities'
When I create the flat array of contents in 'identities'
and I rename 'flat array' to 'contents flat array'
When I create the flat array of keys in 'identities'
and I rename 'flat array' to 'keys flat array'
Then print the 'keys flat array'
and print the 'contents flat array'
EOF

cat timestamp_stats.json | jq '{"timestamp": . }' > not_flat_dic.json

cat <<EOF | zexe flat_array_contents.zen -a not_flat_dic.json | jq .
Rule check version 2.0.0
Given I have a 'string dictionary' named 'timestamp'
When I create the flat array of contents in 'timestamp'
and I rename 'flat array' to 'contents flat array'
When I create the flat array of keys in 'timestamp'
and I rename 'flat array' to 'keys flat array'
Then print the 'keys flat array'
and print the 'contents flat array'
EOF

cat <<EOF > consensusroom-flatten.data
{
 "identities": [
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ],
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ],
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ],
  [
   "https://api/dyneorgroom.net/api/dyneorg/consensusroom-get-timestamp"
  ]
 ],
 "identity": {
  "uid": "random",
  "ip": "hostname -I",
  "baseUrl": "http://hostname -I",
  "port_http": "$PORT_HTTP",
  "port_https": "$PORT_HTTPS",
  "public_key": "BGiQeHz55rNc/k/iy7wLzR1jNcq/MOy8IyS6NBZ0kY3Z4sExlyFXcILcdmWDJZp8FyrILOC6eukLkRNt7Q5tzWU=",
  "version": "2",
  "announceAPI": "/api/consensusroom-announce",
  "get-6-timestampsAPI": "/api/consensusroom-get-6-timestamps",
  "timestampAPI": "/api/consensusroom-get-timestamp",
  "tracker": "https://apiroom.net/"
 }
}
EOF

cat <<EOF | zexe consensusroom-flatten.zen -a consensusroom-flatten.data
Given I have a 'string array' named 'identities'
Given I have a 'string dictionary' named 'identity'

When I create the flat array of contents in 'identities'
When I rename the 'flat array' to 'flattened array 1'

When I create the flat array of keys in 'identity'
When I rename the 'flat array' to 'flattened array 2'
And debug

Then print the 'flattened array 1'
Then print the 'flattened array 2'
Then print the string 'succes'
EOF


success
