FROM openjdk:17-slim-bullseye

# Set Flink version (https://downloads.apache.org/flink/)
ENV FLINK_VERSION=1.20.0
ENV SCALA_VERSION=2.12
ENV HIVE_VERSION=3.1.3
ENV HADOOP_VERSION=3.4.1
ENV METASTORE_VERSION=3.0.0

RUN apt-get update && \
    apt-get install -y wget curl netcat procps net-tools iputils-ping && \
    rm -rf /var/lib/apt/lists/*

# Flink Binary 
RUN wget -P /opt https://downloads.apache.org/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz && \
    tar -xzf /opt/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz -C /opt/ && \
    rm /opt/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz && \
    mv /opt/flink-${FLINK_VERSION} /opt/flink && \
    mkdir /opt/flink/catalog

# Flink Stream and SQL
RUN wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-streaming-java/${FLINK_VERSION}/flink-streaming-java-${FLINK_VERSION}.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-sql-client/${FLINK_VERSION}/flink-sql-client-${FLINK_VERSION}.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-sql-gateway/${FLINK_VERSION}/flink-sql-gateway-${FLINK_VERSION}.jar -P /opt/flink/opt/ && \ 
    wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-connector-base/${FLINK_VERSION}/flink-connector-base-${FLINK_VERSION}.jar -P /opt/flink/lib/

# Flink Prometheus Connector and system metrics dependencies
RUN wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-metrics-prometheus/${FLINK_VERSION}/flink-metrics-prometheus-${FLINK_VERSION}.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/com/github/oshi/oshi-core/6.4.4/oshi-core-6.4.4.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/net/java/dev/jna/jna/5.13.0/jna-5.13.0.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/net/java/dev/jna/jna-platform/5.13.0/jna-platform-5.13.0.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-metrics-jmx/1.20.0/flink-metrics-jmx-1.20.0.jar -P /opt/flink/lib/

# RocksDB state backend
RUN wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-statebackend-rocksdb/${FLINK_VERSION}/flink-statebackend-rocksdb-${FLINK_VERSION}.jar -P /opt/flink/lib/

# Flink Kafka Connectors (FLINK 2.0)
# RUN wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/4.0.0-2.0/flink-sql-connector-kafka-4.0.0-2.0.jar -P /opt/flink/lib/ && \
#     wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/4.0.0-2.0/flink-connector-kafka-4.0.0-2.0.jar -P /opt/flink/lib/ && \
#     wget -q https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/4.0.0/kafka-clients-4.0.0.jar -P /opt/flink/lib && \
#     wget -q https://repo1.maven.org/maven2/com/google/guava/guava/33.4.8-jre/guava-33.4.8-jre.jar -P /opt/flink/lib 

# Flink Kafka Connectors (FLINK 1.20.0)
RUN wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.4.0-1.20/flink-sql-connector-kafka-3.4.0-1.20.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka/3.4.0-1.20/flink-connector-kafka-3.4.0-1.20.jar -P /opt/flink/lib/ && \
    wget -q https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/4.0.0/kafka-clients-4.0.0.jar -P /opt/flink/lib && \
    wget -q https://repo1.maven.org/maven2/com/google/guava/guava/33.4.8-jre/guava-33.4.8-jre.jar -P /opt/flink/lib 

RUN mkdir -p /opt/flink/flink-state/flink-checkpoints && \
    mkdir -p /opt/flink/flink-state/flink-savepoints && \
    mkdir -p /opt/flink/sql_query_list && \
    chmod 777 -R /opt/flink

ENV FLINK_HOME=/opt/flink
ENV HADOOP_CONF_DIR=/opt/flink/conf
ENV HIVE_CONF_DIR=/opt/flink/conf
ENV PATH=$PATH:$FLINK_HOME/bin
    
RUN chmod 777 -R /opt/flink
WORKDIR $FLINK_HOME

COPY init-sh/flink-iceberg-jar-dw.sh ./flink-iceberg-jar-dw.sh
RUN chmod +x ./flink-iceberg-jar-dw.sh

COPY init-sh/flink-starter.sh ./flink-starter.sh
RUN chmod +x ./flink-starter.sh

ENTRYPOINT ["./flink-starter.sh"]