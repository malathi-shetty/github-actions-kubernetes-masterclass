# Stage 1: Build
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Copy dependency files first
COPY go.mod go.sum ./

RUN go mod download

# Copy remaining source
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o skillpulse .

# Stage 2: Runtime
FROM gcr.io/distroless/static

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/skillpulse .

EXPOSE 8080

CMD ["./skillpulse"]
