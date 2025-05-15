FROM openjdk:17-slim-bullseye

RUN apt-get update && \
    apt-get install -y curl wget && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/kafka && \
    mkdir -p /opt/jmx_exporter && \
    mkdir /kafka && \
    mkdir /opt/kafka_exporter && \
    mkdir -p /data/kafka

RUN curl "https://archive.apache.org/dist/kafka/4.0.0/kafka_2.13-4.0.0.tgz" \
    -o /opt/kafka/kafka.tgz && \
    cd /kafka && \
    tar -xvzf /opt/kafka/kafka.tgz --strip 1 && \
    rm /opt/kafka/kafka.tgz

RUN wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.19.0/jmx_prometheus_javaagent-0.19.0.jar \
    -O /opt/jmx_exporter/jmx_prometheus_javaagent.jar

RUN wget https://github.com/danielqsj/kafka_exporter/releases/download/v1.9.0/kafka_exporter-1.9.0.linux-amd64.tar.gz \
    -O /opt/kafka_exporter/kafka_exporter.tar.gz && \
    cd /opt/kafka_exporter && \
    tar -xvzf kafka_exporter.tar.gz --strip 1 && \
    rm kafka_exporter.tar.gz

COPY init-sh/kafka-starter.sh /usr/bin
COPY init-sh/kafka-export-starter.sh /usr/bin/

RUN chmod +x /usr/bin/kafka-starter.sh /usr/bin/kafka-export-starter.sh

WORKDIR /kafka/bin

CMD ["kafka-starter.sh"]