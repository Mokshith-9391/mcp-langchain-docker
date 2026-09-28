#!/usr/bin/env bash
# =====================================================================
#  mcp.sh — day-to-day commands for the Dockerised MCP stack
#
#    ./mcp.sh up              start the 3 MCP servers (build if needed)
#    ./mcp.sh down            stop and remove containers
#    ./mcp.sh restart         restart servers (use after editing .env)
#    ./mcp.sh rebuild         rebuild image + restart (use after editing code)
#    ./mcp.sh status          container status + health
#    ./mcp.sh logs [name]     follow logs (weather | jira | ec2), all if empty
#    ./mcp.sh test            smoke-test all servers (no LLM needed)
#    ./mcp.sh agent           interactive chat with the agent
#    ./mcp.sh ask "question"  ask one question and exit
#    ./mcp.sh shell [name]    open a shell inside a container (default: ec2)
#    ./mcp.sh clean           remove containers, network AND the image
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"

if docker info >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="sudo docker"; fi
COMPOSE="$DOCKER compose"
SERVERS=(weather jira ec2)

need_env() {
  [ -f .env ] || { echo "❌ .env not found. Run: cp .env.example .env && nano .env"; exit 1; }
}

cmd="${1:-help}"; shift || true

case "$cmd" in
  up)
    need_env
    $COMPOSE up -d --build
    $COMPOSE ps
    ;;
  down)
    $COMPOSE down
    ;;
  restart)
    need_env
    # 'up -d' re-creates containers so new .env values are picked up
    $COMPOSE up -d --force-recreate "${SERVERS[@]}"
    $COMPOSE ps
    ;;
  rebuild)
    need_env
    $COMPOSE build
    $COMPOSE up -d --force-recreate "${SERVERS[@]}"
    $COMPOSE ps
    ;;
  status|ps)
    $COMPOSE ps
    ;;
  logs)
    if [ $# -gt 0 ]; then $COMPOSE logs -f --tail=100 "$@"; else $COMPOSE logs -f --tail=50; fi
    ;;
  test)
    need_env
    $COMPOSE run --rm -T agent python scripts/test_servers.py
    ;;
  agent|chat)
    need_env
    $COMPOSE run --rm agent
    ;;
  ask)
    need_env
    [ $# -gt 0 ] || { echo 'Usage: ./mcp.sh ask "your question"'; exit 1; }
    $COMPOSE run --rm -T agent python agent/agent.py "$*"
    ;;
  shell)
    $COMPOSE exec "${1:-ec2}" bash
    ;;
  clean)
    $COMPOSE --profile cli down --remove-orphans
    $DOCKER image rm mcp-langchain-app:latest 2>/dev/null || true
    echo "Cleaned containers, network and image."
    ;;
  help|*)
    echo "Usage: ./mcp.sh <command>"; sed -n '5,15p' "$0" | sed 's/^#//'
    ;;
esac
