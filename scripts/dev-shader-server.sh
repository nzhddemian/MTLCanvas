#!/bin/zsh
set -euo pipefail
unsetopt BG_NICE 2>/dev/null || true

ACTION="${1:-start}"
PORT="${MTLCANVAS_SHADER_PORT:-8080}"
ROOT="${MTLCANVAS_SHADER_ROOT:-${SRCROOT:-$(pwd)}}"
HOST="${MTLCANVAS_SHADER_HOST:-0.0.0.0}"
IDLE_TIMEOUT="${MTLCANVAS_SHADER_IDLE_TIMEOUT:-300}"
SCRIPT_DIR="${0:A:h}"
PID_FILE="/tmp/mtlcanvas-shader-server-${PORT}.pid"
LOG_FILE="/tmp/mtlcanvas-shader-server-${PORT}.log"

is_running() {
    [[ -f "$PID_FILE" ]] \
        && kill -0 "$(cat "$PID_FILE")" 2>/dev/null \
        && /usr/bin/curl --silent --head --max-time 1 "http://127.0.0.1:${PORT}/" >/dev/null 2>&1
}

start_server() {
    if is_running; then
        echo "MTLCanvas shader server already running on port ${PORT}: pid $(cat "$PID_FILE")"
        return 0
    fi

    if ! [[ -d "$ROOT" ]]; then
        echo "MTLCanvas shader server root does not exist: ${ROOT}" >&2
        exit 1
    fi

    cd "$ROOT"
    nohup /usr/bin/python3 "${SCRIPT_DIR}/dev_shader_server.py" \
        --host "$HOST" \
        --port "$PORT" \
        --root "$ROOT" \
        --idle-timeout "$IDLE_TIMEOUT" \
        > "$LOG_FILE" 2>&1 < /dev/null &
    local pid=$!
    disown "$pid" 2>/dev/null || true
    echo "$pid" > "$PID_FILE"

    local server_url="http://127.0.0.1:${PORT}/"
    local ready="NO"
    for _ in {1..20}; do
        if /usr/bin/curl --silent --head --max-time 1 "$server_url" >/dev/null 2>&1; then
            ready="YES"
            break
        fi

        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi

        sleep 0.1
    done

    if [[ "$ready" != "YES" ]]; then
        kill "$pid" 2>/dev/null || true
        rm -f "$PID_FILE"
        echo "Failed to start MTLCanvas shader server. Log: ${LOG_FILE}" >&2
        exit 1
    fi

    echo "Started MTLCanvas shader server: http://${HOST}:${PORT}/"
    echo "Root: ${ROOT}"
    echo "PID: ${pid}"
    echo "Log: ${LOG_FILE}"
}

stop_server() {
    local shutdown_url="http://127.0.0.1:${PORT}/_mtlcanvas/shutdown"

    if ! is_running; then
        local port_pid
        port_pid="$(/usr/sbin/lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -n 1 || true)"
        if [[ -n "$port_pid" ]]; then
            /usr/bin/curl --silent --max-time 1 "$shutdown_url" >/dev/null 2>&1 || true
            sleep 0.2
            kill "$port_pid" 2>/dev/null || true
            echo "Stopped MTLCanvas shader server on port ${PORT}: pid ${port_pid}"
        fi

        rm -f "$PID_FILE"
        if [[ -z "$port_pid" ]]; then
            echo "MTLCanvas shader server is not running"
        fi
        return 0
    fi

    local pid
    pid="$(cat "$PID_FILE")"
    /usr/bin/curl --silent --max-time 1 "$shutdown_url" >/dev/null 2>&1 || true
    sleep 0.2
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo "Stopped MTLCanvas shader server: pid ${pid}"
}

case "$ACTION" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server || true
        start_server
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}" >&2
        exit 64
        ;;
esac
