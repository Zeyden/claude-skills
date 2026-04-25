# Database Deep-Dive

## 1. postgreskit

Import: `gitlab.com/tabby.ai/core/pkg/postgreskit`

Plug-and-play PostgreSQL connection management built on `pgx/v5`.

### Setup

```go
import "gitlab.com/tabby.ai/core/pkg/postgreskit"

db, err := postgreskit.New(ctx, postgreskit.Config{
    DSN:             os.Getenv("DATABASE_URL"),
    MaxConns:        10,
    MinConns:        2,
    MaxConnLifetime: 30 * time.Minute,
    MaxConnIdleTime: 5 * time.Minute,
})
if err != nil {
    log.Fatal("failed to connect to database", "error", err)
}
defer db.Close()
```

### Configuration

| Field | Env Variable | Default | Description |
|-------|-------------|---------|-------------|
| `DSN` | `DATABASE_URL` | — | PostgreSQL connection string |
| `MaxConns` | `DATABASE_MAX_CONNS` | 10 | Maximum open connections |
| `MinConns` | `DATABASE_MIN_CONNS` | 2 | Minimum idle connections |
| `MaxConnLifetime` | `DATABASE_MAX_CONN_LIFETIME` | 30m | Max time a connection lives |
| `MaxConnIdleTime` | `DATABASE_MAX_CONN_IDLE_TIME` | 5m | Max time a connection stays idle |

### Querying

```go
// Single row
var order Order
err := db.Pool.QueryRow(ctx,
    "SELECT id, customer_id, amount FROM orders WHERE id = $1", orderID,
).Scan(&order.ID, &order.CustomerID, &order.Amount)

// Multiple rows
rows, err := db.Pool.Query(ctx,
    "SELECT id, customer_id, amount FROM orders WHERE status = $1", "pending",
)
defer rows.Close()
for rows.Next() {
    var o Order
    rows.Scan(&o.ID, &o.CustomerID, &o.Amount)
    orders = append(orders, o)
}

// Execute (insert/update/delete)
tag, err := db.Pool.Exec(ctx,
    "UPDATE orders SET status = $1 WHERE id = $2", "completed", orderID,
)
fmt.Println(tag.RowsAffected()) // 1
```

### Transactions

```go
tx, err := db.Pool.Begin(ctx)
if err != nil {
    return err
}
defer tx.Rollback(ctx) // no-op if committed

tx.Exec(ctx, "INSERT INTO orders (id, amount) VALUES ($1, $2)", orderID, amount)
tx.Exec(ctx, "INSERT INTO order_items (order_id, product_id) VALUES ($1, $2)", orderID, productID)

return tx.Commit(ctx)
```

### Health Checks

```go
import "gitlab.com/tabby.ai/core/pkg/healthkit"

healthkit.Register("postgres", db.HealthCheck)
```

---

## 2. pgbouncer

### Connection Calculation

```
max_server_connections = (num_app_instances * max_conns_per_instance) + buffer

Example:
  3 instances * 10 max_conns = 30
  buffer = 10
  pgbouncer max_server_connections = 40
  PostgreSQL max_connections = 50 (pgbouncer + direct admin)
```

### Prepared Statement Fix

pgx v5 defaults to prepared statements, which pgbouncer does not support in transaction pooling mode. This causes:

```
ERROR: prepared statement "stmtcache_xxx" already exists
```

**Fix option 1** — DSN parameter (recommended):

```
DATABASE_URL=postgres://user:pass@pgbouncer:5432/mydb?default_query_exec_mode=simple_protocol
```

**Fix option 2** — pgx config:

```go
config, _ := pgxpool.ParseConfig(dsn)
config.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
```

### Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `prepared statement "stmtcache_xxx" already exists` | pgx using prepared statements through pgbouncer | Enable simple protocol (see above) |
| Connection timeouts | App pool > pgbouncer pool | Reduce `MaxConns` or increase pgbouncer `default_pool_size` |
| `too many connections` | Total connections exceed PostgreSQL `max_connections` | Recalculate: reduce app pools or increase PG limit |
| `server login failed` | pgbouncer auth mismatch | Check `userlist.txt` or `auth_query` config |
| Slow queries after pool exhaustion | All connections busy | Add `pool_timeout` to pgbouncer, tune `MaxConns` |

### pgbouncer Configuration Reference

| Setting | Recommended | Description |
|---------|------------|-------------|
| `pool_mode` | `transaction` | Release connection after transaction |
| `default_pool_size` | 20 | Connections per user/database pair |
| `max_client_conn` | 200 | Max client connections |
| `reserve_pool_size` | 5 | Extra connections for burst |
| `reserve_pool_timeout` | 3s | Wait before using reserve pool |
| `server_lifetime` | 3600 | Close server connections older than this (seconds) |

---

## 3. Migration Checklist — Safe Patterns

**Golden rule**: All migrations must be backward-compatible. Old code must work with the new schema, and new code must work with the old schema during rollout.

### ADD COLUMN

Always add as nullable or with a DEFAULT:

```sql
-- Safe: nullable column
ALTER TABLE orders ADD COLUMN notes text;

-- Safe: column with default
ALTER TABLE orders ADD COLUMN status text DEFAULT 'pending';

-- Safe: column with default (PostgreSQL 11+ stores default in catalog, no rewrite)
ALTER TABLE orders ADD COLUMN created_at timestamptz DEFAULT now();
```

```sql
-- UNSAFE: NOT NULL without default on existing table (fails if rows exist)
ALTER TABLE orders ADD COLUMN status text NOT NULL;
```

### CREATE INDEX CONCURRENTLY

Always use `CONCURRENTLY` to avoid blocking writes:

```sql
-- Safe: non-blocking index creation
CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status);

-- Safe: partial index
CREATE INDEX CONCURRENTLY idx_orders_pending ON orders(created_at)
    WHERE status = 'pending';
```

```sql
-- UNSAFE: locks entire table for duration of index build
CREATE INDEX idx_orders_status ON orders(status);
```

**Note**: `CREATE INDEX CONCURRENTLY` cannot run inside a transaction. If using a migration tool, ensure it supports non-transactional migrations.

### NOT NULL via CHECK Constraint

Add NOT NULL in stages to avoid full table lock:

```sql
-- Migration 1: Add CHECK constraint as NOT VALID (instant, no lock)
ALTER TABLE orders ADD CONSTRAINT orders_status_not_null
    CHECK (status IS NOT NULL) NOT VALID;

-- Migration 2: Validate constraint (scans rows, but does NOT block writes)
ALTER TABLE orders VALIDATE CONSTRAINT orders_status_not_null;

-- Migration 3 (optional, later): Convert to real NOT NULL and drop CHECK
ALTER TABLE orders ALTER COLUMN status SET NOT NULL;
ALTER TABLE orders DROP CONSTRAINT orders_status_not_null;
```

### Foreign Keys with NOT VALID

```sql
-- Migration 1: Add FK as NOT VALID (instant, no lock, no row scan)
ALTER TABLE order_items ADD CONSTRAINT fk_order
    FOREIGN KEY (order_id) REFERENCES orders(id) NOT VALID;

-- Migration 2: Validate (scans rows, no write lock)
ALTER TABLE order_items VALIDATE CONSTRAINT fk_order;
```

### Unique Constraints

Create the index concurrently first, then attach it as a constraint:

```sql
-- Migration 1: Create unique index concurrently (non-blocking)
CREATE UNIQUE INDEX CONCURRENTLY idx_orders_ref_unique ON orders(reference);

-- Migration 2: Add constraint using existing index (instant)
ALTER TABLE orders ADD CONSTRAINT orders_ref_unique
    UNIQUE USING INDEX idx_orders_ref_unique;
```

### Enum Types

Altering enum types cannot run inside a transaction:

```sql
-- Must run outside a transaction block
ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'refunded';
```

**Tip**: If your migration tool wraps everything in transactions, use a separate non-transactional migration file.

### Partitioned Index Drops

When dropping an index on a partitioned table:

1. Detach partitions that need the index dropped
2. Drop the index on detached partitions
3. Reattach partitions if needed
4. Drop the parent index

### Column Removal (Two-Phase)

Never drop a column that code still references:

```
Phase 1 (code deploy): Remove all code references to the column
Phase 2 (migration):   ALTER TABLE orders DROP COLUMN old_field;
```

### Column Rename (Three-Phase)

```
Phase 1: Add new column, write to both old and new
Phase 2: Backfill new column from old column
Phase 3: Switch reads to new column, stop writing old
Phase 4: Drop old column
```

---

## 4. Migration Tooling

### golang-migrate

```bash
# Create a new migration
migrate create -ext sql -dir migrations -seq add_orders_status

# Run migrations
migrate -path migrations -database "$DATABASE_URL" up

# Rollback last migration
migrate -path migrations -database "$DATABASE_URL" down 1
```

### File Structure

```
migrations/
├── 000001_initial_schema.up.sql
├── 000001_initial_schema.down.sql
├── 000002_add_orders_status.up.sql
├── 000002_add_orders_status.down.sql
├── 000003_add_status_index.up.sql      -- CREATE INDEX CONCURRENTLY
└── 000003_add_status_index.down.sql
```

### CI Pipeline

```yaml
migrate-test:
  stage: test
  services:
    - postgres:16
  script:
    - migrate -path migrations -database "$TEST_DATABASE_URL" up
    - migrate -path migrations -database "$TEST_DATABASE_URL" down
    - migrate -path migrations -database "$TEST_DATABASE_URL" up
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
```

### Safety Checklist

| Check | Description |
|-------|-------------|
| Backward compatible? | Old code works with new schema |
| Forward compatible? | New code works with old schema (during rollout) |
| Non-blocking? | No long-running locks on production tables |
| Reversible? | Down migration works correctly |
| Tested both ways? | up → down → up passes |
| Data preserved? | No accidental data loss in rollback |
