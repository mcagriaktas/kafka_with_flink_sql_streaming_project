#!/bin/bash
echo "Flink bas been installed..."
echo "Downloading Iceberg Depenciy Jars"
$FLINK_HOME/flink-iceberg-jar-dw.sh

echo "Flink is starting..."

if [ "$HOSTNAME" == "jobmanager" ]; then
    echo "Starting Flink $HOSTNAME"
    $FLINK_HOME/bin/$HOSTNAME.sh start-foreground &
    
    sleep 5

    echo "Starting Flink SQL Gateway"
    exec $FLINK_HOME/bin/sql-gateway.sh start-foreground
else
    echo "Starting Flink $HOSTNAME"
    exec $FLINK_HOME/bin/$HOSTNAME.sh start-foreground
fi