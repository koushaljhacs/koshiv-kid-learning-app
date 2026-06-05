# Infrastructure Setup Guide

**Project:** koshiv - Learning App for Kids  
**Document Version:** 1.0.0.0.0  
**Author:** Koushal Jha, Docker Engineer  
**Email:** koushaljha.cs@gmail.com  
**Date:** Saturday, 6 June 2026  
**Branch:** infrastructure/docker-engineer  
**Status:** Production-Ready | Sprint 1 Complete  

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Architecture Overview](#2-architecture-overview)
3. [Environment Variables](#3-environment-variables)
4. [Port Mappings and IP Binding](#4-port-mappings-and-ip-binding)
5. [Volume and Network Design](#5-volume-and-network-design)
6. [How to Run](#6-how-to-run)
7. [How to Stop](#7-how-to-stop)
8. [Health Verification](#8-health-verification)
9. [Troubleshooting](#9-troubleshooting)
10. [Version History](#10-version-history)

---

## 1. Prerequisites

The following must be installed and configured on the development machine before starting the koshiv infrastructure stack.

### 1.1 Docker Engine

| Requirement | Minimum Version | Verified Version |
|-------------|-----------------|------------------|
| Docker Engine | 24.0.0 or higher | 27.5.1 |
| Docker Compose | v2.20.0 or higher (plugin) | v2.32.4 |

**Verification Command:**

docker --version
docker compose version
**Note:** Docker Compose standalone (docker-compose) is deprecated. The plugin variant (docker compose) is required.

### 1.2 Tailscale VPN

| Requirement | Details |
|-------------|---------|
| Tailscale Client | Installed and authenticated |
| Tailscale IP (Dev) | 100.81.13.80 (assigned to this machine) |
| Tailscale Status | Connected |

**Verification Command:**

tailscale status
tailscale ip
**Critical:** All service ports are bound exclusively to the Tailscale private IP `100.81.13.80`. If Tailscale is disconnected or the IP changes, the stack will fail to start or become unreachable.

### 1.3 Git

| Requirement | Details |
|-------------|---------|
| Git | 2.40.0 or higher |
| Repository | github.com/koushaljhacs/koshiv-kid-learning-app |
| Branch (Dev) | infrastructure/docker-engineer |

### 1.4 System Resources

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 2 GB free | 4 GB free |
| Disk Space | 5 GB free | 10 GB free |

The stack allocates up to 3.5 CPU cores and 2 GB memory across all three services. Ensure sufficient headroom on the host machine.

---


## 2. Architecture Overview

### 2.1 Services

The koshiv development infrastructure comprises three containerized services, all running on a shared isolated bridge network and accessible exclusively via Tailscale private IP.

| Service | Image | Purpose |
|---------|-------|---------|
| PostgreSQL 16 | `postgres:16-alpine` | Core relational database. Stores student profiles, learning progress, quiz results, and parent dashboards. |
| PgAdmin4 | `dpage/pgadmin4:latest` | Web-based GUI for PostgreSQL administration — schema browsing, query execution, user management. |
| Redis 7 | `redis:7-alpine` | In-memory cache and session store. Handles login sessions, API response caching, and rate limiting counters. |

### 2.2 Inter-Service Communication

All three services communicate over an isolated Docker bridge network named `koshiv_private_net`. The network is internal to the Docker host; no ports are exposed to the public internet.

**Communication Flow:**

- PgAdmin4 connects to PostgreSQL internally via container name `koshiv_postgres_16` on port `5432`
- Backend services (future) will connect to PostgreSQL and Redis via their container names
- Redis is accessed internally on its default port `6379` with password authentication

**Dependency Chain:**

PostgreSQL starts first. PgAdmin4 waits for PostgreSQL healthcheck to pass before starting (`depends_on: service_healthy`). Redis starts independently with no dependencies.

---

## 3. Environment Variables

### 3.1 Overview

The entire infrastructure stack is parameterized through a single `.env` file. No configuration values — IPs, ports, credentials, container names, resource limits — are hardcoded in `docker-compose.dev.yml`. This design enables:

- **Security compliance:** The compose file is safe for version control; credentials reside only in the gitignored `.env` file.
- **Environment portability:** Switching between development, staging, and production requires only swapping the `.env` file.
- **Auditability:** Every configurable parameter is documented in `.env.example` with its purpose clearly stated.

### 3.2 Setup

Copy the template and populate with actual values provided by the architecture team:

```bash
cp .env.example .env
Then edit `.env` with real credentials. The `.env` file is strictly gitignored and must never be committed.
```

### 3.3 Variable Categories

**Tailscale Network:**

| Variable | Purpose |
|----------|---------|
| `KOSHIV_TAILSCALE_IP` | Private Tailscale IP assigned to this machine — all services bind exclusively to this address |
| `KOSHIV_TAILSCALE_DEV_NETWORK_NAME` | Docker bridge network name for inter-service communication |

**PostgreSQL 16:**

| Variable | Purpose |
|----------|---------|
| `KOSHIV_POSTGRES_DEV_CONTAINER_NAME` | Container name for the PostgreSQL service |
| `KOSHIV_POSTGRES_DEV_RESTART_POLICY` | Restart behaviour — set to `unless-stopped` for auto-recovery |
| `KOSHIV_POSTGRES_DEV_USER` | Database user — assigned by Lead Architect |
| `KOSHIV_POSTGRES_DEV_PASSWORD` | Database password — must be wrapped in double quotes if containing special characters |
| `KOSHIV_POSTGRES_DEV_DB` | Default database name auto-created on first start |
| `KOSHIV_POSTGRES_DEV_PORT` | External host port mapped via Tailscale IP |
| `KOSHIV_POSTGRES_DEV_VOLUME_NAME` | Named volume for persistent database storage |
| `KOSHIV_POSTGRES_DEV_HEALTHCHECK_INTERVAL` | Time between health check attempts |
| `KOSHIV_POSTGRES_DEV_HEALTHCHECK_TIMEOUT` | Maximum wait for health check response |
| `KOSHIV_POSTGRES_DEV_HEALTHCHECK_RETRIES` | Consecutive failures before marking unhealthy |
| `KOSHIV_POSTGRES_DEV_HEALTHCHECK_START_PERIOD` | Grace period before health checks begin |
| `KOSHIV_POSTGRES_DEV_CPU_LIMIT` | Maximum CPU allocation |
| `KOSHIV_POSTGRES_DEV_MEMORY_LIMIT` | Maximum memory allocation |
| `KOSHIV_POSTGRES_DEV_CPU_RESERVATION` | Guaranteed CPU minimum |
| `KOSHIV_POSTGRES_DEV_MEMORY_RESERVATION` | Guaranteed memory minimum |

**PgAdmin4:**

| Variable | Purpose |
|----------|---------|
| `KOSHIV_PGADMIN_DEV_CONTAINER_NAME` | Container name for PgAdmin4 |
| `KOSHIV_PGADMIN_DEV_RESTART_POLICY` | Restart behaviour |
| `KOSHIV_PGADMIN_DEV_EMAIL` | Login email for PgAdmin4 web interface |
| `KOSHIV_PGADMIN_DEV_PASSWORD` | Login password — double quotes required for special characters |
| `KOSHIV_PGADMIN_DEV_PORT` | External host port mapped via Tailscale IP |
| `KOSHIV_PGADMIN_DEV_VOLUME_NAME` | Named volume for PgAdmin4 configuration and session data |
| `KOSHIV_PGADMIN_DEV_HEALTHCHECK_INTERVAL` | Time between health check attempts |
| `KOSHIV_PGADMIN_DEV_HEALTHCHECK_TIMEOUT` | Maximum wait for health check response |
| `KOSHIV_PGADMIN_DEV_HEALTHCHECK_RETRIES` | Consecutive failures before marking unhealthy |
| `KOSHIV_PGADMIN_DEV_HEALTHCHECK_START_PERIOD` | Grace period before health checks begin |
| `KOSHIV_PGADMIN_DEV_CPU_LIMIT` | Maximum CPU allocation |
| `KOSHIV_PGADMIN_DEV_MEMORY_LIMIT` | Maximum memory allocation |
| `KOSHIV_PGADMIN_DEV_CPU_RESERVATION` | Guaranteed CPU minimum |
| `KOSHIV_PGADMIN_DEV_MEMORY_RESERVATION` | Guaranteed memory minimum |

**Redis 7:**

| Variable | Purpose |
|----------|---------|
| `KOSHIV_REDIS_DEV_CONTAINER_NAME` | Container name for Redis |
| `KOSHIV_REDIS_DEV_RESTART_POLICY` | Restart behaviour |
| `KOSHIV_REDIS_DEV_PASSWORD` | Redis password — authentication mandatory even in development |
| `KOSHIV_REDIS_DEV_PORT` | External host port mapped via Tailscale IP |
| `KOSHIV_REDIS_DEV_INTERNAL_PORT` | Internal Redis port inside container |
| `KOSHIV_REDIS_DEV_AOF_FSYNC_POLICY` | AOF persistence fsync frequency — set to `everysec` |
| `KOSHIV_REDIS_DEV_MAXMEMORY` | Maximum memory before eviction triggers |
| `KOSHIV_REDIS_DEV_EVICTION_POLICY` | Key eviction strategy — `allkeys-lru` |
| `KOSHIV_REDIS_DEV_DATABASES` | Number of logical Redis databases |
| `KOSHIV_REDIS_DEV_TCP_BACKLOG` | TCP connection backlog queue size |
| `KOSHIV_REDIS_DEV_CLIENT_TIMEOUT` | Idle client connection timeout in seconds |
| `KOSHIV_REDIS_DEV_TCP_KEEPALIVE` | TCP keepalive interval in seconds |
| `KOSHIV_REDIS_DEV_VOLUME_NAME` | Named volume for AOF persistence file and RDB snapshots |
| `KOSHIV_REDIS_DEV_HEALTHCHECK_INTERVAL` | Time between health check attempts |
| `KOSHIV_REDIS_DEV_HEALTHCHECK_TIMEOUT` | Maximum wait for health check response |
| `KOSHIV_REDIS_DEV_HEALTHCHECK_RETRIES` | Consecutive failures before marking unhealthy |
| `KOSHIV_REDIS_DEV_HEALTHCHECK_START_PERIOD` | Grace period before health checks begin |
| `KOSHIV_REDIS_DEV_CPU_LIMIT` | Maximum CPU allocation |
| `KOSHIV_REDIS_DEV_MEMORY_LIMIT` | Maximum memory allocation |
| `KOSHIV_REDIS_DEV_CPU_RESERVATION` | Guaranteed CPU minimum |
| `KOSHIV_REDIS_DEV_MEMORY_RESERVATION` | Guaranteed memory minimum |

### 3.4 Critical: Special Characters in Passwords

Passwords containing special characters (`#`, `$`, `&`, `!`, etc.) must be wrapped in double quotes in the `.env` file:

```text
KOSHIV_POSTGRES_DEV_PASSWORD="koushaladmin#2026"
Without double quotes, the .env parser treats # as a comment marker and truncates the password, causing authentication failure. This is a common but critical configuration error.
```
## 4. Port Mappings and IP Binding

### 4.1 Design Rationale

Per the Sovereign Rulebook, no service binds to default ports or IP addresses. All services are bound exclusively to the Tailscale private IP `100.81.13.80` on custom high ports above 30000. This achieves:

- **Zero public exposure:** Even if the host firewall is misconfigured, services remain unreachable from the public internet because they listen only on the Tailscale virtual interface.
- **Default port scan immunity:** Automated scanners targeting standard ports (5432, 6379, 80, 5050) find no response.
- **N-Layer Firewall optimisation:** Sequential port allocation simplifies firewall rule writing — a single port range rule covers all koshiv services.

### 4.2 Port Allocation Table

| Service | Default Port (Blocked) | Internal Port | Custom Host Port | Full Binding |
|---------|------------------------|---------------|------------------|--------------|
| PostgreSQL | 5432 | 5432 | 34551 | `100.81.13.80:34551` |
| PgAdmin4 | 80 / 5050 | 80 | 34552 | `100.81.13.80:34552` |
| Redis | 6379 | 6379 | 34553 | `100.81.13.80:34553` |

### 4.3 Port Allocation Rationale

**Why sequential ports (34551, 34552, 34553)?**

- Firewall rule simplicity: A single IPTables rule covering range `34551-34553` secures all koshiv services.
- Cognitive load reduction: Developers and operators can easily recall port assignments without documentation lookup.
- Future extensibility: Ports `34554` through `34559` are reserved for upcoming services (backend API, AI processing engine, WebSocket gateway).

**Why above 30000?**

- Ports 0-1023 are privileged (require root).
- Ports 1024-49151 are registered; many are claimed by common applications.
- Ports 49152-65535 are ephemeral/dynamic; OS may randomly assign them.
- Ports 30000-45000 provide a safe, unclaimed range visible in firewall rules without conflicting with system processes.

### 4.4 Verifying Port Bindings

netstat -tlnp | grep 345
Expected output shows all three ports listening on 100.81.13.80 only — not on 0.0.0.0 or 127.0.0.1.

## 5. Volume and Network Design

### 5.1 Named Volumes

Persistent data is stored in Docker named volumes, decoupled from container lifecycles. If a container is removed and recreated, data survives.

| Volume Name | Mount Point (Inside Container) | Purpose |
|-------------|-------------------------------|---------|
| `koshiv_postgres_dev_data` | `/var/lib/postgresql/data` | PostgreSQL data directory — tables, indexes, WAL logs |
| `koshiv_pgadmin_dev_data` | `/var/lib/pgadmin` | PgAdmin4 user preferences, session data, saved queries |
| `koshiv_redis_dev_data` | `/data` | Redis AOF persistence file and RDB snapshots |

**Driver:** All volumes use the `local` driver — data resides on the host filesystem under Docker's default volume directory.

**Important:** Volume names are sourced from environment variables. The top-level keys in `docker-compose.dev.yml` are static (`postgres_koshiv_vol`, `pgadmin_koshiv_vol`, `redis_koshiv_vol`) for Docker Compose parser compatibility. Actual volume names come from the `name:` attribute.

### 5.2 Read-Only Mounts

Two directories are mounted as read-only (`:ro`) for security:
| Host Path | Container Mount | Purpose |
|-----------|-----------------|---------|
| `../../database_layer/postgres_schema` | `/docker-entrypoint-initdb.d` | SQL init scripts auto-executed on first container start. Read-only prevents runtime modification. |
| `../../database_layer/pgadmin_setup/servers.json` | `/pgadmin4/servers.json` | Pre-configured PostgreSQL server connection for PgAdmin4. Read-only ensures consistent admin access. |

### 5.3 Network Architecture

**Network Name:** `koshiv_private_net` (from `KOSHIV_TAILSCALE_DEV_NETWORK_NAME`)

**Driver:** `bridge` — standard Docker bridge network providing automatic DNS resolution between containers.

**Key Properties:**

- Containers resolve each other by container name (e.g., `koshiv_postgres_16`, `koshiv_redis_7`).
- The network is isolated — only containers explicitly attached can communicate.
- No ports are exposed to the host machine's LAN or public internet. External access is exclusively via the Tailscale virtual interface on the specified custom ports.

**Note:** The top-level network key in the compose file is static (`koshiv_bridge_net`) for parser compatibility. The actual network name comes from the `name:` attribute sourced from the environment variable.

---

## 6. How to Run

### 6.1 Prerequisites Check

Before starting, verify all prerequisites are met. Run these commands and confirm output matches expected values:

docker --version
docker compose version
tailscale status
git status

### 6.2 Clone and Prepare

If starting from a fresh machine:

git clone https://github.com/koushaljhacs/koshiv-kid-learning-app.git
cd koshiv-kid-learning-app
git checkout infrastructure/docker-engineer
### 6.3 Environment Configuration

Navigate to the compose directory and set up the environment file:

cd infrastructure/docker_compose
cp .env.example .env
Edit `.env` with actual credentials provided by the Lead Architect. Verify the password for special characters is wrapped in double quotes.
KOSHIV_POSTGRES_DEV_PASSWORD="koushaladmin#2026"

### 6.4 Start the Stack

docker compose -f docker-compose.dev.yml --env-file .env up -d
The -d flag runs containers in detached mode (background).

### 6.5 Expected Output

[+] up 38/38
 ✔ Network koshiv_private_net      Created
 ✔ Volume koshiv_redis_dev_data    Created
 ✔ Volume koshiv_postgres_dev_data Created
 ✔ Volume koshiv_pgadmin_dev_data  Created
 ✔ Container koshiv_postgres_16    Healthy
 ✔ Container koshiv_redis_7        Created
 ✔ Container koshiv_pgadmin4       Created

 ## 7. How to Stop

### 7.1 Stop All Services

To stop all containers while preserving data volumes:

docker compose -f docker-compose.dev.yml down
This stops and removes containers but retains volumes. Data persists for the next up.

7.2 Stop and Remove Volumes
To stop containers and permanently delete all data:
docker compose -f docker-compose.dev.yml down -v

Warning: The -v flag destroys all named volumes. All database records, PgAdmin4 configurations, and Redis cache data will be irretrievably lost. Use only for complete environment reset.

7.3 Stop Individual Service
docker compose -f docker-compose.dev.yml stop redis_koshiv_dev

7.4 Restart All Services
docker compose -f docker-compose.dev.yml restart

## 8. Health Verification

### 8.1 Check Container Status

docker compose -f docker-compose.dev.yml ps
All three containers must show Up under STATUS and healthy in the health check column.

Expected Output:
NAME                 IMAGE                   STATUS
koshiv_pgadmin4      dpage/pgadmin4:latest   Up (healthy)
koshiv_postgres_16   postgres:16-alpine      Up (healthy)
koshiv_redis_7       redis:7-alpine          Up (healthy)

8.2 PostgreSQL Verification
docker exec -it koshiv_postgres_16 psql -U koushaladmin -d koshiv_kla -c "SELECT version();"

Should return PostgreSQL 16 version information and confirm the koshiv_kla database is accessible.

8.3 Redis Verification
docker exec -it koshiv_redis_7 redis-cli -a "koushaladmin#2026" ping
Should return PONG.

8.4 PgAdmin4 Verification
Open browser at http://100.81.13.80:34552. Login with the admin email and password defined in .env.

## 9. Troubleshooting

### 9.1 PostgreSQL Container Fails to Start

**Symptom:** `koshiv_postgres_16` shows `Exited` or keeps restarting.
**Possible Causes and Resolutions:**

**Cause 1: Port already in use.**

docker compose -f docker-compose.dev.yml logs postgres_koshiv_dev | grep "address already in use"
Resolution: Identify the process using port 34551 and terminate it:

netstat -ano | findstr :34551
taskkill /PID <PID> /F

**Cause 2: Password contains special character but missing double quotes in `.env`.**

**Symptom:** `FATAL: password authentication failed` in logs.

docker compose -f docker-compose.dev.yml logs postgres_koshiv_dev | grep "FATAL"
Resolution: Open .env and verify password is wrapped in double quotes:
KOSHIV_POSTGRES_DEV_PASSWORD="koushaladmin#2026"
Then restart:

docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml --env-file .env up -d

**Cause 3: Tailscale disconnected or IP changed.**

**Symptom:** `Error starting userland proxy: listen tcp 100.81.13.80:34551: bind: cannot assign requested address`

**Resolution:** Verify Tailscale status:

tailscale status
tailscale ip

If IP differs from 100.81.13.80, update KOSHIV_TAILSCALE_IP in .env to match the current Tailscale IP, then restart.

### 9.2 PgAdmin4 Fails to Start or Stays Unhealthy

**Symptom:** `koshiv_pgadmin4` shows `unhealthy` or `starting` indefinitely.

**Cause 1:** PostgreSQL not healthy before PgAdmin4 attempts connection.

**Resolution:** PgAdmin4 uses `depends_on: service_healthy`. Wait for PostgreSQL to show `healthy` in `docker compose ps`. PgAdmin4 will start automatically once the dependency is satisfied.

**Cause 2:** PgAdmin4 port conflict.

netstat -ano | findstr :34552

Resolution: Terminate the conflicting process or change KOSHIV_PGADMIN_DEV_PORT in .env.

Cause 3: servers.json file missing or invalid.
docker compose -f docker-compose.dev.yml logs pgadmin4_koshiv_dev | grep "servers.json"

Resolution: Ensure /database_layer/pgadmin_setup/servers.json exists at the path relative to the compose file (../../database_layer/pgadmin_setup/servers.json).


### 9.3 Redis Fails to Start or Authentication Fails

**Symptom:** `koshiv_redis_7` shows `Exited` or `NOAUTH Authentication required` errors.

**Cause 1:** Password contains special character but missing double quotes in `.env`.

**Resolution:** Same as PostgreSQL password fix — ensure `KOSHIV_REDIS_DEV_PASSWORD` is wrapped in double quotes:

KOSHIV_REDIS_DEV_PASSWORD="koushaladmin#2026"

**Cause 2:** AOF file corruption from improper shutdown.

**Symptom:** `Bad file format reading the append only file` in logs.

**Resolution:** Remove the corrupted AOF file and restart:

docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml --env-file .env up -d

Note: The -v flag deletes the Redis volume. All cached data will be lost. In development this is acceptable; in production, follow the Redis AOF repair procedure (redis-check-aof --fix).

**Cause 3:** Memory limit too low.

**Symptom:** `OOM command not allowed when used memory > 'maxmemory'` in logs.

**Resolution:** Increase `KOSHIV_REDIS_DEV_MAXMEMORY` in `.env` (current: 256MB) or reduce cache usage. Restart after the change:

docker compose -f docker-compose.dev.yml restart redis_koshiv_dev
### 9.4 Cannot Connect from Host Machine

**Symptom:** `Connection refused` when connecting from host to any service port.

**Resolution:** Verify Tailscale IP binding is correct:

netstat -tlnp | grep 100.81.13.80
## 10. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0.0.0 | 06 June 2026 | Koushal Jha | Initial infrastructure setup guide — covers Prerequisites, Architecture, Environment Variables, Port Mappings, Volume/Network Design, Run/Stop commands, Health Verification, and Troubleshooting for all three services |

---

**Document Maintained By:** Koushal Jha, Docker Engineer  
**Repository:** github.com/koushaljhacs/koshiv-kid-learning-app  
**Branch:** infrastructure/docker-engineer  
**File Path:** infrastructure/docs/infrastructure_setup_guide.md

---