FROM openjdk:8-jre-slim-buster

WORKDIR /opt

ENV HADOOP_VERSION=3.4.1
ENV HIVE_VERSION=3.1.3

RUN apt-get update && \
    apt-get install -y curl wget netcat procps net-tools iproute2 && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar zxf -

RUN curl -L https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz | tar zxf -

ENV HADOOP_HOME=/opt/hadoop-${HADOOP_VERSION}
ENV HIVE_HOME=/opt/apache-hive-${HIVE_VERSION}-bin
ENV PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

RUN mkdir -p /opt/hive/warehouse
RUN mkdir -p /opt/hive/tmp
RUN mkdir -p /tmp/hive/scratch
RUN chmod -R 777 /tmp/hive

COPY init-sh/hive-starter.sh /hive-starter.sh
RUN chmod +x /hive-starter.sh

ENTRYPOINT ["/hive-starter.sh"]