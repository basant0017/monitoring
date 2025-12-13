# Nginx Configuration for Monitoring Stack

## Overview

Nginx serves as a reverse proxy for all monitoring services, providing:
- Single entry point for all services
- Rate limiting and security headers
- Load balancing (if multiple instances)
- SSL/TLS termination (when configured)

## Configuration Files

- `nginx.conf`: Main Nginx configuration
- `conf.d/monitoring.conf.template`: Reverse proxy configuration (uses env substitution)

## Access Points

With Nginx, you can access services via:

- **Grafana**: http://localhost/ or http://localhost/grafana
- **Prometheus**: http://prometheus.localhost/ (or via direct port 19090)
- **Loki**: http://loki.localhost/ (or via direct port 13100)

## Environment Variables

Set in `monitoring.env`:
- `NGINX_PORT`: HTTP port (default: 80)
- `NGINX_HTTPS_PORT`: HTTPS port (default: 443)
- `NGINX_DOMAIN`: Domain name for server_name (default: localhost)

## SSL/TLS Configuration

To enable HTTPS:

1. Place SSL certificates in `monitoring/nginx/ssl/`:
   - `cert.pem` (certificate)
   - `key.pem` (private key)

2. Update `conf.d/monitoring.conf.template` to add SSL server blocks

3. Set `NGINX_HTTPS_PORT` in `monitoring.env`

## Health Check

Nginx health check endpoint: `http://localhost/nginx-health`

## Rate Limiting

- Grafana: 5 requests/second (burst: 10)
- API endpoints: 10 requests/second (burst: 20)

## Logs

Nginx logs are stored in the `nginx_logs` Docker volume and can be accessed via:
```bash
docker exec monitoring_nginx tail -f /var/log/nginx/access.log
docker exec monitoring_nginx tail -f /var/log/nginx/error.log
```

## Troubleshooting

1. **Check Nginx configuration**:
   ```bash
   docker exec monitoring_nginx nginx -t
   ```

2. **View Nginx logs**:
   ```bash
   docker logs monitoring_nginx
   ```

3. **Reload Nginx** (if config changed):
   ```bash
   docker exec monitoring_nginx nginx -s reload
   ```

4. **Test connectivity**:
   ```bash
   curl http://localhost/nginx-health
   ```

