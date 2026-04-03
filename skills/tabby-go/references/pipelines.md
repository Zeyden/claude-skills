# CI/CD Pipelines Deep-Dive

## 1. Go Docker Images

### Multi-Stage Dockerfile

```dockerfile
# ============================================================
# Build stage
# ============================================================
FROM golang:1.22-bookworm AS builder

# Internal module proxy and private module config
ENV GONOSUMCHECK="gitlab.com/tabby.ai/*"
ENV GONOSUMDB="gitlab.com/tabby.ai/*"
ENV GOPRIVATE="gitlab.com/tabby.ai/*"
ENV GOPROXY="https://athens.internal.tabby.ai,https://proxy.golang.org,direct"

WORKDIR /app

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/service ./cmd/service

# ============================================================
# Runtime stage (secure — production)
# ============================================================
FROM gcr.io/distroless/static-debian12

COPY --from=builder /bin/service /bin/service

ENTRYPOINT ["/bin/service"]
```

### Runner Image Variants

| Variant | Base Image | Shell | Use Case |
|---------|-----------|-------|----------|
| **Secure (distroless)** | `gcr.io/distroless/static-debian12` | No | Production — minimal attack surface |
| **Debug** | `gcr.io/distroless/static-debian12:debug` | Yes (busybox) | Staging — allows `kubectl exec` debugging |
| **Insecure** | `debian:bookworm-slim` | Full | Development — full debugging capability |

### Version Pinning

Always pin Go version and base image digest in production:

```dockerfile
# Pin Go version
FROM golang:1.22.2-bookworm@sha256:abc123... AS builder

# Pin runtime image
FROM gcr.io/distroless/static-debian12@sha256:def456...
```

### Athens Proxy

Athens caches internal GitLab modules, avoiding direct GitLab access from CI:

| Setting | Value | Description |
|---------|-------|-------------|
| `GOPROXY` | `https://athens.internal.tabby.ai,...` | Athens as primary proxy |
| `GOPRIVATE` | `gitlab.com/tabby.ai/*` | Bypass public checksum DB |
| `GONOSUMCHECK` | `gitlab.com/tabby.ai/*` | Skip checksum verification |
| `GONOSUMDB` | `gitlab.com/tabby.ai/*` | Skip sum database lookup |

### Build Optimisations

```dockerfile
# Smaller binary with -ldflags
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /bin/service ./cmd/service
# -s: strip symbol table
# -w: strip DWARF debugging info

# Inject version at build time
ARG VERSION=dev
RUN CGO_ENABLED=0 go build \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /bin/service ./cmd/service
```

---

## 2. Pipeline Linting

### golangci-lint Configuration

Create `.golangci.yml` at project root:

```yaml
run:
  timeout: 5m
  modules-download-mode: readonly

linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - unused
    - gosimple
    - ineffassign
    - typecheck
    - gofmt
    - goimports
    - revive
    - misspell
    - unconvert
    - gocritic
    - nilerr
    - bodyclose
    - exportloopref

linters-settings:
  revive:
    rules:
      - name: exported
        severity: warning
      - name: unexported-return
        severity: warning
  gocritic:
    enabled-tags:
      - diagnostic
      - style
      - performance
  goimports:
    local-prefixes: gitlab.com/tabby.ai

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - errcheck
        - gocritic
```

### Makefile Targets

```makefile
GOLANGCI_LINT_VERSION := v1.57

.PHONY: lint
lint:
	docker run --rm -v $(PWD):/app -w /app \
		golangci/golangci-lint:$(GOLANGCI_LINT_VERSION) \
		golangci-lint run ./...

.PHONY: lint-fix
lint-fix:
	docker run --rm -v $(PWD):/app -w /app \
		golangci/golangci-lint:$(GOLANGCI_LINT_VERSION) \
		golangci-lint run --fix ./...

.PHONY: test
test:
	go test -race -coverprofile=coverage.out ./...

.PHONY: build
build:
	CGO_ENABLED=0 go build -o bin/service ./cmd/service
```

### GitLab CI — Fast Lint Job

```yaml
fast-lint:
  stage: lint
  image: golangci/golangci-lint:v1.57
  script:
    - golangci-lint run ./...
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  cache:
    key: golangci-lint
    paths:
      - .cache/golangci-lint
  variables:
    GOLANGCI_LINT_CACHE: .cache/golangci-lint
```

### Local Development

Install golangci-lint locally for faster feedback:

```bash
# Install
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.57

# Run
golangci-lint run ./...

# Run with auto-fix
golangci-lint run --fix ./...

# Run specific linters
golangci-lint run --enable=govet,errcheck ./...
```

---

## 3. Standard CI Pipeline

### Complete Pipeline Template

```yaml
stages:
  - lint
  - test
  - build
  - deploy

variables:
  GONOSUMCHECK: "gitlab.com/tabby.ai/*"
  GONOSUMDB: "gitlab.com/tabby.ai/*"
  GOPRIVATE: "gitlab.com/tabby.ai/*"
  GOPROXY: "https://athens.internal.tabby.ai,https://proxy.golang.org,direct"

# ──────────────────────────────────
# Lint
# ──────────────────────────────────
fast-lint:
  stage: lint
  image: golangci/golangci-lint:v1.57
  script:
    - golangci-lint run ./...
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

proto-lint:
  stage: lint
  image: bufbuild/buf:latest
  script:
    - buf lint
    - buf breaking --against '.git#branch=main'
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - proto/**/*

# ──────────────────────────────────
# Test
# ──────────────────────────────────
unit-test:
  stage: test
  image: golang:1.22-bookworm
  services:
    - postgres:16
  script:
    - go test -race -coverprofile=coverage.out -count=1 ./...
    - go tool cover -func=coverage.out
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.out
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: "postgres://test:test@postgres:5432/test_db?sslmode=disable"

# ──────────────────────────────────
# Build
# ──────────────────────────────────
docker-build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.9.0-debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      --destination $CI_REGISTRY_IMAGE:latest
      --cache=true
      --cache-repo=$CI_REGISTRY_IMAGE/cache
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

# ──────────────────────────────────
# Deploy
# ──────────────────────────────────
deploy-staging:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/$SERVICE_NAME
        $SERVICE_NAME=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        -n staging
  environment:
    name: staging
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-production:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/$SERVICE_NAME
        $SERVICE_NAME=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        -n production
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
```

### Pipeline Stages Summary

| Stage | Jobs | Trigger |
|-------|------|---------|
| `lint` | `fast-lint`, `proto-lint` | MR events |
| `test` | `unit-test` | MR events, main branch |
| `build` | `docker-build` | Main branch |
| `deploy` | `deploy-staging` (auto), `deploy-production` (manual) | Main branch |

### Caching Strategy

| Cache | Key | Content |
|-------|-----|---------|
| Go modules | `go.sum` hash | `$GOPATH/pkg/mod` |
| golangci-lint | `golangci-lint` | `.cache/golangci-lint` |
| Docker layers | `Dockerfile` hash | Kaniko cache repo |

### Testing Best Practices

```bash
# Run tests with race detector
go test -race ./...

# Run tests with coverage
go test -race -coverprofile=coverage.out -count=1 ./...

# Run specific test
go test -run TestPaymentProcessing ./internal/app/service/...

# Run tests with verbose output
go test -v -run TestPaymentProcessing ./...

# Run integration tests (tagged)
go test -tags=integration ./...
```
