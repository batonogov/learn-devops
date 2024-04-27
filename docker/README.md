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

### Запуск в контейнере

```sh
docker build -t test . && docker run test
```

Вывод

```output
Сервер запущен на порту 8080...
```

### Запуск при помощи docker compose

Запуск

```sh
docker compose --profile blue up --wait --remove-orphans --scale web-blue=5
```

Вывод

```output
 ✔ Network docker_default          Created          0.0s 
 ✔ Container docker-nginx-proxy-1  Healthy          0.1s 
 ✔ Container docker-web-blue-2     Healthy          0.1s 
 ✔ Container docker-web-blue-4     Healthy          0.1s 
 ✔ Container docker-web-blue-3     Healthy          0.0s 
 ✔ Container docker-web-blue-5     Healthy          0.1s 
 ✔ Container docker-web-blue-1     Healthy          0.1s
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
docker-nginx-proxy-1   nginxproxy/nginx-proxy:1.5.1-alpine   "/app/docker-entrypo…"   nginx-proxy   12 seconds ago   Up 5 seconds (healthy)    0.0.0.0:80->80/tcp
docker-web-blue-1      docker-web-blue                       "./main"                 web-blue      12 seconds ago   Up 11 seconds (healthy)   8080/tcp
docker-web-blue-2      docker-web-blue                       "./main"                 web-blue      12 seconds ago   Up 11 seconds (healthy)   8080/tcp
docker-web-blue-3      docker-web-blue                       "./main"                 web-blue      12 seconds ago   Up 11 seconds (healthy)   8080/tcp
Журналы запуска web-blue
web-blue-2  | Сервер запущен на порту 8080...
web-blue-1  | Сервер запущен на порту 8080...
web-blue-3  | Сервер запущен на порту 8080...
```
