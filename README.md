# Introduction 
This repository is for scripts meant to assist in admin functions for Cloudflare WAF. 

# Getting Started

1.	UpdateIPList.sh
- This script will pull down a list of IP's from Emerging threat's IP block list URL. It will then extract the IP and CIDR ranges and print them to a new text file. It will then iterate over that list of ip's and CIDR ranges and perform curl's to do the following:
- Remove all previous IP's in cloudflare IP LIST. 
- Add new IP's to list.
- This should be run as a cron job daily
## Instructions
- create and get your Cloudflare API key
- Copy your Account ID
- Git clone this repo or copy the contents of UpdateIPList.sh
- Create a IP list in cloudflare and retrieve list ID by using following curl command
  - This script assumed you have 1 IP list. If you have more then 1, you will need to tailor this script to select the right listid and assign it to the listid variable
- Add your values to the variables in to the script
- perform `chmod +x UpdateIpList.sh`
- test by running `./UpdateIpList.sh`
- set cron job. 

2.GrabIPandCheck.sh
- This script will scrub nginx access logs for a 404 response to attempt to access wp-login page. It will also check for any 403 response and output the results of both of these to a file. It will then iterate over this file of Ip's and check each IP against the community API for Greynoise. If the API returns a value of "true" for the "noise" parameter, then this script will send that IP to cloudflare IP list for blocking. 
## Instructions
- You must pass this script a positional argument containing your grey noise API key
- You must save your Cloudflare Token inside the script(If you wish to replace this with a flag argument feel free. I may do so in the future so I can pass it from a secret vault)
- EX: ./GrabIPandCheck.sh 3473437473473437437
  - Where 3473437473473437437 equals your API key
- This should be run as a cron job daily


### Acknowledgements
- Thanks to the author of this blog for a bit of inspiration and guidance on interacting with cloudflare API.
  - https://www.xfelix.com/2021/10/simple-script-update-cloudflare-firewall-ip-list/

