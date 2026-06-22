---
description: Comprehensive Data Architecture, Modeling, and Information Strategy Rules
globs: *.*
---
# Data Architecture and Strategy Standards

## 🎯 Directives

### 1. Data Modeling & Schema Design (Relational & Dimensional)
- ALWAYS separate intrinsic identity (`PARTY`, `PERSON`, `ORGANIZATION`) from contextual roles (`CUSTOMER`, `EMPLOYEE`). Use `PARTY_RELATIONSHIP` for interactions.
- ALWAYS decouple marketing offerings (`PRODUCT`) from physical inventory (`PART`, `INVENTORY_ITEM`).
- ALWAYS unify Sales and Purchase transactions under a generic `ORDER` supertype. Link shipping/billing to `ORDER_ITEM`.
- NEVER overwrite financial data or quantities for corrections; ALWAYS use recursive adjusting `INVOICE_ITEM`s. Separate business transactions from accounting transactions (`TRANSACTION_DETAIL` with debit/credit).
- ALWAYS separate `WORK_REQUIREMENT` (need), `WORK_ORDER_ITEM` (commitment), and `WORK_EFFORT` (execution). Track historical state using `from_date` and `thru_date`. Derive statuses where possible.
- ALWAYS abstract addresses/phones into `CONTACT_MECHANISM` linked via associative entities with `PURPOSE` and `USAGE`.
- ALWAYS enforce Normalization (1NF, 2NF, 3NF) in logical models. Denormalize (Rolldown/Rollup) in physical models ONLY for explicit performance gains.
- ALWAYS resolve logical subtypes in physical models via Identity, Rolldown, or Rollup based on access patterns.
- ALWAYS design Data Warehouses using Star Schemas: a central `FACT` table (numeric measures, composite primary keys) surrounded by flattened `DIMENSION` tables (e.g., `TIME_BY_DAY`). NEVER extract Data Marts directly from operational systems; source from the EDW.

### 2. Distributed Systems & Database Reliability
- ALWAYS select storage engines based on workload: B-Trees for read-heavy/predictable latency, LSM-Trees for write-heavy, Columnar (Parquet/ORC) with Bitmap/RLE for OLAP.
- ALWAYS configure replication appropriately: Single-Leader for strong consistency, Multi-Leader for geo-distribution (requires CRDTs), Leaderless for high availability (requires Quorum $W+R>N$).
- NEVER use Last Write Wins (LWW) with wall-clock timestamps; ALWAYS use Version Vectors. 
- ALWAYS wrap multi-object mutations in explicit ACID transactions. Prevent Lost Updates via atomic operations or `FOR UPDATE`. Prevent Write Skew via Serializable isolation or index-range locks.
- ALWAYS mitigate hot keys using salting. NEVER use `hash % N` for routing; use Consistent Hashing.
- ALWAYS use Fencing Tokens for distributed locks. Use 2PC for distributed transactions. Rely on ZooKeeper/etcd for consensus.
- ALWAYS treat event logs as immutable Systems of Record. Derive read-optimized Materialized Views (CQRS) deterministically. Use pure functions.
- ALWAYS prioritize MTTR over MTBF. Implement automated failover with STONITH. Monitor USE (Utilization, Saturation, Errors). Alert ONLY on imminent SLO violations.
- ALWAYS enforce Datensparsamkeit (Data Minimization). Implement crypto-shredding for GDPR right-to-erasure in immutable logs. Use Prepared Statements. Enforce TLS 1.2+ and PFS.
- NEVER treat replication as a backup. ALWAYS implement tiered physical backups and continuously test restores.

### 3. Information Architecture & Content Strategy
- ALWAYS separate content meaning from visual presentation. Break content into semantic chunks (Elements) within Content Types. NEVER use WYSIWYG HTML blobs.
- ALWAYS implement COPE (Create Once, Publish Everywhere) using Adaptive Content (filtered by device constraints) rather than relying solely on Responsive Design.
- ALWAYS use Controlled Vocabularies. Define Preferred Terms (PT) and Variant Terms (VT/UF). Enforce the "All/Some" rule for Hierarchical relationships (BT/NT). Use Associative relationships (RT) for cross-hierarchy links.
- ALWAYS use Faceted Classification (mutually exclusive dimensions like Topic, Audience, Geography) for complex, heterogeneous content instead of rigid single hierarchies.
- ALWAYS tune search systems by weighting structural metadata. Implement "No Dead Ends" policies for zero-result SERPs.
- ALWAYS use Open Card Sorts for discovery and Closed Card Sorts for validation. NEVER use card sorting to test findability; use task-based usability testing.
- ALWAYS establish a Governance Board. Define strict rules for content lifecycles (Create, Review, Manage, Deliver).
- ALWAYS use URIs for entities and structure data as RDF Triples (Subject-Predicate-Object). Embed Schema.org microdata in HTML.

## 📝 Examples

### ✅ DO
```sql
-- DO: Use associative entities with date ranges for historical tracking
CREATE TABLE party_role (
    party_id INT REFERENCES party(party_id),
    role_type_id INT REFERENCES role_type(role_type_id),
    from_date DATE NOT NULL,
    thru_date DATE,
    PRIMARY KEY (party_id, role_type_id, from_date)
);

-- DO: Star Schema Fact Table with composite dimension keys
CREATE TABLE sales_fact (
    time_id INT REFERENCES time_dim(time_id),
    product_id INT REFERENCES product_dim(product_id),
    customer_id INT REFERENCES customer_dim(customer_id),
    quantity_sold INT,
    gross_revenue DECIMAL(15,2),
    PRIMARY KEY (time_id, product_id, customer_id)
);
```

```json
// DO: Semantic, format-free content modeling for omnichannel delivery
{
  "content_type": "Recipe",
  "id": "rec_123",
  "metadata": {
    "audience": "Beginner",
    "dietary_tags": ["Vegan", "Gluten-Free"]
  },
  "elements": {
    "title": "Roasted Carrots",
    "teaser_mobile": "Quick and easy roasted carrots.",
    "ingredients": ["Carrots", "Olive Oil", "Salt"],
    "steps": ["Preheat oven to 400F.", "Roast for 20 mins."]
  }
}
```

```python
# DO: Safe distributed locking with Fencing Tokens
lock_token = coordination_service.acquire_lock("resource_x")
db.execute(
    "UPDATE table SET val = %s WHERE id = %s AND last_token <= %s", 
    (new_val, resource_id, lock_token)
)
```

### ❌ DON'T
```sql
-- DON'T: Hardcode volatile attributes or repeating groups (1NF/3NF violations)
CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    phone_1 VARCHAR(20),
    phone_2 VARCHAR(20),
    current_status VARCHAR(50) -- Loses history
);

-- DON'T: Use operational keys in Fact Tables
CREATE TABLE sales_fact (
    invoice_id INT PRIMARY KEY, -- Anti-pattern: Prevents dimensional aggregation
    gross_revenue DECIMAL(15,2)
);
```

```html
<!-- DON'T: WYSIWYG blobs mixing content and presentation -->
<div class="article-body">
  <font size="5"><b>Roasted Carrots</b></font><br><br>
  <i>Quick and easy roasted carrots.</i><br>
  <ul><li>Carrots</li></ul>
</div>
```

```python
# DON'T: Naive read-modify-write vulnerable to Lost Updates
row = db.execute("SELECT value FROM counters WHERE id = ?", counter_id)
new_value = row['value'] + 1
db.execute("UPDATE counters SET value = ? WHERE id = ?", new_value, counter_id)