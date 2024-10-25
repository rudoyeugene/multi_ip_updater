FROM alpine:latest
RUN apk add --update --no-cache curl jq bash
RUN apk add aws-cli --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/
COPY ipupdater.sh /
RUN chmod +x ipupdater.sh
CMD [ "/ipupdater.sh" ]
