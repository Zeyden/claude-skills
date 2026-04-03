# Pub/Sub Deep-Dive

## 1. Google Pub/Sub Adapter

Internal wrapper: `gitlab.com/tabby.ai/core/pkg/pubsub/v2`

### Topic & Subscription Naming

| Resource | Pattern | Example |
|----------|---------|---------|
| Topic | `{service}-{event}-topic` | `payments-created-topic` |
| Subscription | `{service}-{event}-{consumer}-sub` | `payments-created-orders-sub` |
| Dead-letter topic | `{service}-{event}-{consumer}-dead-letter-topic` | `payments-created-orders-dead-letter-topic` |

### Concurrency Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `NumGoroutines` | 10 | Parallel message processing goroutines |
| `MaxOutstandingMessages` | 1000 | Max unprocessed messages buffered |
| `MaxOutstandingBytes` | 1GB | Max unprocessed bytes buffered |

Tune based on handler latency and resource capacity. Start conservative, increase after monitoring.

### Dead-Lettering

Dead-letter topics capture messages that fail after repeated delivery attempts:

```go
m.Subscription("payments-created-orders-sub", pubsub.SubscriptionConfig{
    Topic:               "payments-created-topic",
    DeadLetterTopic:     "payments-created-orders-dead-letter-topic",
    MaxDeliveryAttempts: 5,
})
```

- Set `MaxDeliveryAttempts` to 5 (default recommendation)
- Monitor dead-letter subscription for unprocessed messages
- Create alerts on dead-letter message count > 0

### Publisher Batching

```go
topic := client.Topic("payments-created-topic")
topic.PublishSettings = pubsub.PublishSettings{
    DelayThreshold: 10 * time.Millisecond,   // max wait before sending batch
    CountThreshold: 100,                       // max messages per batch
    ByteThreshold:  1 * 1024 * 1024,          // 1MB max batch size
}
```

### Monitoring

| Metric | Alert Threshold | Description |
|--------|----------------|-------------|
| `subscription/oldest_unacked_message_age` | > 5m | Messages stuck in subscription |
| `subscription/num_undelivered_messages` | > 10k | Backlog growing |
| `subscription/dead_letter_message_count` | > 0 | Failed messages |
| `topic/send_request_count` | anomaly | Publishing rate change |

---

## 2. Publishing Events with AsyncAPI SDK

### Flow

1. Define event contract in AsyncAPI spec
2. Generate SDK: `tabbycli asyncapi generate-sdk --lang go`
3. Create publisher with transport and middleware
4. Publish typed events

### Transport Setup

```go
import (
    "gitlab.com/tabby.ai/core/sdk/events/payments/v1"
    "gitlab.com/tabby.ai/core/pkg/pubsub/v2"
)

func NewPublisher(client *pubsub.Client, logger *log.Logger, meter metric.Meter) payments.Publisher {
    transport := pubsub.NewTransport(client)
    return payments.NewPublisher(transport,
        payments.WithPublisherMiddleware(
            middleware.Logging(logger),
            middleware.Tracing(),
            middleware.Metrics(meter),
        ),
    )
}
```

### Publishing

```go
err := publisher.PublishPaymentCreated(ctx, &payments.PaymentCreated{
    PaymentId: "pay_123",
    Amount:    10000,
    Currency:  "AED",
    CreatedAt: timestamppb.Now(),
})
if err != nil {
    logger.Error("failed to publish event", "error", err)
}
```

### Environment-Specific Topic Mapping

The SDK maps logical channel names to physical topics per environment. Configure via environment variables or config files:

| Environment | Topic Pattern |
|-------------|--------------|
| local | `local-{channel}-topic` |
| review | `review-{branch}-{channel}-topic` |
| staging | `staging-{channel}-topic` |
| production | `{channel}-topic` |

---

## 3. Subscribing to Events with SDK

### Handler Interface

The generated SDK produces a handler interface per channel:

```go
type PaymentEventsHandler interface {
    HandlePaymentCreated(ctx context.Context, event *PaymentCreated) error
    HandlePaymentRefunded(ctx context.Context, event *PaymentRefunded) error
}
```

### Registering Handlers

```go
type PaymentHandler struct {
    orderSvc *service.Orders
}

func (h *PaymentHandler) HandlePaymentCreated(ctx context.Context, event *payments.PaymentCreated) error {
    return h.orderSvc.ConfirmPayment(ctx, event.PaymentId, event.Amount)
}

func (h *PaymentHandler) HandlePaymentRefunded(ctx context.Context, event *payments.PaymentRefunded) error {
    return h.orderSvc.ProcessRefund(ctx, event.PaymentId)
}

func main() {
    transport := pubsub.NewTransport(client)
    subscriber := payments.NewSubscriber(transport,
        payments.WithSubscriberMiddleware(
            middleware.Logging(logger),
            middleware.Recovery(),
            middleware.Tracing(),
        ),
    )
    subscriber.Register(&PaymentHandler{orderSvc: orderSvc})

    if err := subscriber.Start(ctx); err != nil {
        logger.Error("subscriber stopped", "error", err)
    }
}
```

### Legacy Codec

For backward compatibility with non-SDK publishers:

```go
subscriber := payments.NewSubscriber(transport,
    payments.WithCodec(legacy.NewCodec()),
)
```

### DummyHandlers Pattern

When subscribing to a channel but only caring about some events:

```go
type MyHandler struct {
    payments.DummyHandlers // no-op for events you don't handle
}

// Only implement the events you care about
func (h *MyHandler) HandlePaymentCreated(ctx context.Context, event *payments.PaymentCreated) error {
    // process
    return nil
}
// HandlePaymentRefunded is a no-op from DummyHandlers
```

---

## 4. Outbox Pattern

Use when events must be published atomically with database changes (exactly-once semantics).

### How It Works

1. Business logic writes to the database and inserts events into `outbox_events` table — in the same transaction
2. An outbox processor polls the table and publishes events to Pub/Sub
3. Published events are marked as processed

### Schema

```sql
CREATE TABLE outbox_events (
    id          BIGSERIAL PRIMARY KEY,
    event_type  TEXT NOT NULL,
    payload     JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed   BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ
);
CREATE INDEX idx_outbox_unprocessed ON outbox_events(processed, created_at)
    WHERE NOT processed;
```

### Usage

```go
// Within a transaction — both writes are atomic
tx, _ := db.Begin(ctx)

// Business logic
tx.Exec(ctx, "INSERT INTO orders (id, customer_id, amount) VALUES ($1, $2, $3)",
    orderID, customerID, amount)

// Publish event via outbox (same transaction)
outbox.Publish(ctx, tx, &events.OrderCreated{
    OrderId:    orderID,
    CustomerId: customerID,
    Amount:     amount,
})

tx.Commit(ctx)
// Both the order and the event are committed atomically
```

### Processor Configuration

```go
processor := outbox.NewProcessor(outbox.Config{
    DB:            db,
    PollInterval:  1 * time.Second,
    BatchSize:     100,
    Publisher:      publisher,
    RetryAttempts: 3,
})
go processor.Start(ctx)
```

### Routing

Map event types to Pub/Sub topics:

```go
router := outbox.NewRouter()
router.Route("OrderCreated", "orders-created-topic")
router.Route("OrderCancelled", "orders-cancelled-topic")
```

### Monitoring

| Metric | Description |
|--------|-------------|
| `outbox_events_pending` | Unprocessed events (gauge) |
| `outbox_processor_lag_seconds` | Time since oldest unprocessed event |
| `outbox_publish_errors_total` | Failed publish attempts |
| `outbox_processed_total` | Successfully published events |

---

## 5. Pub/Sub Config Management

### Manager Pattern

Declare all topics and subscriptions in code:

```go
func NewManager() *pubsub.Manager {
    m := pubsub.NewManager()

    m.Topic("payments-created-topic", pubsub.TopicConfig{
        Labels: map[string]string{"team": "payments", "domain": "payments"},
    })

    m.Subscription("payments-created-orders-sub", pubsub.SubscriptionConfig{
        Topic:               "payments-created-topic",
        AckDeadline:         30 * time.Second,
        RetryPolicy: pubsub.RetryPolicy{
            MinBackoff: 10 * time.Second,
            MaxBackoff: 600 * time.Second,
        },
        DeadLetterTopic:     "payments-created-orders-dead-letter-topic",
        MaxDeliveryAttempts: 5,
    })

    m.Topic("payments-created-orders-dead-letter-topic", pubsub.TopicConfig{
        Labels: map[string]string{"team": "payments", "type": "dead-letter"},
    })

    return m
}
```

### Makefile Targets

```makefile
.PHONY: pubsub-apply
pubsub-apply:
	docker run --rm \
		-v $(PWD):/app \
		-e GOOGLE_APPLICATION_CREDENTIALS=/app/sa.json \
		-e PUBSUB_PROJECT_ID=$(PROJECT_ID) \
		pubsub-manager apply

.PHONY: pubsub-plan
pubsub-plan:
	docker run --rm \
		-v $(PWD):/app \
		-e GOOGLE_APPLICATION_CREDENTIALS=/app/sa.json \
		-e PUBSUB_PROJECT_ID=$(PROJECT_ID) \
		pubsub-manager plan
```

### CI Template

```yaml
pubsub-config:
  stage: deploy
  image: pubsub-manager:latest
  script:
    - pubsub-manager apply
  environment:
    name: $CI_ENVIRONMENT_NAME
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success
```

### Environment Hierarchy

| Environment | Project | Notes |
|-------------|---------|-------|
| local | `local-project` | Emulator, auto-created |
| review | `review-project` | Per-branch, ephemeral |
| staging | `staging-project` | Mirrors prod config |
| production | `prod-project` | Managed via CI only |

---

## 6. AsyncAPI Migration (pubsubkit)

### Migration Strategy

1. **Publisher first**: Replace raw Pub/Sub publishers with AsyncAPI SDK publishers
2. **Subscriber second**: Replace raw subscribers with SDK handlers
3. **Parallel running**: Both old and new can coexist during migration

### pubsubkit Reflection

Test codec compatibility:

```go
import "gitlab.com/tabby.ai/core/pkg/pubsubkit"

func TestCodecCompatibility(t *testing.T) {
    oldMsg := legacyEncode(&OldPaymentEvent{ID: "123"})
    newEvent, err := pubsubkit.Decode[*payments.PaymentCreated](oldMsg)
    require.NoError(t, err)
    assert.Equal(t, "123", newEvent.PaymentId)
}
```

### SDK Replacement Checklist

1. Generate SDK from AsyncAPI spec
2. Replace publisher instantiation with SDK publisher
3. Update handler to implement SDK interface
4. Add `DummyHandlers` for unhandled events
5. Test with legacy codec for backward compatibility
6. Remove legacy code after full migration
