FROM alpine:3.23
RUN apk add --update --no-cache coreutils bash curl jq python3 py3-pip
RUN pip install --no-cache-dir awscurl --break-system-packages
COPY entrypoint.sh /
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]