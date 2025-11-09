# Monitoring Stack

This repository contains a Prometheus + Loki + Grafana stack (with node-exporter, cAdvisor, Promtail, and optional web-server exporters) that you can run locally via Docker Compose.

## Quick start

```bash
docker compose -f docker-compose.monitoring.yml --env-file monitoring.env up -d
```

Grafana will be available on `http://localhost:3200` (login: `admin` / password from `monitoring.env`).

## On-boarding additional servers

1. **Deploy the remote agent**  
   Copy the contents of `agents/` to the target server and set:
   ```bash
   export AGENT_NAME=myserver
   export AGENT_HOSTNAME=myserver.example.com
   export LOKI_URL=http://<central-monitoring-host>:13100/loki/api/v1/push
   docker compose -f agents/docker-compose.monitoring-agent.yml up -d
   ```
   This launches node-exporter (9100/tcp), cAdvisor (8080/tcp) and Promtail (shipping logs, including PM2 logs if present).

2. **Expose the exporters**  
   Ensure the central Prometheus host can reach the agent’s node-exporter (`9100`) and cAdvisor (`8080`). Adjust firewalls or use VPN/mTLS as needed.

3. **Register the new targets**  
   On the central stack, edit the files in `monitoring/targets/` and append the server endpoints, e.g.:
   ```yaml
   # monitoring/targets/node-exporter.yml
   - labels:
       environment: production
     targets:
       - node-exporter:9100          # local stack
       - myserver.example.com:9100   # remote
   ```

4. **Reload the stack**
   ```bash
   docker compose -f docker-compose.monitoring.yml --env-file monitoring.env up -d
   ```
   Prometheus will pick up the new `file_sd` targets automatically.

5. **Grafana**  
   The home dashboard includes variables for jobs, containers, and log sources. Once the remote exporters are scraped, they appear automatically. Use the “Log Job” filter to select `pm2-logs` or other log streams forwarded by Promtail.

## Optional exporters

- `nginx-exporter` and `apache-exporter` are available behind the `optional` profile:
  ```bash
  docker compose -f docker-compose.monitoring.yml --env-file monitoring.env --profile optional up -d
  ```
  Update `monitoring/targets/nginx-exporter.yml` / `apache-exporter.yml` with any remote instances you ship metrics for.

## Configuration layout

```
monitoring/
├── grafana/
│   ├── dashboards/            # JSON dashboards (home overview, Loki overview, etc.)
│   ├── datasources/           # Grafana datasource provisioning
│   └── preferences/           # Grafana org preferences (home dashboard)
├── prometheus.yml             # Base Prometheus configuration (includes file_sd job definitions)
├── targets/                   # Append remote scrape targets per job
│   ├── node-exporter.yml
│   ├── cadvisor.yml
│   └── ...
├── promtail.yml               # Central Promtail configuration (Docker + PM2 logs)
└── ipmi-config.yml            # Placeholder for future IPMI exporter usage
```

Use the `agents/` directory as a template for remote hosts. Customize labels (e.g. `environment`, `role`) to match your topology and the Grafana filters you want. Update the dashboards as needed to leverage new labels or exporters. 
