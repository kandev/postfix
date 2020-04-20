# Simple and clean mail server #

## Main features ##

* OpenDKIM signing
* IMAP with STARTTLS encryption
* SMTP with STARTTLS encryption
* Letsencrypt SSL certificat with autorenew
* Blacklists for spam filtering
## DKIM Keys ##
DKIM key is automatically generated on image creation. Both private and publik keys are stored at **/var/config** directory.
Please use the content of **dkim_public.key** to create TXT records in all required DNS zones.
```
default._domainkey 14400 IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGS.....QAB"
```
If you want to create new key. Please use the following commands.
```
openssl genrsa -out /var/config/dkim_private.key 1024
openssl rsa -in dkim_private.key -pubout | sed '1d;$d' | tr -d '\n' > /var/config/dkim_public.key
```
## Domains ##
All accepted domains are filled in **/var/config/postfix/mailbox_domains**.
```
example.com ok
example.net ok
example.org ok
```
Don't forget *postmap mailbox_domains*
## Creating user accounts ##
### Mailbox map ###
All mailboxes should be listed in **/var/config/mailbox_maps**, using the following format:
```
ivan@example.com example.com/ivan/
petar@example.org example.org/petar/
```
Don't forget *postmap mailbox_maps*

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
Don't forget *postmap alias_maps*
## SSL Certificate ##
Initial creation of the certificate is manual.
```
certbot certonly --agree-tos -n --standalone -d mail.example.com
```
Daily cron job is running to automatically renew any expiring certificates.
