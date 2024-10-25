# multi_ip_updater
A simple Docker App that publishes into several sources current Public IP of the Environment where it runs.

### The very simple docker compose file:
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
      - ROUTE53_DOMAIN=your.server.url. # your Route53 url incl dot
      - ROUTE53_ZONE_ID=AAABBB... # your Route53 DNS Zone ID
      - ROUTE53_KEY_ID=AKIA... # your User Secret Key Id
      - ROUTE53_KEY_SECRET=aaabbb... # your User Key Secret Key
      # he.net
      - HE_NET_LOGIN=login # your He.Net login
      - HE_NET_PWD=password  # your He.Net password
      - HE_NET_HOST=111000  # your He.Net host id
      # Net.Assist
      - NET_ASSIST_LOGIN=login # your Net Assist login
      - NET_ASSIST_PWD=password # your Net Assist password
      # NextDNS
      - NEXT_DNS_PROFILE=111000 # your NextDNS device id
      - NEXT_DNS_UPDATE_ID=111000222 # your NextDNS update unique id
```

### AWS Route 53 required policy
Before you can do Route 53 updates you must create a User in IAM with proper permissions:
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