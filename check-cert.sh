#!/bin/bash

#### Scripts to check certificate expiration. Scripts will run in crontab under user environment. Crontab is set to run this script twice daily at 12:00AM/PM GMT +8. In the event of certificate nearly expiring within 30 days, email will be send to the target recipient. An email also will be sent out to target recipient if certificate expired.

	# Author: Alif Amzari Mohd Azamee
	# Date: 19/12/2019
	# Version: 1.0
	
####

#### Global variables that can be change to your needs
TARGET="your.hostname.com"  # Target host
PORT=443 # Target host port
RECIPIENT="youremail.com" # Target recipient
DAYS=30 # Threshold days
TMPPATH="/tmp" # Temp folder path
####
echo "Checking $TARGET certificate validity..."
echo 
# Certificate information (Subject, Issuer, Expiration)
CERTINFO=`openssl s_client -connect $TARGET:$PORT 2>/dev/null |openssl x509 -text |grep 'Subject:\|Issuer:\|Not After'`  
# Current date from epoch in seconds 
CURRENTDATE=`date +%s` 
# Converting certificate "Not After" date into epoch date format
EXPIRATIONDATE=$(date -d "$(: |echo $CERTINFO |awk '{print $18,$19,$21}')" '+%s')
# Get the remaining days before expired 
REMAININGDAYS=$((($EXPIRATIONDATE - $CURRENTDATE) / (24*3600)))
# Measuring current date + threshold days to get amber days
AMBERDAYS=$(($CURRENTDATE + (86400*$DAYS)))

## 1-Sending email to target recipient  if certificate will expire within the threshold days
if [ $AMBERDAYS -gt $EXPIRATIONDATE ]; then
	echo -e "WARNING - Certificate for $TARGET expires in $REMAININGDAYS days, on $(date -d @$EXPIRATIONDATE '+%d %B %Y').\n" > $TMPPATH/warningpayload.txt  # Outputting  warning certificate expiration message to a text file
	echo $CERTINFO | sed 's/Not/\nNot/; s/Sub/\nSub/' >> $TMPPATH/warningpayload.txt  # Appending current certificate info to the same text file
	mail -s "Certificate expiration warning for $TARGET" $RECIPIENT < $TMPPATH/warningpayload.txt # Sending message to recipient from the text file
	else
	echo "OK - Certificate expires on $(date -d @$EXPIRATIONDATE '+%d %B %Y')"
fi
## 1

# Housekeeping warningpayload.txt
test -e $TMPPATH/warningpayload.txt && rm $TMPPATH/warningpayload.txt

## 2-Sending email to target recipient if certificate has expired. 
if [ $CURRENTDATE -lt $EXPIRATIONDATE ]; then
	echo "Certificate valid"
	else
	echo -e "Certicate for $TARGET has expired.\n" > $TMPPATH/expiredpayload.txt 
	echo $CERTINFO | sed 's/Not/\nNot/; s/Sub/\nSub/' >> $TMPPATH/expiredpayload.txt
	mail -s "Your certificate for $TARGET has expired" $RECIPIENT < $TMPPATH/expiredpayload.txt
fi
## 2

# Housekeeping expiredpayload.txt
test -e $TMPPATH/expiredpayload.txt && rm $TMPPATH/expiredpayload.txt