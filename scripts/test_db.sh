#!/usr/bin/env bash
# ==============================================================================
# Showcase App · Supabase Database & REST API Health Check
#
# Tests database connectivity, authentication, and REST queries against
# Supabase PostgREST endpoint using configurable environment variables.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ------------------------------------------------------------------------------
# 1. Load Environment Variables (from .env.local or .env if present)
# ------------------------------------------------------------------------------
if [ -f "${REPO_ROOT}/.env.local" ]; then
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/.env.local"
elif [ -f "${REPO_ROOT}/.env" ]; then
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/.env"
fi

# ------------------------------------------------------------------------------
# 2. Configurable Variables with Defaults
# ------------------------------------------------------------------------------
SUPABASE_URL="${SUPABASE_URL:-${NEXT_PUBLIC_SUPABASE_URL:-}}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}}"
TABLE_NAME="${TABLE_NAME:-scenarios}"
TIMEOUT="${TIMEOUT:-10}"
LIMIT="${LIMIT:-5}"

# ------------------------------------------------------------------------------
# 3. CLI Argument Parsing
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Использование: $(basename "$0") [ПАРАМЕТРЫ]

Параметры:
  -u, --url URL        Supabase URL (по умолчанию: \$SUPABASE_URL)
  -k, --key KEY        Supabase Anon / Publishable Key (по умолчанию: \$SUPABASE_ANON_KEY)
  -t, --table TABLE    Имя таблицы для выборки (по умолчанию: scenarios)
  -l, --limit N        Максимальное количество строк (по умолчанию: 5)
  --timeout SEC        Таймаут запроса в секундах (по умолчанию: 10)
  -h, --help           Показать эту справку

Переменные окружения:
  SUPABASE_URL / NEXT_PUBLIC_SUPABASE_URL
  SUPABASE_ANON_KEY / NEXT_PUBLIC_SUPABASE_ANON_KEY
  TABLE_NAME
  TIMEOUT
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--url)
            SUPABASE_URL="$2"
            shift 2
            ;;
        -k|--key)
            SUPABASE_ANON_KEY="$2"
            shift 2
            ;;
        -t|--table)
            TABLE_NAME="$2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Неизвестный параметр: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
    echo "❌ Ошибка: SUPABASE_URL и SUPABASE_ANON_KEY должны быть заданы." >&2
    echo "   Укажите их через .env.local, переменные окружения (GitHub Secrets / Vault) или параметры CLI (-u, -k)." >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# 4. Diagnostics & Execution
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  SHOWCASE · Supabase Database Health Check"
echo "=========================================================="
echo "  Target URL : ${SUPABASE_URL}"
echo "  Table      : ${TABLE_NAME}"
echo "  Limit      : ${LIMIT}"
echo "  Timeout    : ${TIMEOUT}s"
echo "  Key        : ${SUPABASE_ANON_KEY:0:15}... (masked)"
echo "----------------------------------------------------------"

ENDPOINT="${SUPABASE_URL}/rest/v1/${TABLE_NAME}?select=*&limit=${LIMIT}"

echo "📡 Отправка запроса к REST API: ${ENDPOINT} ..."
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time "${TIMEOUT}" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    "${ENDPOINT}" 2>&1) || {
        echo "❌ Ошибка сетевого соединения при вызове curl" >&2
        exit 1
    }

HTTP_CODE=$(echo "${HTTP_RESPONSE}" | tail -n1)
BODY=$(echo "${HTTP_RESPONSE}" | sed '$d')

echo "📊 HTTP Status Code: ${HTTP_CODE}"
echo "----------------------------------------------------------"

if [ "${HTTP_CODE}" -ge 200 ] && [ "${HTTP_CODE}" -lt 300 ]; then
    echo "✅ Подключение успешно! Получены данные:"
    if command -v jq &>/dev/null; then
        echo "${BODY}" | jq .
        ROW_COUNT=$(echo "${BODY}" | jq 'length')
        echo "----------------------------------------------------------"
        echo "✅ Успешно получено записей: ${ROW_COUNT}"
    else
        echo "${BODY}"
    fi
    exit 0
else
    echo "⚠️ Ошибка при выполнении запроса (HTTP ${HTTP_CODE}):"
    if command -v jq &>/dev/null; then
        echo "${BODY}" | jq . 2>/dev/null || echo "${BODY}"
    else
        echo "${BODY}"
    fi
    echo "----------------------------------------------------------"
    echo "💡 Рекомендации по устранению:"
    echo "  1. Проверьте правильность SUPABASE_URL и SUPABASE_ANON_KEY"
    echo "  2. Убедитесь, что таблица '${TABLE_NAME}' существует и RLS разрешает чтение"
    echo "  3. Если проект был неактивен, Supabase может находиться в режиме прогрева"
    exit 1
fi
