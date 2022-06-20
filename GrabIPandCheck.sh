#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   printf "\n"
   printf "Syntax: scriptTemplate [-P|C|G|h|a]\n"
   printf "options:\n"
   printf "p     Specifies path to NGINX access.log. REQUIRED\n"
   printf "h     Print this Help.\n"
   printf "c     Enables sending IP's to cloudflare.\nIf enabled you must make a credential file with that title in the same directory as this script\nPlace the credentials in there like this\nCF_Token=YourCredential\nAccountID=YourAccountID\n"
   printf "g     Pass your Greynoise Community API key.\n"
   printf "a     Perform further analysis on the IP's that require further investigation.\n"
   printf " Example Command Usage ./GrabIPandCheck.sh -c -p /var/log/nginx/access.log -g YourAPIHere"
   printf " \n"
}
# Main program                                             #
############################################################
############################################################

# Set variables

# CF_Token= these are passed via credential file in same directory as the script
# AccountID= these are passed via credential file in same directory as the script
. "$(dirname "$0")"/credential
Cloudflare="false"
logpath="/var/log/nginx/access.log"
greynoise=""
analysis="false"
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hcp:g:a" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      c) # Set Cloudflare to true
         Cloudflare="true";;
      p) # Set path to logs
         logpath=$OPTARG;;
      g) # Set GreyNoise API
         greynoise=$OPTARG;;
      a) # Set analysis to true
         analysis="true";;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done
#### Get LIST ID Variable if cloudflare options used
if [[ "$Cloudflare" = "true" ]] && [[ "$ListID" = "" ]]; then
        echo "reading cloudflare creds from credential file and setting ListID variable"
ListID=$(curl -X GET "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
| jq '.result[] |.id' | tr -d '"')
elif [[ "$Cloudflare" = "true" ]] && [[ "$ListID" != "" ]]; then
        echo "LISTID was set within credential file."
else    echo "Cloudflare option wasn't selected."
fi

# scrub nginx access logs for either 404 responses to an attempt to access wp-login.php or 403 responses and outputs to txt file
echo "${logpath}"
cat $logpath | grep ' 404 '| sort -u | awk '{print $1}' > ~/Badip.txt && \
cat $logpath | grep ' 403 '| sort -u | awk '{print $1}' >> ~/Badip.txt
# reads ips from text file and checks them against greynoise community API with curl command
for ip in $(cat ~/Badip.txt | sort -u); do
noise=$(curl --request GET \
--url https://api.greynoise.io/v3/community/$ip \
--header 'Accept: application/json' \
--header 'key: '$greynoise | jq '. | .noise')
if [[ "$noise" = "true" ]] && [[ "$Cloudflare" = "true" ]]; then
            echo "${ip} is noise" >> ~/noisyip.txt && curl -X POST "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists/$ListID/items" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json" \
--data '[{"ip":"'$ip'","comment":"Noisy IP"}]'
elif [[ "$noise" = "true" ]] && [[ "$Cloudflare" = "false" ]]; then
            echo "${ip} is noise but it wasn't sent to Cloudflare" >> ~/noisyip.txt
else
            echo "${ip} may require further investigation" && echo "${ip}" >> ~/investigateip.txt

fi
done
if [[ "$analysis" = "true" ]]; then
            printf "Performing additional analysis.\nLooking for additional entries in access logs for each IP.\nSorting and providing an unique count.\nLook for output in longtail.txt within your home directory\n"
            printf " "
    for ip in $(cat ~/investigateip.txt | sort -u); do
    cat $logpath | grep $ip | awk '{print $1,$6,$7,$9}' >> ~/workinganalysis.txt && cat ~/workinganalysis.txt | tr -d '"' | sort| uniq -c | sort -n > ~/longtail.txt
done
else echo "Further analysis option was not selected"
fi