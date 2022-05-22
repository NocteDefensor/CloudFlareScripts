# Introduction 
This repository is for scripts meant to assist in admin functions for Cloudflare WAF. 

# Getting Started

1.	UpdateIPList.sh
    - This script will pull down a list of IP's from Emerging threat's IP block list URL. It will then extract the IP and CIDR ranges and print them to a new text file. It will then iterate over that list of ip's and CIDR ranges and perform curl's to do the following:
      - Remove all previous IP's in cloudflare IP LIST. 
      - Add new IP's to list.
    - This should be run as a cron job daily
    - Instructions
      - create and get your Cloudflare API key
      - Copy your Account ID
      - Git clone this repo or copy the contents of UpdateIPList.sh
      - Create a IP list in cloudflare and retrieve list ID by using following curl command
```
CF_Token=YourAPIToken
AccountID=YourAccountID
curl -X GET "https://api.cloudflare.com/client/v4/accounts/$AccountID/rules/lists" \
-H "Authorization: Bearer $CF_Token" \
-H "Content-Type:application/json"
```
      - Add your values to the variables in to the script
      - perform `chmod +x UpdateIpList.sh`
      - test by running `./UpdateIpList.sh`
      - set cron job. 

