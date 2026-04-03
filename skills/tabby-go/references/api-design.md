# API Design Deep-Dive

## 1. Protobuf Layout Requirements

### Directory Structure

```
proto/
├── tabby/
│   ├── payments/
│   │   └── v1/
│   │       ├── payment.proto           # Message definitions
│   │       ├── payment_service.proto   # Service definition
│   │       └── common.proto            # Shared types within domain
│   └── orders/
│       └── v1/
│           ├── order.proto
│           └── order_service.proto
├── buf.yaml
├── buf.gen.yaml
└── buf.lock
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Package | `tabby.{domain}.{version}` | `tabby.payments.v1` |
| Service | `{Domain}Service` | `PaymentsService` |
| RPC | `Verb{Resource}` | `CreatePayment`, `GetPayment`, `ListPayments` |
| Message | `{Verb}{Resource}Request/Response` | `CreatePaymentRequest` |
| File | `{resource}.proto` or `{resource}_service.proto` | `payment_service.proto` |

### Package Declaration

```protobuf
syntax = "proto3";

package tabby.payments.v1;

option go_package = "gitlab.com/tabby.ai/core/sdk/payments/v1;paymentsv1";

import "google/protobuf/timestamp.proto";
import "google/protobuf/wrappers.proto";
```

### Versioning Rules

| Change Type | Action |
|-------------|--------|
| Add field | Add to existing package (backward compatible) |
| Add RPC | Add to existing service (backward compatible) |
| Remove/rename field | Deprecate, create v2 package |
| Change field type | Create v2 package |
| Semantic change | Create v2 package |

### Standard Patterns

```protobuf
// Pagination
message ListPaymentsRequest {
    int32 page_size = 1;
    string page_token = 2;
}

message ListPaymentsResponse {
    repeated Payment payments = 1;
    string next_page_token = 2;
}

// Field mask for partial updates
message UpdatePaymentRequest {
    Payment payment = 1;
    google.protobuf.FieldMask update_mask = 2;
}
```

---

## 2. Proto SDK Building

### Generate Code

```bash
tabbycli proto generate
```

This runs `buf generate` with the project's `buf.gen.yaml` configuration.

### buf.yaml

```yaml
version: v2
modules:
  - path: proto
    name: buf.build/tabby/payments
lint:
  use:
    - DEFAULT
  except:
    - PACKAGE_VERSION_SUFFIX
breaking:
  use:
    - FILE
```

### buf.gen.yaml

```yaml
version: v2
plugins:
  - remote: buf.build/protocolbuffers/go
    out: gen/go
    opt:
      - paths=source_relative
  - remote: buf.build/grpc/go
    out: gen/go
    opt:
      - paths=source_relative
```

### Dependencies with proto.deps.hcl

Declare proto dependencies for SDK generation:

```hcl
dependency "google-apis" {
  source  = "buf.build/googleapis/googleapis"
  version = "v1"
}

dependency "common-types" {
  source  = "buf.build/tabby/common"
  version = "v1"
}
```

### Publishing SDKs

```bash
# Lint before publishing
buf lint

# Check breaking changes against main branch
buf breaking --against '.git#branch=main'

# Push to BSR (Buf Schema Registry)
buf push
```

---

## 3. API Gateway (Caddy-based)

Caddy serves as the unified API gateway for all Tabby services.

### Bootstrap

```bash
tabbycli gateway init --service payments
```

Generates a Caddyfile and deployment configuration.

### Caddyfile Routing

```
{
    order rate_limit before reverse_proxy
}

:8080 {
    # gRPC service routing
    @payments path /tabby.payments.v1.PaymentsService/*
    reverse_proxy @payments payments-service:9090 {
        transport http {
            versions h2c
        }
    }

    @orders path /tabby.orders.v1.OrdersService/*
    reverse_proxy @orders orders-service:9090 {
        transport http {
            versions h2c
        }
    }

    # Health check endpoint
    handle /health {
        respond "OK" 200
    }
}
```

### gRPC Proxying

Key configuration for gRPC through Caddy:

| Setting | Value | Purpose |
|---------|-------|---------|
| `transport http` | — | Use HTTP transport (not FastCGI) |
| `versions h2c` | — | HTTP/2 cleartext (gRPC requirement) |
| Path matching | `/package.Service/*` | gRPC uses `/{package}.{Service}/{Method}` paths |

### gRPC Reflection

Enable reflection on backend services for debugging:

```go
import "google.golang.org/grpc/reflection"

srv := grpc.NewServer()
reflection.Register(srv) // enables grpcurl, grpcui, etc.
```

### CORS Configuration

```
:8080 {
    header {
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "POST, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization, X-Grpc-Web"
        Access-Control-Max-Age 86400
    }

    @options method OPTIONS
    handle @options {
        respond "" 204
    }
}
```

### Testing Gateway Locally

```bash
# Start gateway
docker compose up gateway

# Test gRPC via gateway
grpcurl -plaintext localhost:8080 tabby.payments.v1.PaymentsService/GetPayment

# Test with grpcui (web UI)
grpcui -plaintext localhost:8080
```

### Deployment

- Gateway runs as a Kubernetes Deployment with a Service
- Horizontal Pod Autoscaler based on CPU/connections
- ConfigMap for Caddyfile (hot-reload supported)
- Ingress routes external traffic to gateway

### Monitoring

| Metric | Source | Description |
|--------|--------|-------------|
| Request rate | Caddy metrics | Requests per second per route |
| Error rate | Caddy metrics | 4xx/5xx responses per route |
| Latency | Caddy metrics | p50/p95/p99 per route |
| Active connections | Caddy metrics | Current open connections |

---

## 4. Rate Limiting

### Zones

Define rate limit buckets:

```
rate_limit {
    zone payments_create {
        key    {header.x-api-key}
        rate   100/m
        burst  10
    }

    zone payments_read {
        key    {header.x-api-key}
        rate   1000/m
        burst  50
    }

    zone global_expensive {
        key    static
        rate   500/m
    }
}
```

### Keys

| Key Type | Expression | Use Case |
|----------|-----------|----------|
| API key | `{header.x-api-key}` | Per-client limiting |
| IP address | `{remote_host}` | Anonymous rate limiting |
| User ID | `{header.x-user-id}` | Per-user limiting |
| Static | `static` | Global rate limiting |
| gRPC metadata | `{header.x-grpc-metadata}` | gRPC client limiting |

### gRPC-Aware Errors

When rate limited, the gateway returns gRPC `ResourceExhausted` (code 8):

```
grpc-status: 8
grpc-message: rate limit exceeded
```

Clients should implement exponential backoff on `ResourceExhausted`.

### Scenario: Per-Client Rate Limiting

```
@payments_create {
    path /tabby.payments.v1.PaymentsService/CreatePayment
}
rate_limit @payments_create {
    zone payments_create
}
```

### Scenario: Global Rate Limiting for Expensive Operations

```
@batch_export {
    path /tabby.reports.v1.ReportsService/ExportBatch
}
rate_limit @batch_export {
    zone global_expensive
}
```

### Scenario: gRPC Metadata Extractor

```
@authenticated {
    header X-Merchant-Id *
}
rate_limit @authenticated {
    zone merchant_rate {
        key {header.x-merchant-id}
        rate 200/m
    }
}
```

### Best Practices

| Practice | Description |
|----------|-------------|
| Start generous | Begin with high limits, tighten after monitoring |
| Separate read/write | Higher limits for reads, lower for writes |
| Burst allowance | Allow short bursts (2-5x rate) for legitimate spikes |
| Return Retry-After | Include when to retry in error response |
| Monitor before enforcing | Log rate limit hits before blocking |
| Per-client defaults | Apply defaults, allow overrides for trusted clients |

---

## 5. AsyncAPI for Event-Driven Architecture

### AsyncAPI Specification

```yaml
asyncapi: 2.6.0
info:
  title: Payments Events
  version: 1.0.0
  description: Payment domain events

channels:
  payments.created:
    description: Emitted when a payment is created
    publish:
      operationId: publishPaymentCreated
      message:
        name: PaymentCreated
        schemaFormat: 'application/vnd.google.protobuf'
        payload:
          $ref: 'tabby/payments/v1/events.proto#PaymentCreated'
    bindings:
      googlepubsub:
        topic: payments-created-topic

  payments.refunded:
    description: Emitted when a payment is refunded
    publish:
      operationId: publishPaymentRefunded
      message:
        name: PaymentRefunded
        schemaFormat: 'application/vnd.google.protobuf'
        payload:
          $ref: 'tabby/payments/v1/events.proto#PaymentRefunded'
    bindings:
      googlepubsub:
        topic: payments-refunded-topic
```

### Channel Naming

| Pattern | Example | Description |
|---------|---------|-------------|
| `{domain}.{event}` | `payments.created` | Standard domain event |
| `{domain}.{entity}.{event}` | `payments.invoice.generated` | Entity-specific event |

### Proto Schema Rules

- Event messages defined in `events.proto` within the domain package
- Each event must have a unique message type
- Include timestamp, entity ID, and relevant context
- Use `google.protobuf.Timestamp` for timestamps

---

## 6. AsyncAPI Pub/Sub SDK Generator

### Generate SDK

```bash
tabbycli asyncapi generate-sdk --lang go --spec asyncapi.yaml --output sdk/events/payments/v1
```

### Generated Publisher

```go
// Generated interface
type Publisher interface {
    PublishPaymentCreated(ctx context.Context, event *PaymentCreated) error
    PublishPaymentRefunded(ctx context.Context, event *PaymentRefunded) error
}

// Usage
publisher := payments.NewPublisher(transport,
    payments.WithPublisherMiddleware(
        middleware.Logging(logger),
        middleware.Tracing(),
    ),
)
```

### Generated Subscriber

```go
// Generated handler interface
type Handler interface {
    HandlePaymentCreated(ctx context.Context, event *PaymentCreated) error
    HandlePaymentRefunded(ctx context.Context, event *PaymentRefunded) error
}

// Usage
subscriber := payments.NewSubscriber(transport)
subscriber.Register(myHandler)
subscriber.Start(ctx)
```

---

## 7. API Registry and Backstage Integration

### Service Registration

Each service registers its API in the Backstage catalog:

```yaml
# catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: payments-api
  description: Payments service gRPC API
  tags:
    - grpc
    - payments
spec:
  type: grpc
  lifecycle: production
  owner: team-payments
  definition:
    $text: proto/tabby/payments/v1/payment_service.proto
```

### What Gets Registered

| Type | Source | Description |
|------|--------|-------------|
| gRPC APIs | Proto definitions | Service methods, request/response types |
| Events | AsyncAPI specs | Event channels, message schemas |
| REST APIs | OpenAPI specs (if any) | HTTP endpoints |

### Benefits

- Service discovery: find who owns what API
- Dependency tracking: see who consumes your events
- Documentation: auto-generated from proto/AsyncAPI specs
- Breaking change detection: CI checks against registry
