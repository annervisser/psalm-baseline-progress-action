FROM alpine
RUN apk add --no-cache libxml2-utils git gettext

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
