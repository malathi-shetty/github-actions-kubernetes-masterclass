FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o skillpulse .


FROM gcr.io/distroless/static

WORKDIR /

COPY --from=builder /app/skillpulse /skillpulse

EXPOSE 8080

CMD ["/skillpulse"]
