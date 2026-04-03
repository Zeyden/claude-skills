# Observability Deep-Dive

## 1. Structured Logging with `pkg/log`

Import: `gitlab.com/tabby.ai/core/pkg/log`

### Basic Usage

```go
import "gitlab.com/tabby.ai/core/pkg/log"

// Create a named logger
logger := log.New("payments")

// Structured key-value logging
logger.Info("payment processed",
    "order_id", orderID,
    "amount", amount,
    "currency", "AED",
)

// Error logging with error value
logger.Error("payment failed",
    "error", err,
    "order_id", orderID,
)

// Debug logging (filtered in production)
logger.Debug("validating payment details",
    "card_last_four", card[len(card)-4:],
)
```

### Log Levels

| Level | Usage |
|-------|-------|
| `Debug` | Development-only detail, disabled in production |
| `Info` | Normal operations, key business events |
| `Warn` | Unexpected but recoverable situations |
| `Error` | Failures requiring attention |

### TABBY_LOG Environment Variable

Filter log output by package and level:

| Value | Effect |
|-------|--------|
| `debug` | All packages at debug level |
| `warn` | All packages at warn+ |
| `payments=debug,*=warn` | payments at debug, everything else at warn |
| `payments=debug,orders=info,*=error` | Fine-grained per-package control |

### Context-Enriched Logging

```go
// Add fields to context — all downstream logs include them
ctx = log.WithFields(ctx,
    "request_id", requestID,
    "user_id", userID,
)

// Later, in any function receiving this context
logger.InfoContext(ctx, "processing request")
// Output includes request_id and user_id automatically
```

### Sensitive Data Masking

```go
logger.Info("payment details",
    "card", log.MaskString(cardNumber),    // "****1234"
    "email", log.MaskString(email),         // "****@example.com"
    "phone", log.Mask(phoneNumber),         // masks any type
)
```

**Rule**: Always mask PII, card numbers, tokens, and secrets before logging.

### Output Formats

| Format | When | Example |
|--------|------|---------|
| logfmt | Development (`TABBY_ENV=local`) | `level=info msg="payment processed" order_id=123` |
| JSON | Production (`TABBY_ENV=production`) | `{"level":"info","msg":"payment processed","order_id":123}` |

### Testing with logtest

```go
import "gitlab.com/tabby.ai/core/pkg/log/logtest"

func TestPaymentLogging(t *testing.T) {
    recorder := logtest.NewRecorder()
    logger := log.New("payments", log.WithHandler(recorder))

    svc := NewService(logger)
    svc.Process(ctx, payment)

    // Assert log entries
    entries := recorder.Entries()
    require.Len(t, entries, 1)
    assert.Equal(t, "payment processed", entries[0].Message)
    assert.Equal(t, "pay_123", entries[0].Attrs["order_id"])
}
```

---

## 2. Metrics with `metrics.yaml` + `tabbycli`

### Define Metrics

Create `metrics.yaml` at project root:

```yaml
metrics:
  - name: payments_processed_total
    type: counter
    description: "Total number of payments processed"
    labels:
      - name: status
        description: "Payment status (success, failed, timeout)"
      - name: method
        description: "Payment method (card, wallet, bank_transfer)"

  - name: payment_processing_duration_seconds
    type: histogram
    description: "Payment processing duration in seconds"
    buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
    labels:
      - name: method
        description: "Payment method"

  - name: active_payment_sessions
    type: updowncounter
    description: "Currently active payment sessions"

  - name: payment_queue_depth
    type: gauge
    description: "Current depth of the payment processing queue"
```

### Generate Code

```bash
tabbycli metrics generate
```

Produces a `metrics/` package with typed metric accessors.

### Use Generated Metrics

```go
import (
    "your-service/metrics"
    "go.opentelemetry.io/otel/attribute"
)

// Counter
metrics.PaymentsProcessedTotal.Add(ctx, 1,
    attribute.String("status", "success"),
    attribute.String("method", "card"),
)

// Histogram
start := time.Now()
// ... process payment ...
metrics.PaymentProcessingDurationSeconds.Record(ctx, time.Since(start).Seconds(),
    attribute.String("method", "card"),
)

// UpDownCounter
metrics.ActivePaymentSessions.Add(ctx, 1)
defer metrics.ActivePaymentSessions.Add(ctx, -1)
```

### Metric Types Reference

| Type | Use Case | Operations |
|------|----------|------------|
| `counter` | Monotonically increasing values (requests, errors) | `Add(ctx, value, attrs...)` |
| `gauge` | Point-in-time values (queue depth, temperature) | `Record(ctx, value, attrs...)` |
| `histogram` | Distribution of values (latencies, sizes) | `Record(ctx, value, attrs...)` |
| `updowncounter` | Values that go up and down (active connections) | `Add(ctx, delta, attrs...)` |

### OTEL/otelkit Setup

```go
import "gitlab.com/tabby.ai/core/pkg/otelkit"

shutdown, err := otelkit.Setup(ctx, otelkit.Config{
    ServiceName:    "payments-service",
    ServiceVersion: version,
    Environment:    os.Getenv("TABBY_ENV"),
})
defer shutdown(ctx)
```

### Push Mode

For serverless or short-lived processes that cannot wait for scraping:

```go
otelkit.Setup(ctx, otelkit.Config{
    ServiceName: "payments-cron",
    PushMode:    true,
    PushEndpoint: os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT"),
})
```

### Testing Metrics

```go
import "go.opentelemetry.io/otel/sdk/metric/metrictest"

func TestPaymentMetrics(t *testing.T) {
    reader := metrictest.NewManualReader()
    provider := metric.NewMeterProvider(metric.WithReader(reader))

    // Inject test provider
    svc := NewService(WithMeterProvider(provider))
    svc.Process(ctx, payment)

    // Read and assert metrics
    rm, _ := reader.Collect(ctx)
    // Assert counter value, histogram buckets, etc.
}
```

---

## 3. Tracing with DataDog dd-trace-go

### Initialization

```go
import "gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"

func main() {
    tracer.Start(
        tracer.WithService("payments-service"),
        tracer.WithEnv(os.Getenv("DD_ENV")),
        tracer.WithServiceVersion(version),
    )
    defer tracer.Stop()
}
```

### Log-Trace Binding

Correlate logs with traces by injecting trace/span IDs:

```go
import (
    "gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
    "gitlab.com/tabby.ai/core/pkg/log"
)

func ProcessPayment(ctx context.Context, p *Payment) error {
    span, ctx := tracer.StartSpanFromContext(ctx, "process.payment")
    defer span.Finish()

    // pkg/log automatically picks up trace context from ctx
    logger.InfoContext(ctx, "processing payment", "payment_id", p.ID)
    // Log output includes dd.trace_id and dd.span_id
}
```

### Auto-Instrumentation via TabbyKits

The following are automatically instrumented when using Tabby's kit libraries:

| Component | Library | What's Traced |
|-----------|---------|---------------|
| gRPC server | `grpckit` | Every incoming RPC |
| gRPC client | `grpckit` | Every outgoing RPC |
| HTTP server | `httpkit` | Every incoming request |
| HTTP client | `httpkit` | Every outgoing request |
| Pub/Sub | `pubsub/v2` | Publish and receive operations |
| PostgreSQL | `postgreskit` | Every query |

### Manual Spans

```go
func ProcessPayment(ctx context.Context, p *Payment) error {
    span, ctx := tracer.StartSpanFromContext(ctx, "process.payment",
        tracer.ResourceName("ProcessPayment"),
        tracer.SpanType("custom"),
    )
    defer span.Finish()

    // Add tags for filtering in DataDog
    span.SetTag("payment.id", p.ID)
    span.SetTag("payment.amount", p.Amount)
    span.SetTag("payment.currency", p.Currency)

    // Child span for sub-operation
    validateSpan, ctx := tracer.StartSpanFromContext(ctx, "validate.payment")
    err := validate(ctx, p)
    validateSpan.Finish(tracer.WithError(err))
    if err != nil {
        return err
    }

    return nil
}
```

### Error Handling in Spans

```go
span, ctx := tracer.StartSpanFromContext(ctx, "charge.card")
defer span.Finish()

result, err := chargeCard(ctx, card, amount)
if err != nil {
    span.SetTag("error", true)
    span.SetTag("error.msg", err.Error())
    span.SetTag("error.type", fmt.Sprintf("%T", err))
    return err
}
```

### Environment Configuration

| Environment | DD Agent | Notes |
|-------------|----------|-------|
| local | `localhost:8126` (Docker Compose) | `DD_ENV=local` |
| review | Cluster agent | `DD_ENV=review` |
| staging | Cluster agent | `DD_ENV=staging` |
| production | Cluster agent | `DD_ENV=production` |

---

## 4. SLO Configuration

### Define SLOs

Create `slo.yaml` at project root:

```yaml
slos:
  - name: "Payment API Availability"
    description: "99.9% of payment API requests return non-5xx responses"
    type: metric
    target: 99.9
    warning: 99.95
    timeframe: 30d
    query:
      numerator: "sum:payments.requests.success{service:payments-service}.as_count()"
      denominator: "sum:payments.requests.total{service:payments-service}.as_count()"
    tags:
      - "service:payments-service"
      - "team:payments"

  - name: "Payment API Latency"
    description: "99% of payment requests complete within 500ms"
    type: metric
    target: 99.0
    timeframe: 30d
    query:
      numerator: "sum:payments.requests.duration.under_500ms{service:payments-service}.as_count()"
      denominator: "sum:payments.requests.total{service:payments-service}.as_count()"
    tags:
      - "service:payments-service"
      - "team:payments"
```

### CI Wiring

```yaml
slo-lint:
  stage: lint
  script:
    - tabbycli slo lint
  rules:
    - changes:
        - slo.yaml

slo-apply:
  stage: deploy
  script:
    - tabbycli slo apply
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      changes:
        - slo.yaml
```

### DataDog Team/Service Mapping

| Field | Convention |
|-------|-----------|
| `service` | `{service-name}` matching `DD_SERVICE` env var |
| `team` | Team slug from DataDog Teams (e.g., `payments`, `orders`) |
| `timeframe` | `7d`, `30d`, or `90d` |
