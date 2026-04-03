# Platform Services Deep-Dive

## 1. Feature Flags with OpenFeature + ffkit

Import: `gitlab.com/tabby.ai/core/pkg/ffkit`

### Setup

```go
import "gitlab.com/tabby.ai/core/pkg/ffkit"

// Create client (typically once at startup)
client := ffkit.NewClient()
```

### Evaluating Flags

```go
// Boolean flag
enabled, err := client.BooleanValue(ctx, "new-checkout-flow", false,
    ffkit.EvalContext{
        TargetingKey: userID,
        Attributes: map[string]interface{}{
            "country":  "AE",
            "platform": "ios",
            "version":  "3.2.0",
        },
    },
)
if enabled {
    // new flow
} else {
    // existing flow
}

// String flag (e.g., A/B test variant)
variant, _ := client.StringValue(ctx, "checkout-variant", "control",
    ffkit.EvalContext{TargetingKey: userID},
)

// Integer flag (e.g., rate limit override)
limit, _ := client.IntValue(ctx, "api-rate-limit", 100,
    ffkit.EvalContext{TargetingKey: merchantID},
)

// Float flag
percentage, _ := client.FloatValue(ctx, "discount-percentage", 0.0,
    ffkit.EvalContext{TargetingKey: userID},
)
```

### Evaluation Context

| Attribute | Type | Description |
|-----------|------|-------------|
| `TargetingKey` | string | Primary identifier (user ID, merchant ID) |
| `country` | string | ISO country code for geo-targeting |
| `platform` | string | `ios`, `android`, `web` |
| `version` | string | Client app version for version-based rollout |
| Custom attributes | any | Additional context for targeting rules |

### ff-agent Deployment

The `ff-agent` runs as a sidecar or standalone service that caches flag evaluations:

| Mode | Architecture | Use Case |
|------|-------------|----------|
| Sidecar | Pod-level, localhost access | Standard services |
| Standalone | Shared deployment | Serverless, batch jobs |

```yaml
# Kubernetes sidecar
containers:
  - name: ff-agent
    image: ff-agent:latest
    ports:
      - containerPort: 8013
    env:
      - name: FF_SOURCE
        value: "https://flags.internal.tabby.ai"
```

### Local Development with Flagd

Use Flagd with a file-based flag source for local development:

```json
{
  "flags": {
    "new-checkout-flow": {
      "state": "ENABLED",
      "variants": {
        "on": true,
        "off": false
      },
      "defaultVariant": "off",
      "targeting": {
        "if": [
          { "in": ["$country", ["AE", "SA"]] },
          "on",
          "off"
        ]
      }
    }
  }
}
```

```bash
# Run Flagd locally
docker run -p 8013:8013 -v $(PWD)/flags.json:/flags.json \
    ghcr.io/open-feature/flagd:latest start --uri file:/flags.json
```

### Testing Feature Flags

```go
import "gitlab.com/tabby.ai/core/pkg/ffkit/fftest"

func TestNewCheckoutFlow(t *testing.T) {
    // Mock provider that returns specific values
    provider := fftest.NewMockProvider(map[string]interface{}{
        "new-checkout-flow": true,
    })
    client := ffkit.NewClient(ffkit.WithProvider(provider))

    svc := NewService(client)
    result := svc.Checkout(ctx, order)

    assert.True(t, result.UsedNewFlow)
}
```

---

## 2. Authorization for Internal Portals

### Architecture

```
User (Google OIDC)
    │
    ▼
┌───────────┐     ┌───────────┐     ┌───────────┐
│  Portal   │────▶│    PEP    │────▶│    PDP    │
│  (Web UI) │     │(Enforcer) │     │ (Casbin)  │
└───────────┘     └───────────┘     └───────────┘
                                          │
                                    ┌─────▼─────┐
                                    │  Policy   │
                                    │  Syncer   │
                                    │  (Google  │
                                    │  Groups)  │
                                    └───────────┘
```

- **PEP** (Policy Enforcement Point): Middleware that checks permissions before handler execution
- **PDP** (Policy Decision Point): Casbin engine that evaluates policies
- **Policy Syncer**: Maps Google Groups to Casbin roles

### Google OIDC Authentication

```go
import "gitlab.com/tabby.ai/core/pkg/auth"

// Middleware: validates Google OIDC token
authMiddleware := auth.GoogleOIDC(auth.Config{
    AllowedDomains: []string{"tabby.ai"},
})

// Extract user info from context
user := auth.UserFromContext(ctx)
fmt.Println(user.Email)  // "engineer@tabby.ai"
fmt.Println(user.Groups) // ["payments-team@tabby.ai", "engineering@tabby.ai"]
```

### Casbin Model

```ini
[request_definition]
r = sub, obj, act

[policy_definition]
p = sub, obj, act

[role_definition]
g = _, _

[policy_effect]
e = some(where (p.eft == allow))

[matchers]
m = g(r.sub, p.sub) && r.obj == p.obj && r.act == p.act
```

### Policy Definition

```csv
# Role permissions
p, admin, /api/payments, read
p, admin, /api/payments, write
p, admin, /api/refunds, read
p, admin, /api/refunds, write
p, viewer, /api/payments, read
p, viewer, /api/refunds, read

# Google Groups → Roles
g, payments-team@tabby.ai, admin
g, support@tabby.ai, viewer
g, finance@tabby.ai, viewer
```

### Enforcer Setup

```go
import "gitlab.com/tabby.ai/core/pkg/auth/casbin"

enforcer, err := casbin.NewEnforcer(casbin.Config{
    ModelPath:  "model.conf",
    PolicyPath: "policy.csv",
    SyncInterval: 5 * time.Minute, // re-sync policies from source
})

// Check permission
allowed, err := enforcer.Enforce(user.Email, "/api/payments", "write")
if !allowed {
    return status.Errorf(codes.PermissionDenied, "insufficient permissions")
}
```

### Policy Syncer

Automatically syncs Google Groups membership to Casbin roles:

```go
syncer := casbin.NewPolicySyncer(casbin.SyncConfig{
    GoogleAdminEmail: "admin@tabby.ai",
    GroupMappings: map[string]string{
        "payments-team@tabby.ai": "admin",
        "support@tabby.ai":       "viewer",
        "finance@tabby.ai":       "viewer",
    },
    SyncInterval: 5 * time.Minute,
})
go syncer.Start(ctx)
```

### Infrastructure Setup

```yaml
# Kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portal
spec:
  template:
    spec:
      serviceAccountName: portal-sa
      containers:
        - name: portal
          env:
            - name: GOOGLE_OIDC_CLIENT_ID
              valueFrom:
                secretKeyRef:
                  name: portal-secrets
                  key: oidc-client-id
```

---

## 3. Custom Authorization Models

### When RBAC Isn't Enough

Use custom authorization when:

- Resource-level permissions (merchant can only see their data)
- Multi-tenant isolation
- Dynamic permission rules based on business logic

### ACL Layer + Custom Casbin Policies

```ini
[request_definition]
r = sub, dom, obj, act

[policy_definition]
p = sub, dom, obj, act

[role_definition]
g = _, _, _

[matchers]
m = g(r.sub, p.sub, r.dom) && r.dom == p.dom && r.obj == p.obj && r.act == p.act
```

```csv
# Merchant-scoped permissions
p, merchant_admin, merchant_123, /orders, read
p, merchant_admin, merchant_123, /orders, write
p, merchant_viewer, merchant_123, /orders, read

# User → Role in domain
g, merchant_user@example.com, merchant_admin, merchant_123
g, support_agent@tabby.ai, merchant_viewer, merchant_123
```

### Policy Management API

```go
// Add permission dynamically
enforcer.AddPolicy("merchant_admin", "merchant_456", "/orders", "read")

// Remove permission
enforcer.RemovePolicy("merchant_viewer", "merchant_123", "/orders", "read")

// Check with domain
allowed, _ := enforcer.Enforce(userEmail, merchantID, "/orders", "write")
```

---

## 4. Localization with l10nkit

Import: `gitlab.com/tabby.ai/core/pkg/l10nkit`

### Setup

```go
import "gitlab.com/tabby.ai/core/pkg/l10nkit"

localizer := l10nkit.New(l10nkit.Config{
    DefaultLanguage:  "en",
    FallbackLanguage: "en",
    ServiceURL:       os.Getenv("LOCALIZATION_SERVICE_URL"),
})
```

### Basic Usage

```go
// Simple translation
text, err := localizer.Localize(ctx, "welcome.message",
    l10nkit.Params{"name": userName},
    l10nkit.WithLanguage("ar"),
)
// "welcome.message" key with {name} placeholder
// English: "Hello, {name}!"
// Arabic:  "!{name} ،مرحبا"
```

### Plural Forms

```go
text, _ := localizer.Localize(ctx, "items.count",
    l10nkit.Params{"count": 3},
    l10nkit.WithLanguage("ar"),
)
// Handles Arabic plural rules:
// 0: "لا عناصر"
// 1: "عنصر واحد"
// 2: "عنصران"
// 3-10: "3 عناصر"
// 11-99: "42 عنصرا"
// 100+: "100 عنصر"
```

### Lokalise Integration

| Component | Purpose |
|-----------|---------|
| Lokalise platform | Translation management, translator workflows |
| `layout` tag | Tags keys used in BDUI layouts |
| Export to service | Localization service caches translations at runtime |
| Import from Lokalise | `tabbycli l10n import` syncs translations |

### Local Development

Use a local translations file for development:

```json
{
  "en": {
    "welcome.message": "Hello, {name}!",
    "items.count": "{count} items"
  },
  "ar": {
    "welcome.message": "!{name} ،مرحبا",
    "items.count": "{count} عناصر"
  }
}
```

```go
localizer := l10nkit.New(l10nkit.Config{
    DefaultLanguage: "en",
    LocalFile:       "translations.json", // file-based for local dev
})
```

### Supported Languages

| Code | Language | Plural Forms |
|------|----------|-------------|
| `en` | English | one, other |
| `ar` | Arabic | zero, one, two, few, many, other |
| `fr` | French | one, other |
| `tr` | Turkish | one, other |
| `ur` | Urdu | one, other |

---

## 5. Temporal Workflows

### When to Use Temporal

| Use Case | Why Temporal |
|----------|-------------|
| Multi-step payment flows | Durable state, automatic retries |
| Scheduled operations | Cron workflows, delayed execution |
| Long-running processes | Can wait hours/days, survives restarts |
| Saga patterns | Compensating transactions on failure |
| Human-in-the-loop | Wait for external signals/approvals |

### Workflow Example

```go
import (
    "go.temporal.io/sdk/workflow"
    "go.temporal.io/sdk/temporal"
)

func PaymentWorkflow(ctx workflow.Context, input PaymentInput) error {
    options := workflow.ActivityOptions{
        StartToCloseTimeout: 30 * time.Second,
        RetryPolicy: &temporal.RetryPolicy{
            InitialInterval:    1 * time.Second,
            BackoffCoefficient: 2.0,
            MaximumAttempts:    3,
        },
    }
    ctx = workflow.WithActivityOptions(ctx, options)

    // Step 1: Charge the card
    var chargeResult ChargeResult
    err := workflow.ExecuteActivity(ctx, ChargeActivity, input).Get(ctx, &chargeResult)
    if err != nil {
        // Compensate: notify about failure
        _ = workflow.ExecuteActivity(ctx, NotifyFailureActivity, input).Get(ctx, nil)
        return err
    }

    // Step 2: Send receipt
    err = workflow.ExecuteActivity(ctx, SendReceiptActivity, input, chargeResult).Get(ctx, nil)
    if err != nil {
        // Receipt is non-critical, log and continue
        workflow.GetLogger(ctx).Warn("failed to send receipt", "error", err)
    }

    return nil
}
```

### Activity Implementation

```go
func ChargeActivity(ctx context.Context, input PaymentInput) (ChargeResult, error) {
    // Activities contain the actual side-effect logic
    result, err := paymentGateway.Charge(ctx, input.CardToken, input.Amount)
    if err != nil {
        return ChargeResult{}, err
    }
    return ChargeResult{TransactionID: result.ID}, nil
}
```

### Worker Setup

```go
import (
    "go.temporal.io/sdk/client"
    "go.temporal.io/sdk/worker"
)

func main() {
    c, err := client.Dial(client.Options{
        HostPort:  os.Getenv("TEMPORAL_HOST"),
        Namespace: "payments",
    })
    if err != nil {
        log.Fatal("failed to connect to Temporal", "error", err)
    }
    defer c.Close()

    w := worker.New(c, "payments-task-queue", worker.Options{
        MaxConcurrentActivityExecutionSize:     10,
        MaxConcurrentWorkflowTaskExecutionSize: 10,
    })

    // Register workflows and activities
    w.RegisterWorkflow(PaymentWorkflow)
    w.RegisterActivity(ChargeActivity)
    w.RegisterActivity(SendReceiptActivity)
    w.RegisterActivity(NotifyFailureActivity)

    if err := w.Run(worker.InterruptCh()); err != nil {
        log.Fatal("worker failed", "error", err)
    }
}
```

### Starting a Workflow

```go
// From another service or handler
we, err := temporalClient.ExecuteWorkflow(ctx,
    client.StartWorkflowOptions{
        ID:        fmt.Sprintf("payment-%s", paymentID),
        TaskQueue: "payments-task-queue",
    },
    PaymentWorkflow,
    input,
)
if err != nil {
    return err
}

// Optionally wait for result
var result PaymentResult
err = we.Get(ctx, &result)
```

### Infrastructure Configuration

```yaml
# Temporal namespace registration
temporal operator namespace create \
    --namespace payments \
    --retention 7d \
    --description "Payments domain workflows"
```

### Local Development

```bash
# Start Temporal dev server
temporal server start-dev --namespace payments

# Start worker
go run ./cmd/worker

# Start workflow via CLI
temporal workflow start \
    --task-queue payments-task-queue \
    --type PaymentWorkflow \
    --input '{"amount": 10000, "currency": "AED"}'

# View workflow status
temporal workflow show --workflow-id payment-pay_123
```

### Namespace Configuration

| Environment | Temporal Host | Namespace |
|-------------|--------------|-----------|
| local | `localhost:7233` | `payments` (dev server) |
| review | `temporal.review.internal:7233` | `payments-review` |
| staging | `temporal.staging.internal:7233` | `payments-staging` |
| production | Temporal Cloud or `temporal.prod.internal:7233` | `payments` |
