FROM openjdk:21-slim-bullseye

ENV JENKINS_HOME=/opt/jenkins
ENV JENKINS_VERSION=2.506
ENV KAFKA_VERSION=4.0.0
ENV FLINK_VERSION=2.0.0
ENV SCALA_VERSION=2.12

RUN apt-get update && \
    apt-get install -y \
    curl wget git openssh-client unzip \
    ca-certificates \
    sshpass \
    fontconfig libfreetype6 libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${JENKINS_HOME}/.ssh && \
    echo "StrictHostKeyChecking no" > ${JENKINS_HOME}/.ssh/config && \
    chmod 600 ${JENKINS_HOME}/.ssh/config

RUN mkdir -p /opt/kafka && \
    curl "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz" \
    -o /opt/kafka/kafka.tgz && \
    mkdir -p /opt/kafka/bin && \
    tar -xvzf /opt/kafka/kafka.tgz -C /opt/kafka --strip-components=1 && \
    rm /opt/kafka/kafka.tgz

RUN wget -P /opt https://downloads.apache.org/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz && \
    tar -xzf /opt/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz -C /opt/ && \
    rm /opt/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz && \
    mv /opt/flink-${FLINK_VERSION} /opt/flink && \
    mkdir /opt/flink/catalog

RUN mkdir -p /usr/share/jenkins ${JENKINS_HOME} ${JENKINS_HOME}/init.groovy.d ${JENKINS_HOME}/groovys \
    ${JENKINS_HOME}/groovys_base /opt/flink/sql-files /opt/flink/jobs

RUN curl -fL https://get.jenkins.io/war/${JENKINS_VERSION}/jenkins.war -o /usr/share/jenkins/jenkins.war || \
    curl -fL https://get.jenkins.io/war-stable/${JENKINS_VERSION}/jenkins.war -o /usr/share/jenkins/jenkins.war && \
    chmod 644 /usr/share/jenkins/jenkins.war

COPY init-sh/jenkins-starter.sh /usr/local/bin/
COPY init-sh/groovy/00-init-jobs.groovy ${JENKINS_HOME}/init.groovy.d/00-init-jobs.groovy
COPY init-sh/groovys_base ${JENKINS_HOME}/groovys_base
COPY init-sh/execute-flink-sql.sh /opt/jenkins/execute-flink-sql.sh
RUN chmod +x /usr/local/bin/jenkins-starter.sh /opt/jenkins/execute-flink-sql.sh

WORKDIR $JENKINS_HOME

ENTRYPOINT ["/usr/local/bin/jenkins-starter.sh"]