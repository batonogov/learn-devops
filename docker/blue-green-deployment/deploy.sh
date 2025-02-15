#!/bin/bash

# Эта строка настраивает оболочку так, чтобы она выходила из скрипта при возникновении ошибки в любой команде.
# Это помогает обнаружить и обрабатывать ошибки в скрипте.
set -e

# Проверяем состояние контейнера с именем "web-blue", чтобы определить, является ли он "здоровым" (healthy).
# Если это так, переменным NEW и OLD присваиваются значения "green" и "blue" соответственно, иначе наоборот.
if [ "$(docker compose ps web-blue | grep healthy)" ]
then
    export NEW="green"
    export OLD="blue"
else
    export NEW="blue"
    export OLD="green"
fi

# Выводим сообщение о том, какой профиль поднимается в данный момент (значение переменной NEW).
echo Поднимаю проект с профилем ${NEW}
# Эта команда использует docker-compose для запуска проекта с указанным профилем (значение переменной NEW),
# разворачивая контейнеры в фоновом режиме, пересоздавая их, удаляя сиротские контейнеры,
# масштабируя сервис "web" на три экземпляра и дожидаясь их запуска.
docker compose \
    --profile ${NEW} \
    up \
    --detach \
    --build \
    --remove-orphans \
    --scale web-${NEW}=3 \
    --wait \
    --quiet-pull

# Эта строка выводит сообщение о том, какие сервисы останавливаются в данный момент (значение переменной OLD).
echo Останавливаю сервисы ${OLD}
# Эта команда использует docker-compose для остановки сервиса "web" с именем, соответствующим значению переменной OLD.
docker compose stop \
    web-${OLD}

# Эта строка выводит сообщение о том, какие сервисы удаляются в данный момент (значение переменной OLD).
echo Удаляю сервисы ${OLD}
# Эта команда использует docker-compose для принудительного удаления сервиса "web" с именем, соответствующим значению переменной OLD.
docker compose rm -f \
    web-${OLD}

# Эта строка выводит сообщение о выводе списка всех контейнеров.
echo Список контейнеров
docker compose ps -a

# Эта команда выводит сообщение о том, что будут выведены журналы запуска для сервиса "web" с именем,
# соответствующим значению переменной NEW, и затем выводит эти журналы.
echo Журналы запуска web-${NEW}
docker compose logs web-${NEW}
