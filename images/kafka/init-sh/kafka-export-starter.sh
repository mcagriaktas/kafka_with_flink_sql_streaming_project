#!/bin/bash

sleep 15

echo "Starting Kafka Exporter..."
exec /opt/kafka_exporter/kafka_exporter \
  --kafka.server=kafka1:9092 --kafka.server=kafka2:9092 --kafka.server=kafka3:9092 \
  --web.listen-address=:9308 \
  --web.telemetry-path=/metrics \
  --topic.filter=.* \
  --group.filter=.* \
  --log.level=info