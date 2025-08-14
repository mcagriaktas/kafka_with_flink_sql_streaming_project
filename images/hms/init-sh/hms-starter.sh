#!/bin/bash

export HADOOP_HOME=/opt/hadoop-3.4.1
export JAVA_HOME=/usr/local/openjdk-17
export HMS_HOME=/opt/apache-hive-metastore-3.0.0-bin

echo "Waiting for namenode to be available..."
while ! nc -z namenode 9000; do
    sleep 1
done
echo "Namenode is available!"

$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse
$HADOOP_HOME/bin/hdfs dfs -chmod g+w /user/hive/warehouse
$HADOOP_HOME/bin/hdfs dfs -chmod -R 777 /user/hive/warehouse

echo "Initializing Metastore schema..."
$HMS_HOME/bin/schematool -initSchema -dbType derby

sleep 5

echo "Starting Hive Metastore Service..."
$HMS_HOME/bin/start-metastore