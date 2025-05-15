#!/bin/bash
set -e

sleep 30 

echo "Starting Grafana initialization..."

mkdir -p /var/lib/grafana \
         /var/log/grafana \
         /etc/grafana/provisioning/dashboards/json \
         /etc/grafana/provisioning/datasources \
         /etc/grafana/provisioning/dashboards/provider \
         /etc/grafana/provisioning/alerting \
         /etc/grafana/provisioning/notifiers \
         /etc/grafana/provisioning/plugins

chown -R root:root /var/lib/grafana /var/log/grafana /etc/grafana

echo "Checking for dashboards..."
find /etc/grafana/provisioning/dashboards/json -type f -name "*.json" | while read file; do
  echo "Processing dashboard: $file"
  
  temp_file=$(mktemp)
  
  sed 's/"datasource"[ ]*:[ ]*"[0-9]*"/"datasource": {"type": "prometheus", "uid": "prometheus"}/g' "$file" > "$temp_file"
  
  sed -i 's/"datasource"[ ]*:[ ]*"Prometheus"/"datasource": {"type": "prometheus", "uid": "prometheus"}/g' "$temp_file"
  
  sed -i 's/"datasource"[ ]*:[ ]*"${DS_PROMETHEUS}"/"datasource": {"type": "prometheus", "uid": "prometheus"}/g' "$temp_file"
  sed -i 's/"uid"[ ]*:[ ]*"${DS_PROMETHEUS}"/"uid": "prometheus"/g' "$temp_file"

  sed -i 's/"datasource"[ ]*:[ ]*{[ ]*"type"[ ]*:[ ]*"prometheus"[ ]*,[ ]*"uid"[ ]*:[ ]*"${DS_PROMETHEUS}"[ ]*}/"datasource": {"type": "prometheus", "uid": "prometheus"}/g' "$temp_file"
  
  cat "$temp_file" > "$file"
  rm -f "$temp_file"
  
  echo "Updated datasource references in $file"
done

if [ -n "$GF_INSTALL_PLUGINS" ]; then
  echo "Installing Grafana plugins: $GF_INSTALL_PLUGINS"
  IFS=',' read -ra plugins <<< "$GF_INSTALL_PLUGINS"
  for plugin in "${plugins[@]}"; do
    grafana-cli plugins install "$plugin" || echo "Failed to install plugin: $plugin"
  done
fi

echo "Starting Grafana server as root..."
export GF_PATHS_DATA=/var/lib/grafana
export GF_PATHS_LOGS=/var/log/grafana
export GF_PATHS_PLUGINS=/var/lib/grafana/plugins

exec grafana-server \
  --homepath=/usr/share/grafana \
  --config=/etc/grafana/grafana.ini \
  --packaging=docker \
  cfg:allow_using_current_user_from_config=true \
  "$@"