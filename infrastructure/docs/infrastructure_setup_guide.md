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
```bash
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
```bash
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
```
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

