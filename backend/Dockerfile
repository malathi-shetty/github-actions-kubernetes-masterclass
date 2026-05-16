# =========================
# Stage 1: Builder
# =========================
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Cache dependencies first (better layer caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary for Linux
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o skillpulse .


# =========================
# Stage 2: Runtime (Minimal Image)
# =========================
FROM gcr.io/distroless/static

WORKDIR /

# Copy binary from builder stage
COPY --from=builder /app/skillpulse /skillpulse

# Expose application port
EXPOSE 8080

# Run binary
CMD ["/skillpulse"]
