# Используем официальный образ Golang
FROM golang:1.22.5-alpine AS builder
# Устанавливаем рабочую директорию
WORKDIR /build
# Копируем исходный код приложения в контейнер
COPY ./ ./
# Сборка приложения
RUN CGO_ENABLED=0 go build main.go

# Отдельный этап сборки для уменьшения размера образа
FROM alpine:3.20.1 AS runner
# Определяем аргумент для имени пользователя
ARG USERNAME=appuser
ARG GROUPNAME=appgroup
# Создаем пользователя и группу
RUN addgroup -S ${GROUPNAME} && adduser -S ${USERNAME} -G ${GROUPNAME}
# Устанавливаем рабочую директорию
WORKDIR /app
# Копируем скомпилированное приложение из предыдущего этапа
COPY --from=builder /build/main ./
# Меняем владельца файлов на нового пользователя
RUN chown -R ${USERNAME}:${GROUPNAME} /app
# Запускаем контейнер от имени нового пользователя
USER ${USERNAME}
# Запускаем healthcheck, проверяющий доступность веб-сервера на порту 8080
HEALTHCHECK --interval=5s --timeout=5s --start-period=3s --retries=3 \
            CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1
# Запускаем приложение при старте контейнера
CMD ["./main"]
