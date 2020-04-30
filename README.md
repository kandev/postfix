# Simple and clean mail server in docker container #
Assuming you have basic knowledge of *Docker Containers* and what they do. If not - please, go watch some online video presentation about that. Basically it's almost virtual machine, but not so bloated and resource hungry.

## Main features ##

* OpenDKIM signing
* IMAP with STARTTLS encryption
* SMTP with STARTTLS encryption
* Letsencrypt SSL certificate with autorenew
* Blacklists and SPF checks for spam filtering

## Installation ##
### Build from source ###
```
git clone https://github.com/kandev/postfix
cd postfix
docker-compose build
docker-compose up -d
```
Connecting to container:
```
docker exec -ti mail1 bash
```
### Get the latest image from Docker Hub ###
```
docker create -h mail1 --name mail1 --network dmz --ip 172.20.0.3 -v mail1_config:/var/config -v /volumes/mail1/domains:/var/mail/domains:rw -v /volumes/mail1/letsencrypt:/etc/letsencrypt:rw -v /etc/localtime:/etc/localtime:ro kandev/postfix:latest
docker start mail1
```
## DKIM Keys ##
DKIM key is automatically generated on image creation. Both private and publik keys are stored at **/var/config** directory.
Please use the content of **dkim_public.key** to create TXT records in all required DNS zones.
```
default._domainkey 14400 IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGS.....QAB"
```
If you want to create new key. Please use the following commands.
```
openssl genrsa -out /var/config/dkim_private.key 1024
openssl rsa -in /var/config/dkim_private.key -pubout | sed '1d;$d' | tr -d '\n' > /var/config/dkim_public.key
```
## Domains ##
All accepted domains are filled in **/var/config/postfix/mailbox_domains**.
```
example.com ok
example.net ok
example.org ok
```
Don't forget to run **postmap mailbox_domains** after update.
## Creating user accounts ##
### Mailbox map ###
All mailboxes should be listed in **/var/config/mailbox_maps**, using the following format:
```
ivan@example.com example.com/ivan/
petar@example.org example.org/petar/
```
Don't forget to run **postmap mailbox_maps** after update.

Specifyng SMTP address and mailbox directory where all the messages will be stored.
### User credentials ###
Access credentials are stored in **/var/config/users**
```
ivan@example.com:{CRAM-MD5}b1a3aca8da01c45eb94aa9e64d317d36785e7056b42t67e0ac1d6925ca1b11d7
```
Password is generated using **doveadm pw**.
## Address aliases ##
Aliases are created in **alias_maps**.
```
admin@example.com ivan@example.com
support@example.com ivan@example.com
```
Don't forget to run **postmap alias_maps** after update.

## Access control: blacklist, whitelist, archive ##
Addresses are listed in **sender_access** file as follows.
```
promocia.info     REJECT You suck but yo mama sweet
1.2.3.4           REJECT
4.3.2.1           OK
kiro@example.com  BCC gosho@corp.com
```
You can use full email addresses, domains, ip addresses of mail servers. Full list of actions can be seen [here](http://www.postfix.org/access.5.html).
And of course - don't forget to run **postmap sender_access** after editing.

## SSL Certificate ##
Initial creation of the certificate is manual.
```
certbot certonly --agree-tos -n --standalone -d mail.example.com
```
Daily cron job is running to automatically renew any expiring certificates.

## Mail client configuration ##
To enable autodiscovery of server configuration parameters, create file named **config-v1.1.xml** with the following example content:
```
<?xml version="1.0" encoding="UTF-8"?>

<clientConfig version="1.1">
  <emailProvider id="example.com">
    <domain>example.com</domain>
    <displayName>Example Corp Ltd.</displayName>
    <displayShortName>Example</displayShortName>
    <incomingServer type="imap">
      <hostname>mail.example.com</hostname>
      <port>143</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <outgoingServer type="smtp">
      <hostname>mail.example.com</hostname>
      <port>25</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
  </emailProvider>
</clientConfig>
```
Update your server name and domain, then upload this file to your web server where **example.com** web site is hosted, in the following path - **/.well-known/autoconfig/mail/**.

If for some reason the client application which you use can't find your server details, you should fill them manually.
* SMTP port 25, STARTTLS, plain text password
* IMAP port 143, STARTTLS, plain text password
* Supposedly you have already created DNS A record for the mail server itself - **mail.example.com**
* Don't worry about the *plain text*, the connection is secured by TLS.

## Tips ##
Here are some additional spices, which will make your mail service taste better :)
* Create SPF record in your DNS zone - https://www.spfwizard.net/
* Create DMARC record in your DNS zone - https://dmarcian.com/dmarc-record-wizard/
* Mail server automatic detection best practices - https://dmarcian.com/dmarc-record-wizard/
* Mail server diagnostics - https://mxtoolbox.com/diagnostic.aspx
