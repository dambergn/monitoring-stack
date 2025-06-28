#!/bin/bash

## TODO - Update to provide list of what to restart.

# Restart Grafana
cd grafana
docker compose down
docker compose up -d
cd ..

# Restart Prometheus
cd prometheus
docker compose down
docker compose up -d
cd ..

# Restart Alloy
cd alloy
docker compose down
docker compose up -d
cd ..

# Restart Loki
cd loki
docker compose down
docker compose up -d
cd ..

echo "*** Restart Complete ***"