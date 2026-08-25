FROM python:3.13-slim

WORKDIR /app

# Install system deps for psycopg2
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

# Install Python deps
COPY dr/app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY dr/app/ ./app/
COPY lambdas/common/ ./lambdas/common/
COPY lambdas/users/handler.py ./lambdas/users/handler.py
COPY lambdas/projects/handler.py ./lambdas/projects/handler.py
COPY lambdas/worker/handler.py ./lambdas/worker/handler.py

# Copy common modules to flat structure (Lambda handlers import them flat)
RUN cp lambdas/common/*.py lambdas/users/ && \
    cp lambdas/common/*.py lambdas/projects/ && \
    cp lambdas/common/*.py lambdas/worker/

# Add lambdas/ to PYTHONPATH so handler imports resolve
ENV PYTHONPATH="/app/lambdas:/app/lambdas/common:/app/app"

# Create data directory and set ownership
RUN mkdir -p /data/artifacts && chown -R appuser:appuser /app /data

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
