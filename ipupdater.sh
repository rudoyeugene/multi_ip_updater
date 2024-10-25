#!/bin/bash
set -e
PREV_IP=127.0.0.1
UPDATE_DELAY="${UPDATE_DELAY:=300}"
HE_NET_ENABLED=true
NET_ASSIST_ENABLED=true
NEXT_DNS_ENABLED=true
ROUTE53_ENABLED=true

echo -e "Update delay is set to $UPDATE_DELAY seconds"

if [[ -z "$HE_NET_LOGIN" && -z "$HE_NET_PWD" && -z "$HE_NET_HOST" ]]; then
  echo -e "HE.Net update is not set"
  HE_NET_ENABLED=false
fi

if [[ -z "$NET_ASSIST_LOGIN" && -z "$HE_NET_PWD" && -z "$HE_NET_HOST" ]]; then
  echo -e "NetAssist update is not set"
  NET_ASSIST_ENABLED=false
fi

if [[ -z "$NEXT_DNS_PROFILE" && -z "$NEXT_DNS_UPDATE_ID" ]]; then
  echo -e "NextDNS update is not set"
  NEXT_DNS_ENABLED=false
fi

if [[ -z "$ROUTE53_DOMAIN" && -z "$ROUTE53_ZONE_ID" && -z "$ROUTE53_KEY_ID" && -z "$ROUTE53_KEY_SECRET" ]]; then
  echo -e "AWS Route 53 update is not set"
  ROUTE53_ENABLED=false
fi

update_he_net () {
  echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  echo -e "Running HE.Net update:"
  curl -s https://$HE_NET_LOGIN:$HE_NET_PWD@ipv4.tunnelbroker.net/nic/update?hostname=$HE_NET_HOST
  echo -e "HE.Net update done"
}

update_net_assist () {
  echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  echo -e "Running NetAssist update:"
  curl -s https://tb.netassist.ua/autochangeip.php?l=$NET_ASSIST_LOGIN\&p=$NET_ASSIST_PWD\&ip=$CURR_IP
  echo -e "NetAssist update done"
}

update_next_dns () {
  echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  echo -e "Running NextDNS update:"
  curl -s https://link-ip.nextdns.io/$NEXT_DNS_PROFILE/$NEXT_DNS_UPDATE_ID
  echo -e "NextDNS update done"
}

prepeare_aws_route53_changes () {
  echo -e "Preparing AWS Route 53 batch file for $1"
  jq -n --arg ROUTE53_DOMAIN "$ROUTE53_DOMAIN" --arg CURR_IP "$CURR_IP" '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":$ROUTE53_DOMAIN,"Type":"A","TTL":300,"ResourceRecords":[{"Value":$CURR_IP}]}}]}' > batch.json
}

update_aws_route53 () {
  echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  prepeare_aws_route53_changes "$1"
  echo -e "Running Route53 update:"
  AWS_ACCESS_KEY_ID=$ROUTE53_KEY_ID AWS_SECRET_ACCESS_KEY=$ROUTE53_KEY_SECRET aws route53 change-resource-record-sets \
  --hosted-zone-id $ROUTE53_ZONE_ID \
  --change-batch file://batch.json --output=text
  echo -e "Route53 update done"
}

while true
do
  echo -e "================================================================"
  echo -e "Update started at $(date)"
  CURR_IP=$(curl -s https://api.myip.com | jq -r .ip)
  if [ "$PREV_IP" = "$CURR_IP" ]; then
    echo -e "IPs the same, skipping all updates"
  else
    echo -e "Previous IP: $PREV_IP"
    echo -e "Current IP:  $CURR_IP"

    if [ "$HE_NET_ENABLED" = "true" ]; then
      update_he_net
    fi

    if [ "$NEXT_DNS_ENABLED" = "true" ]; then
      update_next_dns
    fi

    if [ "$NET_ASSIST_ENABLED" = "true" ]; then
      update_net_assist "$CURR_IP"
    fi

    if [ "$ROUTE53_ENABLED" = "true" ]; then
      update_aws_route53 "$CURR_IP"
    fi
  fi
  PREV_IP=$CURR_IP
  sleep $UPDATE_DELAY
done
