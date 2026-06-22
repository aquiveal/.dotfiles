---
description: Core architectural, stability, security, deployment, and production-readiness standards for distributed systems and microservices.
globs: *
---
# Architecture & Technology Standards

## 🎯 Core Directives

### 1. Stability & Resilience (Cynical Software)
- **Timeouts & Limits**: ALWAYS configure explicit connection/read timeouts for EVERY external integration, DB, and socket. NEVER use infinite blocking. Bound all resource pools and queues.
- **Circuit Breakers & Bulkheads**: ALWAYS wrap risky external calls in Circuit Breakers with fallback strategies (e.g., defensive caching). Isolate resources (Bulkheads) so one failure doesn't sink the system.
- **Demand Control**: ALWAYS implement Load Shedding (return HTTP 503) and Backpressure when capacity/SLA is exceeded. Keep TCP listen queues short.
- **Resource Cleanup**: ALWAYS isolate resource closures (e.g., `try-with-resources`) so one exception doesn't leak subsequent resources.
- **Dogpile Prevention**: ALWAYS add randomized jitter/slew to retries, cron jobs, and cache expirations.
- **Unbounded Results**: NEVER return unbounded result sets. ALWAYS enforce pagination and `LIMIT` clauses.
- **Session Bloat**: NEVER store large object graphs in memory sessions. Store only lightweight identifiers (e.g., User ID) and rely on cookies, not URL parameters.
- **Component Restarts**: Favor dynamic component-level restarts (via lifecycle hooks) over rolling cluster reboots during acute thread-exhaustion incidents.

### 2. Microservices & Architecture
- **Horizontal Scaling**: ALWAYS design for stateless horizontal scaling (concurrency & partitioning). NEVER rely on vertical scaling.
- **Loose Clustering**: ALWAYS use Service Discovery (Consul, etcd) and logical DNS/VIPs. NEVER hardcode physical IPs or hostnames. Instances must not statically know peers.
- **Decoupling**: ALWAYS prefer asynchronous decoupling (message queues, pub/sub) over synchronous RPC/HTTP where business logic permits.
- **Explicit Context (URL Dualism)**: ALWAYS use full URLs as identifiers in payloads instead of bare database IDs to prevent concept leakage and decouple authority.
- **Federated Data**: Reject the "Single System of Record" fallacy. Allow different bounded contexts to own their distinct facets of data.
- **Service Extinction**: ALWAYS delete unsuccessful/redundant services rather than merging them into complex monoliths.

### 3. Zero-Downtime Deployment & CI/CD
- **Immutable Infrastructure**: ALWAYS deploy via immutable images (Containers, AMIs). NEVER write scripts to patch or mutate running production instances (Convergence).
- **Deployinator**: ALWAYS automate deployments completely. NEVER use manual playbooks, SSH into production, or require "Go/No-Go" meetings.
- **Database Migrations (Relational)**: ALWAYS split into two phases: 1) **Expansion** (add tables/nullable columns/shims, backward-compatible) -> Code Rollout -> 2) **Contraction** (cleanup, strict constraints, `NOT NULL`). NEVER apply breaking schema changes synchronously.
- **Database Migrations (NoSQL)**: ALWAYS use "Trickle, then Batch" (migrate documents on-read in app code, batch cleanup later).
- **Asset Versioning**: ALWAYS version static web assets by embedding the hash in the filename/path (e.g., `/v1a2b3c/app.css`). NEVER use query strings for cache-busting.
- **Health Checks & Draining**: ALWAYS implement deep `/health` checks verifying dependencies. Toggle to 503 to gracefully drain traffic before shutdown. Wait for cache warm-up before passing.

### 4. API Evolution & Versioning
- **Postel's Law**: ALWAYS be conservative in what you send, liberal in what you accept.
- **Safe vs. Breaking**: Adding required fields, removing response fields, or tightening constraints are BREAKING changes. Adding optional inputs or new outputs are SAFE (Covariant/Contravariant).
- **Versioning**: ALWAYS implement breaking changes via explicit URL versioning (e.g., `/v2/`). Bump all routes simultaneously.
- **Controller Translation**: ALWAYS route old API versions through adapters to the current business logic. NEVER duplicate business logic.
- **Contract Testing**: ALWAYS split integration tests into outbound (spec compliance) and inbound (fuzzing/generative). NEVER rely on brittle end-to-end tests against live providers.

### 5. Security & Access Control
- **Injection**: ALWAYS use parameterized queries. NEVER concatenate strings for SQL/NoSQL. Disable XXE in XML parsers.
- **Session Management**: ALWAYS use high-entropy, PRNG-generated session IDs stored ONLY in `Secure`, `HttpOnly`, `SameSite=Strict` cookies. Regenerate IDs on login.
- **Access Control**: ALWAYS return `404 Not Found` instead of `403 Forbidden` for unauthorized access to obscure resource existence. Use random UUIDs, not sequential IDs.
- **XSS & CSRF**: ALWAYS scrub input and contextually escape output. Require anti-CSRF tokens for state-changing requests.
- **Least Privilege**: ALWAYS run processes as unprivileged users, disable OS core dumps, and vault all secrets (KMS/Vault). NEVER log PII or secrets.

### 6. Observability & Control Plane
- **Metrics & Logs**: ALWAYS inject Correlation/Trace IDs into logs. Log to stdout/external volume. Separate Host metrics (CPU/RAM) from Microservice metrics (RPS/Latency).
- **Actionable Alerts**: ALWAYS restrict `ERROR`/`SEVERE` logs to actionable system failures requiring operator intervention. Log user errors as `WARN`/`INFO`. Every alert MUST have a Runbook.
- **Governors**: ALWAYS implement "Governors" on automation scripts to hard-limit the blast radius of destructive actions (e.g., max 10% termination without human approval).
- **Admin APIs**: ALWAYS expose administrative APIs on private/internal NICs. NEVER implement "flush cache" or schema wipe commands in production APIs.

### 7. Chaos Engineering
- **Empirical Resilience**: ALWAYS validate resilience empirically via Chaos Engineering. Define a steady state, formulate an externally observable hypothesis, and limit the blast radius.
- **Fault Injection**: Use Instance Death for autoscaling tests, Latency Injection for race conditions, and Failure Injection Testing (FIT) via request tagging for downstream failures.

## 📝 Examples

### ✅ DO: Safe Resource Cleanup & Timeouts
```java
// Explicit timeouts and isolated cleanup via try-with-resources
HikariConfig config = new HikariConfig();
config.setConnectionTimeout(3000); // 3s timeout, no infinite blocking
HikariDataSource ds = new HikariDataSource(config);

try (Connection conn = ds.getConnection();
     PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users LIMIT 100")) {
    stmt.setQueryTimeout(5);
    ResultSet rs = stmt.executeQuery();
} catch (SQLException e) {
    log.error("Database integration failed", e);
    throw new ServiceDegradedException();
}
```

### ❌ DON'T: Unbounded Queries & Leaky Cleanup
```java
Connection conn = null;
Statement stmt = null;
try {
    conn = pool.getConnection(); // Blocks infinitely if pool exhausted
    stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM audit_logs"); // Unbounded result set (OOM risk)
} finally {
    if (stmt != null) stmt.close(); // If this throws, conn is leaked!
    if (conn != null) conn.close();
}
```

### ✅ DO: API Versioning via Controller Translation
```javascript
// V2 Controller (Current Business Logic)
async function createApplicationV2(req, res) {
    const result = await BusinessLogic.createApplication(req.body);
    res.json(result);
}

// V1 Controller (Adapter)
async function createApplicationV1(req, res) {
    // Translate V1 to V2 (provide defaults for new required fields)
    const v2Data = { ...req.body, newRequiredField: 'DEFAULT' };
    const result = await BusinessLogic.createApplication(v2Data);
    // Translate V2 back to V1 (strip new fields)
    res.json(mapToV1Response(result));
}
```

### ❌ DON'T: Breaking API Changes
```javascript
// Adding a required field to an existing endpoint breaks all current consumers
async function createApplicationV1(req, res) {
    if (!req.body.newRequiredField) {
        return res.status(400).send("Missing newRequiredField"); // BREAKS CONSUMERS
    }
}
```

### ✅ DO: Zero-Downtime Database Expansion
```sql
-- Phase 1: Expansion (Run before code deploy)
ALTER TABLE users ADD COLUMN first_name VARCHAR(255);
-- Shim to keep old code working
CREATE TRIGGER sync_names BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE FUNCTION split_full_name();

-- Phase 2: Contraction (Run AFTER 100% code deploy)
DROP TRIGGER sync_names ON users;
ALTER TABLE users DROP COLUMN full_name;
ALTER TABLE users ALTER COLUMN first_name SET NOT NULL;
```

### ❌ DON'T: Synchronous Breaking Schema Changes
```sql
-- Causes immediate downtime for running instances
ALTER TABLE users RENAME COLUMN full_name TO first_name;
ALTER TABLE users ADD COLUMN last_name VARCHAR(255) NOT NULL;