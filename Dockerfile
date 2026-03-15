FROM alpine:3.21
RUN apk add --update --no-cache curl jq bash aws-cli
COPY ipupdater.sh /
RUN chmod +x ipupdater.sh
CMD [ "/ipupdater.sh" ]
