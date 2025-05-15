#!/bin/bash

sleep 15 

exec ./prometheus \
  --config.file=/etc/prometheus/prometheus.yaml \
  --storage.tsdb.path=/prometheus/data \
  --web.enable-lifecycle \
  --web.enable-admin-api \
  --web.enable-remote-write-receiver \
  --enable-feature=remote-write-receiver


