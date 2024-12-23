# Docker

## Описание приложения

Простой веб сервис написанный на **Go**, возвращающий имя узла.

Сервис можно запустить несколькими способами.

### Локальный запуск

Сборка приложения:

```sh
go build main.go
```

Запуск

```sh
./main
```

Вывод

```output
Сервер запущен на порту 8080...
```

Проверка

```sh
curl localhost:8080
```

Вывод

```output
Имя узла: MacBook-Pro-Fedor.local
```

### Запуск в контейнере

```sh
docker build -t test . && docker run --hostname my_container --publish 8080:8080 test
```

Вывод

```output
Сервер запущен на порту 8080...
```

Проверка

```sh
curl localhost:8080
```

Вывод

```output
Имя узла: my_container
```

### Запуск при помощи docker compose

Запуск

```sh
docker compose --profile blue up --wait --remove-orphans --scale web-blue=3
```

Вывод

```output
✔ Network docker_default          Created
✔ Container docker-web-blue-1     Healthy
✔ Container docker-nginx-proxy-1  Healthy
✔ Container docker-web-blue-3     Healthy
✔ Container docker-web-blue-2     Healthy
```

Проверка

Поскольку запущено несколько реплик сервиса, то при повторной проверке мы можем увидеть разное имена узлов

```sh
declare -A responses
count=0

while [ ${#responses[@]} -lt 3 ]; do
    response=$(curl -s localhost:8080)

    if [[ -z "${responses[$response]}" ]]; then
        responses["$response"]=1
        count=$((count + 1))
        echo "Уникальный ответ $count: $response"
    fi
done
```

Вывод

```output
Уникальный ответ 1: Имя узла: eeec60605b3c
Уникальный ответ 2: Имя узла: 1a0e8d8f0d64
Уникальный ответ 3: Имя узла: d5822762eab6
```

### Сине-зеленое развертывание

Запуск

```sh
bash ./deploy.sh
```

Вывод

```output
Список контейнеров
NAME                   IMAGE                                 COMMAND                  SERVICE       CREATED          STATUS                    PORTS
docker-nginx-proxy-1   nginxproxy/nginx-proxy:1.6.2-alpine   "/app/docker-entrypo…"   nginx-proxy   22 seconds ago   Up 22 seconds (healthy)   0.0.0.0:80->80/tcp
docker-web-green-1     docker-web-green                      "./main"                 web-green     6 seconds ago    Up 6 seconds (healthy)    8080/tcp
docker-web-green-2     docker-web-green                      "./main"                 web-green     6 seconds ago    Up 6 seconds (healthy)    8080/tcp
docker-web-green-3     docker-web-green                      "./main"                 web-green     6 seconds ago    Up 6 seconds (healthy)    8080/tcp
Журналы запуска web-green
web-green-3  | Сервер запущен на порту 8080...
web-green-2  | Сервер запущен на порту 8080...
web-green-1  | Сервер запущен на порту 8080...
```

[Проверка](README.md#L83)
