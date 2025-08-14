#!/bin/bash

export HADOOP_HOME=/opt/hadoop-3.4.1
export JAVA_HOME=/usr/local/openjdk-17
export PATH=$PATH:$HADOOP_HOME/bin

mkdir -p $HADOOP_HOME/logs
mkdir -p /opt/hadoop/dfs/name
mkdir -p /opt/hadoop/dfs/data

service ssh start

sleep 5

if [ "$HOSTNAME" = "namenode" ]; then
    echo "Starting namenode..."
    if [ ! -f /opt/hadoop/dfs/name/current/VERSION ]; then
        echo "Formatting namenode..."
        hdfs namenode -format -force
    fi
    hdfs --daemon start namenode
    echo "Namenode started!"
fi

if [ "$HOSTNAME" = "datanode" ]; then
    echo "Starting datanode..."
    hdfs --daemon start datanode
    echo "Datanode started!"
fi

tail -f $HADOOP_HOME/logs/*