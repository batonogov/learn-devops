# Используем официальный образ Golang
FROM golang:1.23.3-alpine AS builder
# Устанавливаем рабочую директорию
WORKDIR /build
# Копируем исходный код приложения в контейнер
COPY ./main.go ./
# Сборка приложения
RUN CGO_ENABLED=0 go build main.go

# # Отдельный этап сборки для уменьшения размера образа
# FROM alpine:3.20.3 AS runner
# # Определяем аргумент для имени пользователя
# ARG USERNAME=appuser
# ARG GROUPNAME=appgroup
# # Создаем пользователя и группу
# RUN addgroup -S ${GROUPNAME} && adduser -S ${USERNAME} -G ${GROUPNAME}
# # Устанавливаем рабочую директорию
# WORKDIR /app
# # Копируем скомпилированное приложение из предыдущего этапа
# COPY --from=builder /build/main ./
# # Меняем владельца файлов на нового пользователя
# RUN chown -R ${USERNAME}:${GROUPNAME} /app
# # Запускаем контейнер от имени нового пользователя
# USER ${USERNAME}
# # Запускаем healthcheck, проверяющий доступность веб-сервера на порту 8080
# HEALTHCHECK --interval=5s --timeout=5s --start-period=3s --retries=3 \
#             CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1
# # Запускаем приложение при старте контейнера
# CMD ["./main"]

# Отдельный этап сборки для уменьшения размера образа
FROM scratch
# Создаем пользователя
USER 100:100
# Копируем скомпилированное приложение из предыдущего этапа
COPY --from=builder --chown=100:100 /build/main /
# Копируем curl для работы HEALTHCHECK
COPY --from=ghcr.io/tarampampam/curl:8.10.1 /bin/curl /bin/curl
# Запускаем healthcheck, проверяющий доступность веб-сервера на порту 8080
HEALTHCHECK --interval=5s --timeout=5s --start-period=3s --retries=3 \
            CMD [ "curl", "--fail", "http://127.0.0.1:8080/" ]
# Запускаем приложение при старте контейнера
ENTRYPOINT ["/main"]
