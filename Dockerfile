FROM alpine:3.11

COPY build/extensions/*.jar /etc/extensions/
COPY extensions.properties /etc/extensions/

CMD cp /etc/extensions/* /extensions/
