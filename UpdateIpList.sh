#!/bin/bash
 
## Cloudflare IP list update
. "$(dirname "$0")"/credential
# CF_Token= These are passed via the credential file that needs to be in same directory
# AccountID= These are passed via the credential file that needs to be in same directory
if [[ "$ListID" != "" ]]; then
echo "ListID was set within credential file."
else 
echo "setting ListID variable"
 ListID=$(curl -X GET "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
| jq '.result[] |.id' | tr -d '"')
fi

# Get New IPLIST from ET
curl https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt > /tmp/iplist.txt
egrep '[0-9]{1,3}(?:\.[0-9]{1,3}){0,3}/[0-9]+' /tmp/iplist.txt > /tmp/newlist.txt
rm /tmp/iplist.txt


#Clear old list

curl -X PUT "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists/$ListID/items" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
--data '[{"ip": "10.0.0.1","comment": "test ip"}]'
sleep 1

itemid=$(curl -X GET "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists/$ListID/items?" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
| jq '.result[] |.id')

curl -X DELETE "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists/$ListID/items" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
--data '{"items":[{"id":'$itemid'}]}'
sleep 1
 # update the list item
for IP in $(cat /tmp/newlist.txt); do
curl -X POST "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists/$ListID/items" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
--data '[{"ip":"'$IP'","comment":"ET IP"}]'
sleep 0.2
done