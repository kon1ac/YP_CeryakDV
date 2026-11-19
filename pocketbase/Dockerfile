FROM alpine:latest

ARG PB_VERSION=0.34.0

RUN apk add --no-cache unzip ca-certificates curl

ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ \
  && chmod +x /pb/pocketbase \
  && rm /tmp/pb.zip \
  && mkdir -p /pb/pb_data

ENV PB_ADMIN_EMAIL=pb-admin@hockey.local
ENV PB_ADMIN_PASSWORD=AdminPass123!
ENV RAILWAY_RUN_UID=0

EXPOSE 8080

# Railway injects PORT; volume must be mounted at /pb/pb_data.
CMD ["/bin/sh", "-c", "/pb/pocketbase superuser upsert \"$PB_ADMIN_EMAIL\" \"$PB_ADMIN_PASSWORD\" --dir=/pb/pb_data; exec /pb/pocketbase serve --http=0.0.0.0:${PORT:-8080} --dir=/pb/pb_data"]
