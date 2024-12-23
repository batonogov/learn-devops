# uv

Чрезвычайно быстрый менеджер пакетов и проектов Python, написанный на Rust.

Один инструмент для замены **pip**, **pip-tools**, **pipx**, **poetry**, **pyenv**, **twine**, **virtualenv**, и многое другое.

[Официальный GitHub репозиторий](https://github.com/astral-sh/uv)

## Как работаь с **uv**

[Установка **UV**](https://github.com/astral-sh/uv#installation)

- Создание окружения

```sh
make venv
```

- Обновление библиотек

Обноваляем версии зависимостей в **pyproject.toml** и запускаем

```sh
make reqs
```

Сборка образа с **uv** без кэша

```sh
make build
```

Сборка образа с **pip** без кэша

```sh
make build-pip
```
