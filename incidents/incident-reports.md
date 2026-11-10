# DatabaseOps Incident Reports

## Incident 001: Unexpected Database Service Outage
- **Date:** 2026-11-10
- **Severity:** High
- **Symptom:** Prometheus metrics indicated PostgreSQL availability dropped to 0; applications unable to connect.
- **Investigation:** 
  - Checked container status via `docker compose ps` and confirmed the `postgres` service was stopped.
  - Inspected logs using `docker compose logs postgres`.
- **Root Cause:** Intentional service stop simulation for operational testing.
- **Resolution:** Restarted the container using `docker compose start postgres` and verified health check recovery.

---

## Incident 002: Query Performance Investigation
- **Date:** 2026-11-10
- **Severity:** Medium
- **Symptom:** Routine query execution check on the `transactions` table.
- **Investigation:** 
  - Executed `EXPLAIN ANALYZE` on queries filtering by transaction amount.
  - Observed whether the planner utilized sequential scans versus index scans.
- **Resolution:** Verified that proper indexing on foreign keys and timestamps maintains optimal execution paths.