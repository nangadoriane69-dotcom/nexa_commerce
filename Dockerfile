 Dockerfile pour pipeline NexaCommerce
FROM python:3.11-slim
WORKDIR /app
# Copier et installer les dépendances
COPY pyproject.toml poetry.lock .
RUN pip install poetry && poetry install --no-dev
# Copier le code source
COPY src/ ./src/
COPY data/ ./data/
CMD ['poetry', 'run', 'python', 'src/pipeline.py']