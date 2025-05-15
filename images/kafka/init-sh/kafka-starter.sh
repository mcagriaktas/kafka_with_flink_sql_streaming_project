#!/bin/bash

export KAFKA_OPTS="-javaagent:/opt/jmx_exporter/jmx_prometheus_javaagent.jar=7071:/opt/jmx_exporter/kafka-metrics.yml"

/kafka/bin/kafka-storage.sh format --config /kafka/config/server.properties --cluster-id 'EP6hyiddQNW5FPrAvR9kWw' --ignore-formatted

if [[ $HOSTNAME == "kafka1" ]]; then
    /usr/bin/kafka-export-starter.sh &
fi

exec /kafka/bin/kafka-server-start.sh /kafka/config/server.properties