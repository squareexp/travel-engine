#!/bin/zsh

PROJECT_DIR="/Users/ajmaljs/Developer/Blueaqua/twende"
COMPOSE_FILE="$PROJECT_DIR/server/docker-compose.yml"
WATCH_PID_FILE="$HOME/.twende_watch.pid"

start_server() {
  echo "🐳 Building and starting Docker container..."
  docker compose -f "$COMPOSE_FILE" up -d --build

  echo "👀 Starting Docker Compose Watch for hot-reloading..."
  # Run docker compose watch in the background
  docker compose -f "$COMPOSE_FILE" watch > /dev/null 2>&1 &
  echo $! > "$WATCH_PID_FILE"
  echo "✅ Server container started and file watching active."
}

stop_server() {
  echo "🛑 Stopping Docker Compose Watch..."
  if [ -f "$WATCH_PID_FILE" ]; then
    local pid=$(cat "$WATCH_PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
    fi
    rm -f "$WATCH_PID_FILE"
  fi

  echo "🐳 Stopping Docker container..."
  docker compose -f "$COMPOSE_FILE" down
  echo "✅ Server container stopped."
}

case "$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  restart)
    stop_server
    sleep 1
    start_server
    ;;
  logs)
    docker compose -f "$COMPOSE_FILE" logs -f api
    ;;
  *)
    echo "Usage: twende {start|stop|restart|logs}"
    exit 1
    ;;
esac
