---
name: containerization
description: >-
  Создает многоэтапные Dockerfiles, docker-compose файлы, оптимизирует вес слоев и изолирует окружения разработки.
---

# Контейнеризация и окружения (Containerization)

Данный навык упаковывает приложения и сервисы в стандартизированные изолированные контейнеры.

## Стандарты Multi-stage Dockerfile
```dockerfile
# Сборка
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o server .

# Релизный легковесный контейнер
FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/server .
USER 10001
CMD ["./server"]
```
- Использование непривилегированного пользователя (`USER nonroot`).
- Минимизация слоев и размера итогового образа.
