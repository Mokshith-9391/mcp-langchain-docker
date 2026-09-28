# =============================================================
#  One image for everything: the 3 MCP servers + the agent.
#  docker-compose.yml decides which script each container runs.
# =============================================================
FROM python:3.12-slim

# No .pyc files, logs appear immediately in `docker logs`
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# 1) Install dependencies first (this layer is cached until requirements.txt changes)
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# 2) Copy the application code
COPY servers/ servers/
COPY agent/   agent/
COPY scripts/ scripts/

# 3) Run as a non-root user (security best practice)
RUN useradd --create-home --uid 1000 appuser && chown -R appuser /app
USER appuser

# Default command = the agent. Servers override this in docker-compose.yml
CMD ["python", "agent/agent.py"]
