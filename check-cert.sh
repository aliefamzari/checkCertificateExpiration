#!/bin/bash

#### Scripts to check certificate expiration. Scripts will run in crontab under user environment. Crontab is set to run this script twice daily at 12:00AM/PM GMT +8. In the event of certificate nearly expiring within 30 days, email will be send to the target recipient. An email also will be sent out to target recipient if certificate expired.

	# Author: Alif Amzari Mohd Azamee
	# Date: 19/12/2019
	# Version: 1.0
	# Job type: Cron
	
####

#### Global variables that can be change to your needs
target="example.com"  # target host
port=443 # target host port
recipient="youremail.com" # target recipient
days=30 # Threshold days
tmpPath="/tmp" # Temp folder path
####
echo "Checking $target certificate validity..."
echo 
# Certificate information (Subject, Issuer, Expiration)
certInfo=`openssl s_client -connect $target:$port 2>/dev/null |openssl x509 -text |grep 'Subject:\|Issuer:\|Not After'`  
#Current date from epoch in seconds 
currentDate=`date +%s` 
# Converting certificate "Not After" date into epoch date format
expirationDate=$(date -d "$(: |echo $certInfo |cut -d ':' -f3-5 |sed 's/Subject//')" '+%s')
#Get the remaining days before expired 
remainingDays=$((($expirationDate - $currentDate) / (24*3600)))
# Measuring current date + threshold days to get amber days
amberDays=$(($currentDate + (86400*$days)))

##Sending email to target recipient  if certificate will expire within the threshold days
if [ $amberDays -gt $expirationDate ]; then
	echo -e "WARNING - Certificate for $target expires in $remainingDays days, on $(date -d @$expirationDate '+%d %B %Y').\n" > $tmpPath/warningpayload.txt  # Outputting  warning certificate expiration message to a text file
	echo $certInfo | sed 's/Not/\nNot/; s/Sub/\nSub/' >> $tmpPath/warningpayload.txt  # Appending current certificate info to the same text file
	mail -s "Certificate expiration warning for $target" $recipient < $tmpPath/warningpayload.txt # Sending message to recipient from the text file
	else
		echo "OK - Certificate expires on $(date -d @$expirationDate '+%d %B %Y')"
fi

# Housekeeping warningpayload.txt
test -e $tmpPath/warningpayload.txt && rm $tmpPath/warningpayload.txt

##Sending email to target recipient if certificate has expired. 
if [ $currentDate -lt $expirationDate ]; then
	echo "Certificate valid"
	else
		echo -e "Certicate for $target has expired.\n" > $tmpPath/expiredpayload.txt 
		echo $certInfo | sed 's/Not/\nNot/; s/Sub/\nSub/' >> $tmpPath/expiredpayload.txt
		mail -s "Your certificate for $target has expired" $recipient < $tmpPath/expiredpayload.txt
fi
## 

# Housekeeping expiredpayload.txt
test -e $tmpPath/expiredpayload.txt && rm $tmpPath/expiredpayload.txt
