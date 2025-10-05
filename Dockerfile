FROM python:3.13.5-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE="1"
ENV PYTHONUNBUFFERED="1"
ENV PORT="8888"

# Set work directory
WORKDIR /mediaflow_proxy

# Create a non-root user
RUN useradd -m mediaflow_proxy
RUN chown -R mediaflow_proxy:mediaflow_proxy /mediaflow_proxy

# Set up the PATH to include the user's local bin
ENV PATH="/home/mediaflow_proxy/.local/bin:$PATH"

# Switch to non-root user
USER mediaflow_proxy

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Copy only requirements to cache them in docker layer
COPY --chown=mediaflow_proxy:mediaflow_proxy pyproject.toml poetry.lock* /mediaflow_proxy/

# --- CORREZIONE 1: Usa il path completo per eseguire Poetry ---
RUN /home/mediaflow_proxy/.local/bin/poetry config virtualenvs.in-project true \
    && /home/mediaflow_proxy/.local/bin/poetry install --no-interaction --no-ansi --no-root --only main

# Copy project files
COPY --chown=mediaflow_proxy:mediaflow_proxy . /mediaflow_proxy/

# Expose the port the app runs on
EXPOSE 8888

# --- CORREZIONE 2: Usa il path completo anche nel comando finale ---
CMD ["sh", "-c", "exec /home/mediaflow_proxy/.local/bin/poetry run gunicorn mediaflow_proxy.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8888 --timeout 120 --max-requests 500 --max-requests-jitter 200 --access-logfile - --error-logfile - --log-level info --forwarded-allow-ips \"${FORWARDED_ALLOW_IPS:-127.0.0.1}\""]
