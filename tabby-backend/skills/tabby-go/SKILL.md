---
name: tabby-go
description: "Tabby Go backend development expertise. Covers internal libraries (pkg/log, postgreskit, pubsub/v2, otelkit, ffkit, l10nkit, auth/casbin), Go patterns (context cancellation, errgroup), Google pub/sub (publishing, subscribing, AsyncAPI SDK, outbox pattern, dead-lettering), observability (structured logging, OTEL metrics, DataDog tracing, SLO), PostgreSQL (postgreskit, pgbouncer, migrations), API design (protobuf layout/SDK, Caddy API gateway, rate limiting, API registry), platform services (feature flags via OpenFeature, RBAC/Casbin authorization, localization, Temporal workflows), and CI/CD (Docker base images, golangci-lint). Use when working with Tabby Go services, internal pkg libraries, or any backend infrastructure topic."
---

# Tabby Go Backend — Expert Skill

## Mental Model

```
                         ┌──────────────────────────────────────────────┐
                         │              Caddy API Gateway               │
                         │  (gRPC proxy, rate limiting, CORS, routing)  │
                         └────────┬──────────────┬──────────────┬───────┘
                                  │              │              │
                    ┌─────────────▼──┐  ┌────────▼───────┐  ┌──▼──────────────┐
                    │ Service A      │  │ Service B      │  │ Service C       │
                    │ (gRPC server)  │  │ (gRPC server)  │  │ (gRPC server)   │
                    │                │  │                │  │                 │
                    │ ┌────────────┐ │  │ ┌────────────┐ │  │ ┌─────────────┐ │
                    │ │ internal/  │ │  │ │ internal/  │ │  │ │ internal/   │ │
                    │ │  app/      │ │  │ │  app/      │ │  │ │  app/       │ │
                    │ │  handler   │ │  │ │  handler   │ │  │ │  handler    │ │
                    │ │  service   │ │  │ │  service   │ │  │ │  service    │ │
                    │ │  repo      │ │  │ │  repo      │ │  │ │  repo       │ │
                    │ └────────────┘ │  │ └────────────┘ │  │ └─────────────┘ │
                    └──┬──────┬──┬───┘  └──┬──────┬──────┘  └──┬──────┬──────┘
                       │      │  │         │      │             │      │
              ┌────────▼──┐ ┌─▼──▼──────┐ ┌▼──────▼──┐  ┌──────▼──┐ ┌▼────────────┐
              │PostgreSQL │ │Google     │ │Feature   │  │Temporal │ │Localization │
              │postgreskit│ │Pub/Sub   │ │Flags     │  │Workflows│ │l10nkit      │
              │pgbouncer  │ │pubsub/v2 │ │ffkit     │  │         │ │             │
              └───────────┘ │AsyncAPI  │ │OpenFeature│  └─────────┘ └─────────────┘
                            └──────────┘ └──────────┘

    Observability: pkg/log (structured) + otelkit (metrics) + dd-trace-go (tracing)
    Auth: Google OIDC + Casbin RBAC       CI: Docker builder/runner + golangci-lint
```

## When to Use This Skill

Trigger on any of these topics:

- Go backend development at Tabby, internal `pkg/` libraries
- `pkg/log`, `postgreskit`, `pubsub/v2`, `otelkit`, `ffkit`, `l10nkit`, `auth/casbin`
- Google Pub/Sub, AsyncAPI SDK, outbox pattern, dead-lettering
- Structured logging, OTEL metrics, `metrics.yaml`, DataDog tracing, SLO
- PostgreSQL, pgbouncer, database migrations
- Protobuf layout, proto SDK, Caddy API gateway, rate limiting, API registry
- Feature flags, OpenFeature, RBAC, Casbin authorization
- Localization, Temporal workflows
- `tabbycli`, Docker builder/runner images, `golangci-lint`, CI/CD pipelines
- `project-template`, service scaffolding

## Internal Libraries Quick Reference

| Library | Import Path | Purpose |
|---------|------------|---------|
| `log` | `gitlab.com/tabby.ai/core/pkg/log` | Structured logging with level filtering and masking |
| `postgreskit` | `gitlab.com/tabby.ai/core/pkg/postgreskit` | PostgreSQL connection management (pgx/v5) |
| `pubsub/v2` | `gitlab.com/tabby.ai/core/pkg/pubsub/v2` | Google Pub/Sub adapter (topics, subscriptions, batching) |
| `otelkit` | `gitlab.com/tabby.ai/core/pkg/otelkit` | OpenTelemetry metrics setup and helpers |
| `ffkit` | `gitlab.com/tabby.ai/core/pkg/ffkit` | Feature flags via OpenFeature standard |
| `l10nkit` | `gitlab.com/tabby.ai/core/pkg/l10nkit` | Localization with Lokalise integration |
| `auth/casbin` | `gitlab.com/tabby.ai/core/pkg/auth/casbin` | RBAC authorization with Casbin engine |
| `grpckit` | `gitlab.com/tabby.ai/core/pkg/grpckit` | gRPC server/client helpers and interceptors |
| `httpkit` | `gitlab.com/tabby.ai/core/pkg/httpkit` | HTTP server helpers and middleware |
| `healthkit` | `gitlab.com/tabby.ai/core/pkg/healthkit` | Health check and readiness probes |
| `configkit` | `gitlab.com/tabby.ai/core/pkg/configkit` | Configuration loading from env/files |

---

## Go Patterns

### Context Cancellation with `context.WithoutCancel`

Use `context.WithoutCancel` (Go 1.21+) when spawning background work that should outlive the parent request:

```go
import "context"

func (s *Service) ProcessOrder(ctx context.Context, order *Order) error {
    // Synchronous work uses the request context
    if err := s.validate(ctx, order); err != nil {
        return err
    }

    // Background work must not be cancelled when the request ends
    bgCtx := context.WithoutCancel(ctx)
    go s.sendNotification(bgCtx, order)

    return nil
}
```

**When to use:**
- Fire-and-forget side effects (notifications, analytics)
- Outbox processors that outlive the triggering request
- Background cleanup tasks

**When NOT to use:**
- Work that the caller needs to wait for (use `errgroup` instead)
- Work that should be cancelled if the parent is cancelled

### errgroup with Panic Recovery

Use `errgroup` for concurrent work within a request. Always wrap with panic recovery:

```go
import (
    "golang.org/x/sync/errgroup"
    "gitlab.com/tabby.ai/core/pkg/log"
)

func (s *Service) EnrichOrder(ctx context.Context, order *Order) error {
    g, ctx := errgroup.WithContext(ctx)

    g.Go(func() (err error) {
        defer func() {
            if r := recover(); r != nil {
                log.Error(ctx, "panic in fetchCustomer", "panic", r)
                err = fmt.Errorf("panic: %v", r)
            }
        }()
        return s.fetchCustomer(ctx, order)
    })

    g.Go(func() (err error) {
        defer func() {
            if r := recover(); r != nil {
                log.Error(ctx, "panic in fetchProducts", "panic", r)
                err = fmt.Errorf("panic: %v", r)
            }
        }()
        return s.fetchProducts(ctx, order)
    })

    return g.Wait()
}
```

**Key points:**
- `errgroup.WithContext` cancels sibling goroutines on first error
- Always recover panics — an unrecovered panic in a goroutine kills the process
- Set concurrency limits with `g.SetLimit(n)` for bounded parallelism

---

## Pub/Sub

Google Pub/Sub is the primary async messaging system. See `references/pubsub.md` for full details.

### Quick Overview

| Pattern | When to Use | Reference |
|---------|------------|-----------|
| **AsyncAPI SDK Publisher** | Standard event publishing with typed contracts | `references/pubsub.md` §2 |
| **AsyncAPI SDK Subscriber** | Standard event consumption with typed handlers | `references/pubsub.md` §3 |
| **Outbox Pattern** | Transactional event publishing (exactly-once) | `references/pubsub.md` §4 |
| **Raw Pub/Sub Adapter** | Low-level access, custom serialisation | `references/pubsub.md` §1 |

### Minimal Publisher Example

```go
import (
    "gitlab.com/tabby.ai/core/sdk/events/payments/v1"
    "gitlab.com/tabby.ai/core/pkg/pubsub/v2"
)

transport := pubsub.NewTransport(pubsubClient)
publisher := payments.NewPublisher(transport)

err := publisher.PublishPaymentCreated(ctx, &payments.PaymentCreated{
    PaymentId: "pay_123",
    Amount:    10000,
    Currency:  "AED",
})
```

### Minimal Subscriber Example

```go
subscriber := payments.NewSubscriber(transport)
subscriber.Register(&PaymentHandler{})
subscriber.Start(ctx) // blocks until context cancelled
```

---

## Observability

Three pillars: logging, metrics, tracing. See `references/observability.md` for full details.

### Logging — `pkg/log`

```go
import "gitlab.com/tabby.ai/core/pkg/log"

logger := log.New("payments")
logger.Info("payment processed", "order_id", orderID, "amount", amount)
logger.Error("payment failed", "error", err, "card", log.MaskString(card))
```

- Filter with `TABBY_LOG=debug` or `TABBY_LOG=payments=debug,*=warn`
- Use `log.MaskString()` for PII/sensitive data
- Use `logtest` package in tests

### Metrics — `metrics.yaml` + `tabbycli`

1. Define metrics in `metrics.yaml`
2. Run `tabbycli metrics generate`
3. Use generated functions:

```go
metrics.PaymentsProcessedTotal.Add(ctx, 1,
    attribute.String("status", "success"),
)
```

### Tracing — DataDog

```go
import "gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"

span, ctx := tracer.StartSpanFromContext(ctx, "process.payment")
defer span.Finish()
span.SetTag("payment.id", paymentID)
```

Auto-instrumented by TabbyKits: gRPC, HTTP, Pub/Sub, SQL.

### SLO — `slo.yaml`

Define SLOs in `slo.yaml`, lint with `tabbycli slo lint`, apply with `tabbycli slo apply`.

---

## Database

PostgreSQL via `postgreskit` with pgbouncer. See `references/database.md` for full details.

### Quick Setup

```go
import "gitlab.com/tabby.ai/core/pkg/postgreskit"

db, err := postgreskit.New(ctx, postgreskit.Config{
    DSN:      os.Getenv("DATABASE_URL"),
    MaxConns: 10,
})
defer db.Close()
```

### pgbouncer Compatibility

Always use simple protocol with pgbouncer (transaction pooling mode):

```
DATABASE_URL=postgres://user:pass@pgbouncer:5432/mydb?default_query_exec_mode=simple_protocol
```

### Migration Safety Rules

| Operation | Safe Pattern |
|-----------|-------------|
| Add column | `ADD COLUMN ... DEFAULT 'value'` or nullable |
| Create index | `CREATE INDEX CONCURRENTLY` |
| Add NOT NULL | CHECK constraint NOT VALID → VALIDATE → SET NOT NULL |
| Add foreign key | `ADD CONSTRAINT ... NOT VALID` → `VALIDATE CONSTRAINT` |
| Add unique | Create unique index CONCURRENTLY → `ADD CONSTRAINT USING INDEX` |
| Add enum value | Outside transaction: `ALTER TYPE ... ADD VALUE IF NOT EXISTS` |

---

## API Design

Protobuf-first with Caddy gateway. See `references/api-design.md` for full details.

### Protobuf Layout

```
proto/
├── tabby/
│   └── {domain}/
│       └── v1/
│           ├── {resource}.proto
│           └── {resource}_service.proto
├── buf.yaml
└── buf.gen.yaml
```

- Package: `tabby.{domain}.{version}` (e.g., `tabby.payments.v1`)
- Service: `{Domain}Service` (e.g., `PaymentsService`)
- Generate with `tabbycli proto generate`

### Caddy API Gateway

```
:8080 {
    @payments path /tabby.payments.v1.PaymentsService/*
    reverse_proxy @payments payments-service:9090 {
        transport http {
            versions h2c
        }
    }
}
```

Bootstrap with `tabbycli gateway init`.

### Rate Limiting

- Zones define rate buckets (per-client, per-endpoint, global)
- Returns gRPC `ResourceExhausted` status
- Keys: IP, API key, user ID, gRPC metadata

---

## Platform Services

See `references/platform-services.md` for full details.

### Feature Flags — ffkit

```go
import "gitlab.com/tabby.ai/core/pkg/ffkit"

client := ffkit.NewClient()
enabled, _ := client.BooleanValue(ctx, "new-checkout-flow", false,
    ffkit.EvalContext{
        TargetingKey: userID,
        Attributes: map[string]interface{}{
            "country": "AE",
        },
    },
)
```

- OpenFeature standard, `ff-agent` sidecar
- Local dev with Flagd

### Authorization — Casbin RBAC

```go
import "gitlab.com/tabby.ai/core/pkg/auth/casbin"

enforcer := casbin.NewEnforcer(model, policy)
allowed, _ := enforcer.Enforce(userEmail, resource, action)
```

- Google OIDC + Google Groups → Casbin roles
- PEP/PDP architecture

### Localization — l10nkit

```go
import "gitlab.com/tabby.ai/core/pkg/l10nkit"

localizer := l10nkit.New(l10nkit.Config{DefaultLanguage: "en"})
text, _ := localizer.Localize(ctx, "welcome.message",
    l10nkit.Params{"name": userName},
    l10nkit.WithLanguage("ar"),
)
```

### Temporal Workflows

Durable, long-running workflows. Register workflows and activities with a worker:

```go
w := worker.New(temporalClient, "task-queue", worker.Options{})
w.RegisterWorkflow(PaymentWorkflow)
w.RegisterActivity(ChargeActivity)
w.Run(worker.InterruptCh())
```

---

## CI/CD

Docker multi-stage builds with Athens proxy. See `references/pipelines.md` for full details.

### Docker Pattern

```dockerfile
# Build
FROM golang:1.22-bookworm AS builder
ENV GOPRIVATE="gitlab.com/tabby.ai/*"
ENV GOPROXY="https://athens.internal.tabby.ai,https://proxy.golang.org,direct"
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/service ./cmd/service

# Run (secure)
FROM gcr.io/distroless/static-debian12
COPY --from=builder /bin/service /bin/service
ENTRYPOINT ["/bin/service"]
```

### Linting

```makefile
lint:
	docker run --rm -v $(PWD):/app -w /app golangci/golangci-lint:v1.57 golangci-lint run ./...
```

---

## Project Template — Standard Structure

```
my-service/
├── cmd/
│   └── service/
│       └── main.go              # Entry point, wiring
├── internal/
│   └── app/
│       ├── handler/             # gRPC/HTTP handlers (transport layer)
│       │   └── payments.go
│       ├── service/             # Business logic
│       │   └── payments.go
│       └── repo/                # Database access (repository pattern)
│           └── payments.go
├── proto/
│   └── tabby/
│       └── payments/
│           └── v1/
│               └── payments_service.proto
├── migrations/
│   ├── 001_initial.up.sql
│   └── 001_initial.down.sql
├── metrics.yaml
├── slo.yaml
├── .golangci.yml
├── Dockerfile
├── Makefile
└── go.mod
```

### Component Pattern

Services follow a component pattern where `main.go` wires everything:

```go
func main() {
    // Config
    cfg := configkit.MustLoad[Config]()

    // Database
    db, _ := postgreskit.New(ctx, cfg.Database)
    defer db.Close()

    // Repos
    paymentsRepo := repo.NewPayments(db)

    // Services
    paymentsSvc := service.NewPayments(paymentsRepo, publisher)

    // Handlers
    paymentsHandler := handler.NewPayments(paymentsSvc)

    // gRPC server
    srv := grpckit.NewServer(
        grpckit.WithReflection(),
        grpckit.WithHealthCheck(db),
    )
    payments.RegisterPaymentsServiceServer(srv, paymentsHandler)

    // Start
    grpckit.Serve(ctx, srv, ":9090")
}
```

---

## Delegation Guide

| Topic | Delegate To |
|-------|-------------|
| BDUI widget configuration, Sanity CMS pages | `bdui-sanity` |
| Compose UI rendering of BDUI widgets | `compose-expert` |

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|-------------|----------------|------------------|
| Using `fmt.Println` for logging | No structure, no levels, no filtering | Use `pkg/log` |
| Raw `database/sql` | Missing connection pooling, no pgx features | Use `postgreskit` |
| Manual Pub/Sub serialisation | Breaks contract, no type safety | Use AsyncAPI SDK |
| Blocking in Pub/Sub handlers | Starves other messages | Use bounded `errgroup` or async processing |
| `CREATE INDEX` without CONCURRENTLY | Locks table for entire build | `CREATE INDEX CONCURRENTLY` |
| `ALTER TABLE ADD COLUMN NOT NULL` | Full table lock + fails on existing rows | Add nullable or with DEFAULT |
| Hardcoded feature flags | Cannot toggle without deploy | Use `ffkit` with OpenFeature |
| `log.Fatal` in library code | Kills the process, bypasses cleanup | Return errors, let `main` decide |
| Ignoring context cancellation | Wasted work, resource leaks | Check `ctx.Err()` or use `select` |
| Global mutable state | Data races, untestable | Dependency injection via constructor |

---

## Resources

| Resource | Path |
|----------|------|
| Core guides repository | `gitlab.com/tabby.ai/core/guides` |
| Internal packages | `gitlab.com/tabby.ai/core/pkg/` |
| Project template | `gitlab.com/tabby.ai/core/project-template` |
| AsyncAPI SDK generator | `tabbycli asyncapi generate-sdk` |
| Proto SDK generator | `tabbycli proto generate` |
| Metrics generator | `tabbycli metrics generate` |
| SLO tooling | `tabbycli slo lint` / `tabbycli slo apply` |
| Gateway bootstrap | `tabbycli gateway init` |
| Pub/Sub deep-dive | `references/pubsub.md` |
| Observability deep-dive | `references/observability.md` |
| Database deep-dive | `references/database.md` |
| API design deep-dive | `references/api-design.md` |
| Platform services deep-dive | `references/platform-services.md` |
| CI/CD deep-dive | `references/pipelines.md` |
