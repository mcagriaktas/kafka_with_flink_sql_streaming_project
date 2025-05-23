FROM openjdk:8-jre-slim-buster

WORKDIR /opt

ENV HADOOP_VERSION=3.4.1
ENV HADOOP_HOME=/opt/hadoop-${HADOOP_VERSION}
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV JAVA_HOME=/usr/local/openjdk-8

RUN apt-get update && \
    apt-get install -y curl openssh-server openssh-client procps && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar zxf -

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

RUN mkdir -p /opt/hadoop/dfs/name && \
    mkdir -p /opt/hadoop/dfs/data && \
    mkdir -p $HADOOP_HOME/logs && \
    chmod -R 777 /opt/hadoop && \
    chmod -R 777 $HADOOP_HOME/logs

COPY init-sh/hdfs-starter.sh /hdfs-starter.sh
RUN chmod +x /hdfs-starter.sh

ENTRYPOINT ["/hdfs-starter.sh"]