# Используем официальный образ Golang
FROM docker.io/library/golang:1.22.2-alpine AS builder
# Устанавливаем рабочую директорию
WORKDIR /build
# Копируем исходный код приложения в контейнер
COPY ./ ./
RUN CGO_ENABLED=0 go build main.go

# Отдельный этап сборки для уменьшения размера образа
FROM docker.io/library/alpine:3.19.1 AS runner
# Устанавливаем рабочую директорию
WORKDIR /app
# Копируем скомпилированное приложение из предыдущего этапа
COPY --from=builder /build/main ./
# Запускаем healthcheck, проверяющий доступность веб-сервера на порту 8080
HEALTHCHECK --interval=5s --timeout=5s --start-period=3s --retries=3 \
            CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1
# Запускаем приложение при старте контейнера
CMD ["./main"]
