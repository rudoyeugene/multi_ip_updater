#!/bin/bash
set -e
PREV_IP=127.0.0.1
REPEAT_EVERY="${REPEAT_EVERY:=300s}"
HE_NET_ENABLED=true
NET_ASSIST_ENABLED=true
NEXT_DNS_ENABLED=true
ROUTE53_ENABLED=true

echo -e "Run period is set to $REPEAT_EVERY"

if [[ -z "$HE_NET_LOGIN" || -z "$HE_NET_PWD" || -z "$HE_NET_HOST" ]]; then
  echo -e "HE.Net update is not set"
  HE_NET_ENABLED=false
fi

if [[ -z "$NET_ASSIST_LOGIN" || -z "$NET_ASSIST_PWD" ]]; then
  echo -e "NetAssist update is not set"
  NET_ASSIST_ENABLED=false
fi

if [[ -z "$NEXT_DNS_PROFILE" || -z "$NEXT_DNS_UPDATE_ID" ]]; then
  echo -e "NextDNS update is not set"
  NEXT_DNS_ENABLED=false
fi

if [[ -z "$ROUTE53_DOMAIN" || -z "$ROUTE53_ZONE_ID" || -z "$ROUTE53_KEY_ID" || -z "$ROUTE53_KEY_SECRET" ]]; then
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
  curl -s https://link-ip.nextdns.io/$NEXT_DNS_PROFILE/$NEXT_DNS_UPDATE_ID -w "\n"
  echo -e "NextDNS update done"
}

prepare_aws_route53_changes () {
  echo -e "Preparing AWS Route 53 batch XML for $1"
  # Генерируем XML напрямую. Это надежнее для Route 53 API.
  cat <<EOF > batch.xml
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2013-04-01/">
<ChangeBatch>
    <Changes>
        <Change>
            <Action>UPSERT</Action>
            <ResourceRecordSet>
                <Name>$ROUTE53_DOMAIN</Name>
                <Type>A</Type>
                <TTL>300</TTL>
                <ResourceRecords>
                    <ResourceRecord>
                        <Value>$CURR_IP</Value>
                    </ResourceRecord>
                </ResourceRecords>
            </ResourceRecordSet>
        </Change>
    </Changes>
</ChangeBatch>
</ChangeResourceRecordSetsRequest>
EOF
}

update_aws_route53 () {
  echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  prepare_aws_route53_changes "$1"
  echo -e "Running Route53 update:"
  RESPONSE=$(awscurl --service route53 \
          --access_key "$ROUTE53_KEY_ID" \
          --secret_key "$ROUTE53_KEY_SECRET" \
          -X POST \
          -H "Content-Type: text/xml" \
          -d @batch.xml \
          "https://route53.amazonaws.com/2013-04-01/hostedzone/$ROUTE53_ZONE_ID/rrset")
  if echo "$RESPONSE" | grep -q "ErrorResponse"; then
      ERROR_MSG=$(echo "$RESPONSE" | sed -n 's/.*<Message>\(.*\)<\/Message>.*/\1/p')
      echo "Status: ERROR ($ERROR_MSG)"
  elif echo "$RESPONSE" | grep -qE "PENDING|INSYNC"; then
      echo "Status: OK"
  else
      echo "Status: ERROR (Unknown response format)"
  fi
  echo -e "Route53 update done"
  rm batch.xml
}

while true
do
  FORMATTED_DELAY=$(echo "$REPEAT_EVERY" | sed -E 's/([0-9]+)s/\1 seconds/; s/([0-9]+)m/\1 minutes/; s/([0-9]+)h/\1 hours/; s/([0-9]+)d/\1 days/')
  NEXT_RUN=$(date -d "+$FORMATTED_DELAY" +"%Y-%m-%d %H:%M:%S")
  echo -e "================================================================"
  echo -e "Update started at $(date)"
  echo -e "Next run at: $NEXT_RUN"
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
  sleep $REPEAT_EVERY
done
