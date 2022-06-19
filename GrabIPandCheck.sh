#!/bin/bash
CF_Token=
AccountID=
ListID=$(curl -X GET "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
| jq '.result[] |.id' | tr -d '"')
# scrub nginx access logs for either 404 responses to an attempt to access wp-login.php or 403 responses and outputs to txt file
cat access.log | grep ' 404 '| sort -u | grep -i wp-login* | awk '{print $1}' > ~/sortingIP.txt && \
cat access.log | grep ' 403 '| sort -u | awk '{print $1}' >> ~/sortingIP.txt && \
cat ~/sortingIP.txt | sort -u > ~/Badip.txt && \
rm -f ~/sortingIP.txt

# reads ips from text file and checks them against greynoise community API with curl command
for ip in $(cat ~/Badip.txt); do
noise=$(curl --request GET \
--url https://api.greynoise.io/v3/community/$ip \
--header 'Accept: application/json' \
--header 'key: '$1 | jq '. | .noise')
if [[ "$noise" = "true" ]]; then
            echo "${ip} is noise" >> ~/noisyip.txt && curl -X POST "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists/$ListID/items" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
--data '[{"ip":"'$ip'","comment":"Noisy IP"}]'
else
            echo "${ip} may require further investigation" && echo "${ip}" >> ~/investigateip.txt
fi
done