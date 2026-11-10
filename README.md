# 🐘 DatabaseOps & Reliability Engineering Lab

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16--alpine-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker Compose](https://img.shields.io/badge/Docker_Compose-v2-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Prometheus](https://img.shields.io/badge/Prometheus-v2.51.0-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-10.4.0-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![Bash](https://img.shields.io/badge/Automation-Bash_Scripts-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Environment-Ubuntu_Linux-FCC624?logo=linux&logoColor=black)](https://ubuntu.com/)

A containerized, production-grade **Database Operations (DatabaseOps), Reliability, and Monitoring Lab**. Built on Ubuntu Linux with Docker Compose, this lab simulates real-world **Day-2 database administration (DBA)** and **Site Reliability Engineering (SRE)** practices: automated disaster recovery (DR) pipelines, non-destructive restore integrity validation, infrastructure and database engine telemetry, role-based access control (RBAC), query optimization (`EXPLAIN ANALYZE`), and post-mortem incident reporting.

---

## 📑 Table of Contents

- [Architectural Overview](#-architectural-overview)
- [Repository Structure](#-repository-structure)
- [Service Topology & Access Points](#-service-topology--access-points)
- [Database Schema & Security Architecture](#-database-schema--security-architecture)
- [Quick Start Guide](#-quick-start-guide)
- [Operational Runbooks](#-operational-runbooks)
  - [1. Automated Compressed Backups](#1-automated-compressed-backups)
  - [2. Non-Destructive Restore & Verification Pipeline](#2-non-destructive-restore--verification-pipeline)
  - [3. Automated Backup Scheduling via Cron](#3-automated-backup-scheduling-via-cron)
- [Observability & Monitoring Architecture](#-observability--monitoring-architecture)
  - [Prometheus Metrics Scraping](#prometheus-metrics-scraping)
  - [Grafana Dashboard Integration](#grafana-dashboard-integration)
- [Performance Tuning & Diagnostic Queries](#-performance-tuning--diagnostic-queries)
- [Incident Response & Post-Mortems](#-incident-response--post-mortems)
- [Maintenance & Teardown](#️-maintenance--teardown)

---

## 🏗️ Architectural Overview

```
                                  +-------------------------------------------------------+
                                  |                      DOCKER HOST                      |
                                  |                                                       |
  +--------------------+          |  +--------------------+       +--------------------+  |
  |  Database Admin /  |          |  |                    |       |  postgres-exporter |  |
  |   Bash Scripts     | -------->|  |   PostgreSQL 16    | <---- |     (Port 9187)    |  |
  |  (backup/restore)  |          |  |    (Port 5432)     |       +---------+----------+  |
  +--------------------+          |  |   • company_db     |                 |             |
                                  |  |   • company_db_    |                 |             |
                                  |  |     restored       |                 | (15s scrape)|
                                  |  +---------+----------+                 |             |
                                  |            | (Volume)                   v             |
                                  |            v                  +--------------------+  |
                                  |     postgres_data             |     Prometheus     |  |
                                  |                               |    (Port 9090)     |  |
                                  |  +--------------------+       +---------+----------+  |
                                  |  |   node-exporter    |                 |             |
                                  |  |    (Port 9100)     | ----------------+             |
                                  |  +--------------------+                 v             |
                                  |                               +--------------------+  |
                                  |                               |      Grafana       |  |
                                  |                               |    (Port 3000)     |  |
                                  |                               +--------------------+  |
                                  +-------------------------------------------------------+
```

### Core Architecture Highlights

1. **Isolation & Portability**: The entire stack operates inside isolated Docker containers connected over an internal bridge network with exposed host bindings for management.
2. **Resilience & Healthchecks**: PostgreSQL includes native `pg_isready` container healthchecks to ensure dependent services only query healthy database engines.
3. **Data Durability**: Independent named volumes (`postgres_data`, `prometheus_data`, `grafana_data`) protect state against container lifecycle restarts.
4. **Binary-Safe Pipeline**: Backup and restore scripts execute dump routines internally before transferring files across host boundaries via `docker cp`, eliminating stdout/TTY binary corruption risks.

---

## 📁 Repository Structure

```text
databaseops-labs/
├── docker-compose.yml              # 5-service orchestration: DB, exporters, metrics, UI
├── README.md                       # Comprehensive operational & architectural guide
├── backups/                        # Host directory for timestamped database dumps & logs
│   ├── backup.log                  # Execution and retention audit log
│   └── company_db_*.dump           # Custom-format compressed binary dumps
├── incidents/                      # SRE post-mortems and disaster simulation reports
│   └── incident-reports.md         # Documented outages, root causes, and resolutions
├── prometheus/                     # Metrics engine configuration
│   └── prometheus.yml              # Scrape targets (Postgres Exporter, Node Exporter)
├── scripts/                        # Production bash automation utilities
│   ├── backup.sh                   # Binary-safe dump generation & 7-day retention cleanup
│   └── restore.sh                  # Isolated database recreation & row-count validation
└── sql/                            # Database initialization, RBAC, and analytics
    ├── init.sql                    # Schema, relations, indexes, RBAC, and seed records
    └── queries.sql                 # Analytical aggregation, subqueries, and EXPLAIN ANALYZE
```

---

## 🌐 Service Topology & Access Points

| Service | Container Name | Internal Port | Host Port | Credentials / Target | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL 16** | `postgres_lab` | `5432` | `5432` | `postgres_admin` / `Password123` | Primary transactional relational database |
| **Prometheus** | `prometheus` | `9090` | `9090` | [http://localhost:9090](http://localhost:9090) | Time-series metrics engine & scraper |
| **Grafana** | `grafana` | `3000` | `3000` | `admin` / `admin` | Visualization & alerting dashboards |
| **Postgres Exporter** | `postgres_exporter` | `9187` | `9187` | [http://localhost:9187/metrics](http://localhost:9187/metrics) | PostgreSQL engine telemetry provider |
| **Node Exporter** | `node_exporter` | `9100` | `9100` | [http://localhost:9100/metrics](http://localhost:9100/metrics) | Host system/OS metrics (CPU, Memory, I/O) |

---

## 🛡️ Database Schema & Security Architecture

The database initialization (`sql/init.sql`) follows production-grade relational patterns and security best practices:

```
+--------------------+        +--------------------+        +--------------------+
|    departments     |        |     employees      |        |    transactions    |
+--------------------+        +--------------------+        +--------------------+
| department_id (PK) |<-------| department_id (FK) |        | transaction_id(PK) |
| department_name    |        | employee_id (PK)   |<-------| employee_id (FK)   |
| location           |        | first_name         |        | amount             |
| created_at         |        | last_name          |        | transaction_type   |
+--------------------+        | email (UNIQUE)     |        | transaction_date   |
                              | salary (CHECK > 0) |        +--------------------+
                              | hire_date          |
                              | created_at         |
                              +--------------------+
```

### Security & Access Control (Least Privilege)
- **Superuser (`postgres_admin`)**: Used exclusively for administrative operations, schema migrations, and backup utilities.
- **Application Role (`app_user`)**: Restricted role with `CONNECT` and `USAGE` on schema `public`, with standard DML permissions (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) on application tables and sequence privileges. Direct DDL permissions are explicitly withheld.

### Indexing Strategy
To avoid sequential scans (`Seq Scan`) as data volume scales, targeted B-tree indexes are implemented:
- `idx_employees_department`: Optimizes foreign key joins between `employees` and `departments`.
- `idx_transactions_employee`: Accelerates employee transaction history lookups (`ON DELETE CASCADE`).
- `idx_transactions_date`: Accelerates temporal filtering and financial reporting aggregations.

---

## 🚀 Quick Start Guide

### Prerequisites
- Docker Engine 24.0+ and Docker Compose v2+
- GNU Bash 5.0+ on Ubuntu / Debian / macOS
- `curl` (for health verification)

### 1. Launch the Stack
Start all services in detached mode:
```bash
docker compose up -d
```

### 2. Verify Container Health
Check that all containers are running and healthy:
```bash
docker compose ps
```
*Expected Output:*
```text
NAME                IMAGE                                           STATUS
grafana             grafana/grafana:10.4.0                          Up
node_exporter       quay.io/prometheus/node-exporter:v1.7.0         Up
postgres_exporter   prometheuscommunity/postgres-exporter:v0.15.0   Up
postgres_lab        postgres:16-alpine                              Up (healthy)
prometheus          prom/prometheus:v2.51.0                         Up
```

Verify Prometheus targets are scraped successfully:
```bash
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"[^"]*"'
# Output should return "health":"up" for all 3 targets
```

### 3. Connect to PostgreSQL
Access the database interactive shell (`psql`):
```bash
# As Administrator
docker exec -it postgres_lab psql -U postgres_admin -d company_db

# As Application User
docker exec -it postgres_lab psql -U app_user -d company_db
```

---

## 📦 Operational Runbooks

### 1. Automated Compressed Backups

The backup script (`scripts/backup.sh`) generates a custom compressed binary dump (`-F c`) directly inside the container to prevent any Linux/TTY character translation corruption, transfers it to the host `./backups/` directory, and applies a **7-day retention policy**.

```bash
# Execute backup
./scripts/backup.sh
```

**What the script performs:**
1. Creates local `./backups` directory if missing.
2. Executes `pg_dump -F c` inside `postgres_lab` to `/tmp/company_db_temp.dump`.
3. Safely transfers the binary file to `./backups/company_db_<TIMESTAMP>.dump` via `docker cp`.
4. Removes temporary container artifacts.
5. Logs execution timestamps, status, and pruned backup counts to `backups/backup.log`.
6. Enforces retention by deleting dumps older than 7 days using `find -mtime +7`.

---

### 2. Non-Destructive Restore & Verification Pipeline

Testing backups is the only way to guarantee disaster recovery readiness. The restore script (`scripts/restore.sh`) restores a dump into an **isolated sandbox database** (`company_db_restored`) without overwriting production data, followed by automated row-count assertions.

```bash
# Run restore verification
./scripts/restore.sh ./backups/company_db_<TIMESTAMP>.dump
```

**Verification Output:**
```text
Starting restoration from ./backups/company_db_20261110_105746.dump into target database 'company_db_restored'...
DROP DATABASE
CREATE DATABASE
Successfully copied 12.8kB (transferred 14.3kB) to postgres_lab:/tmp/restore_target.dump
SUCCESS: Database restored successfully to 'company_db_restored'.
Verifying row counts...
  table_name  | count 
--------------+-------
 departments  |     4
 employees    |     5
 transactions |     6
(3 rows)
```

---

### 3. Automated Backup Scheduling via Cron

To schedule daily backups at 02:00 AM on the host system:

```bash
# Open crontab editor
crontab -e

# Append scheduled job (adjust directory path to your project root)
0 2 * * * cd /home/thilina/projects/databaseops-labs && ./scripts/backup.sh >> ./backups/cron.log 2>&1
```

---

## 📈 Observability & Monitoring Architecture

### Prometheus Metrics Scraping
Prometheus scrapes the following targets every `15s` as defined in `prometheus/prometheus.yml`:
- **Postgres Exporter (`postgres-exporter:9187`)**:
  - `pg_stat_database_xact_commit` / `pg_stat_database_xact_rollback`: Transaction commit vs. rollback rates.
  - `pg_stat_activity_count`: Active, idle, and waiting client connections.
  - `pg_stat_database_blks_hit` / `pg_stat_database_blks_read`: Buffer cache hit ratio.
  - `pg_database_size_bytes`: Database storage growth over time.
- **Node Exporter (`node-exporter:9100`)**:
  - Host CPU utilization (`node_cpu_seconds_total`).
  - Available memory headroom (`node_memory_MemAvailable_bytes`).
  - Disk read/write throughput and storage saturation (`node_filesystem_free_bytes`).

### Grafana Dashboard Integration
1. Navigate to **[http://localhost:3000](http://localhost:3000)** (Login: `admin` / `admin`).
2. Add Prometheus as Data Source:
   - **URL:** `http://prometheus:9090`
   - Click **Save & Test**.
3. Import Recommended Community Dashboards:
   - **PostgreSQL Overview:** Dashboard ID `9628`
   - **Node Exporter Full:** Dashboard ID `1860`

---

## 🔍 Performance Tuning & Diagnostic Queries

Diagnostic and analytical queries are provided in `sql/queries.sql`:

### 1. Department Payroll & Headcount Analysis
Calculates aggregated payroll metrics using `LEFT JOIN` and `GROUP BY`:
```sql
SELECT 
    d.department_name,
    COUNT(e.employee_id) AS total_employees,
    SUM(e.salary) AS total_payroll,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY total_payroll DESC;
```

### 2. High-Earner Subquery
Identifies employees earning above their department average:
```sql
SELECT * 
FROM employees e
WHERE salary > (
    SELECT AVG(salary) 
    FROM employees 
    WHERE department_id = e.department_id
);
```

### 3. Execution Plan Inspection (`EXPLAIN ANALYZE`)
Validates that query execution uses indexed scans rather than full table sequential scans:
```sql
EXPLAIN ANALYZE
SELECT t.transaction_id, e.first_name, e.last_name, t.amount, t.transaction_date
FROM transactions t
JOIN employees e ON t.employee_id = e.employee_id
WHERE t.amount > 500.00;
```

### 4. Connection Pool & Activity Auditing
Monitors active queries and connection states:
```sql
SELECT datname, usename, client_addr, state, query 
FROM pg_stat_activity 
WHERE datname = 'company_db';
```

---

## 🚨 Incident Response & Post-Mortems

Practical SRE simulations and incident post-mortems are maintained in [`incidents/incident-reports.md`](incidents/incident-reports.md):

- **Incident 001 — Service Outage Simulation (Sev-1)**:
  - *Scenario*: Unplanned container termination (`docker compose stop postgres`).
  - *Detection*: Prometheus scrape failure alert; Grafana availability dropped to 0.
  - *Remediation*: Container restart (`docker compose start postgres`), healthcheck recovery, and reconnection audit.
- **Incident 002 — Query Performance Tuning (Sev-2)**:
  - *Scenario*: Full table scan (`Seq Scan`) overhead on high-volume transaction lookups.
  - *Detection*: Profiling query execution time with `EXPLAIN ANALYZE`.
  - *Remediation*: Verified B-tree index on foreign key (`employee_id`) and timestamp (`transaction_date`).

---

## 🛠️ Maintenance & Teardown

```bash
# Stop all services without deleting data
docker compose stop

# Restart services
docker compose start

# Tear down containers and networks (preserves volumes)
docker compose down

# Full reset: Remove containers, networks, and persistent data volumes
docker compose down -v
```

---

## 📜 Summary

This project showcases a complete lifecycle implementation of database administration, container operations, backup reliability, performance analysis, and infrastructure monitoring.
