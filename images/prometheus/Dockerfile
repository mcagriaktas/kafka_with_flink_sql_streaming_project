FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    wget curl \
    && rm -rf /var/lib/apt/lists/*

ENV PROMETHEUS_VERSION=2.45.0

RUN wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && tar xvfz prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz \
    && mv prometheus-${PROMETHEUS_VERSION}.linux-amd64 /prometheus \
    && rm prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

WORKDIR /prometheus

COPY init-sh/prometheus-starter.sh /usr/bin/prometheus-starter.sh
RUN chmod +x /usr/bin/prometheus-starter.sh

EXPOSE 9090

CMD ["/usr/bin/prometheus-starter.sh"]