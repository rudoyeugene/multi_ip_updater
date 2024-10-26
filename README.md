# Multi IP Updtaer
A simple Docker based App that updates several DNS/IPv6 Broker Services with Your current Public IP of the Environment where it runs.

E.g.: 
- You have a Home Router
- Your ISP assigns it a real Public IP
- This IP can be dynamic
- You want to keep your Services like DNS name of Your Home constantly up-to-date automatically

## Supported Services:
### IPv6 Tunnel Brokers:
- [Hurricane Electric Free IPv6 Tunnel Broker](https://tunnelbroker.net/)
- [NetAssist :: IPv6 Tunnel Broker](https://tb.netassist.ua/)
### DNS Services:
- [AWS Route 53](https://aws.amazon.com/ru/route53/) *
- [NextDNS](https://nextdns.io/)

## Docker compose example:
- Each Service must have full set of environment variables to enable it.
```yaml
services:
  ipupdater:
    image: rudoyeugene/playground:ipupdater
    container_name: ipupdater
    pull_policy: always
    restart: always
    environment:
      - UPDATE_DELAY=300 # we will run the script every 5 minutes
      # AWS Route 53
      - ROUTE53_DOMAIN=your.server.url. # your Route 53 url incl dot
      - ROUTE53_ZONE_ID=AAABBB... # your Route 53 DNS Zone ID
      - ROUTE53_KEY_ID=AKIA... # your IAM User Secret Key Id
      - ROUTE53_KEY_SECRET=aaabbb... # your IAM User Key Secret Key
      # he.net
      - HE_NET_LOGIN=login # your HE.Net login
      - HE_NET_PWD=password  # your HE.Net password
      - HE_NET_HOST=111000  # your HE.Net host id
      # Net.Assist
      - NET_ASSIST_LOGIN=login # your Net Assist login
      - NET_ASSIST_PWD=password # your Net Assist password
      # NextDNS
      - NEXT_DNS_PROFILE=111000 # your NextDNS device id
      - NEXT_DNS_UPDATE_ID=111000222 # your NextDNS update unique id
```

### * AWS Route 53 policy:
- You need to create IAM User with the following policy to be able to update Route 53 record:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "route53:TestDNSAnswer",
                "route53:GetHostedZone",
                "route53:ListHostedZones",
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
```

#### Services addition:

If You want to add another Service please create an Issues with all the details of the Service.
