# monitoring-stack
Stack of monitoring and alerting software

## Setup
In Linux or WSL2
```
# Install Docker

# Setup docker network
sudo docker network create monitoring

# Docker commands
docker compose up
docker compose down
docker compose up -d
docker compose up --build --force-recreate -d
docker compose down -v

docker stop $(sudo docker ps -q)
docker rm -f $(sudo docker ps -a -q)
docker image prune -a

docker logs <container name>
```

## Grafana (Visualization Platform)
- https://hub.docker.com/r/grafana/grafana/tags
```
grafana-cli plugins install marcusolsson-json-datasource
```

## Prometheus (Metrics Database)
- https://hub.docker.com/r/prom/prometheus/tags

## Alloy (System Collector)
- https://grafana.com/docs/alloy/latest/
- https://hub.docker.com/r/grafana/alloy/tags
- https://github.com/jkroepke/grafana-alloy/tree/main
- Community Forum: https://community.grafana.com/c/grafana-alloy/69
This also utilizes node exporter.  

## Loki - (Logs Database)
- https://grafana.com/docs/loki/latest/setup/install/docker/
- https://hub.docker.com/r/grafana/loki/tags

## Tempo (Traces Database)
- https://hub.docker.com/r/grafana/tempo/tags

## Beyla (Application Collector)

## Faro (Client Side Collector)

## Nginx
- https://hub.docker.com/_/nginx/tags

# Metrics collection
For System Metrics from Node Exporter:
Try these queries. They should now return data:

CPU Usage: node_cpu_seconds_total{job="node_exporter_metrics"} (then maybe add mode="idle" for idle CPU, or sum by mode for total usage)
Memory Usage: node_memory_MemFree_bytes{job="node_exporter_metrics"} (or node_memory_MemAvailable_bytes for better insight)
Disk Space: node_filesystem_avail_bytes{job="node_exporter_metrics"} (you may need to add device or mountpoint="/rootfs" labels to filter)
Network Activity: node_network_receive_bytes_total{job="node_exporter_metrics"} (look at instance or device labels)

# Notes
Consider using Ansible for deploying collectors to hosts.