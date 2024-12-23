# Базовый образ
FROM python:3.13.1-alpine

# Устанавливаем переменные окружения
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    WORKDIR_PATH="/app" \
    VENV_PATH="/opt/venv"

# Определяем аргументы для пользователя и группы
ARG USERNAME=appuser
ARG GROUPNAME=appgroup

# Создаем пользователя и рабочую директорию
RUN addgroup --system ${GROUPNAME} \
    && adduser --system --ingroup ${GROUPNAME} ${USERNAME} \
    && mkdir -p ${WORKDIR_PATH} ${VENV_PATH} \
    && chown -R ${USERNAME}:${GROUPNAME} ${WORKDIR_PATH} ${VENV_PATH}

# Устанавливаем рабочую директорию
WORKDIR ${WORKDIR_PATH}

# Копируем uv чрезвычайно быстрый менеджер пакетов и проектов Python
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /bin/

# Создаем виртуальное окружение и настраиваем PATH
RUN uv venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:$PATH"

# Копируем requirements, устанавливаем зависимости в venv и устанавливаем права
COPY --chown=${USERNAME}:${GROUPNAME} ./requirements.txt ./requirements.txt
RUN uv pip install --no-cache --require-hashes --requirements ./requirements.txt \
    && chown -R ${USERNAME}:${GROUPNAME} ${VENV_PATH}

# Копируем остальные файлы приложения
COPY --chown=${USERNAME}:${GROUPNAME} ./ ./

# Запускаем контейнер от имени нового пользователя
USER ${USERNAME}:${GROUPNAME}

# Настраиваем команду запуска
ENTRYPOINT ["uvicorn", "main:app"]
CMD [ "--host", "0.0.0.0", "--port", "8000" ]
