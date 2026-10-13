#!/usr/bin/env bash
# ==============================================================================
# Showcase App · List Storage Bucket Objects
#
# Lists files and folders in Supabase Storage (default: 'videos' bucket)
# using configurable environment variables and REST API.
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
BUCKET_NAME="${BUCKET_NAME:-videos}"
PREFIX="${PREFIX:-}"
LIMIT="${LIMIT:-100}"
TIMEOUT="${TIMEOUT:-15}"

# ------------------------------------------------------------------------------
# 3. CLI Argument Parsing
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Использование: $(basename "$0") [ПАРАМЕТРЫ]

Параметры:
  -b, --bucket BUCKET  Имя бакета хранилища (по умолчанию: videos)
  -p, --prefix PREFIX  Префикс / подпапка для поиска (например: family/)
  -l, --limit N        Максимальное количество объектов (по умолчанию: 100)
  -u, --url URL        Supabase URL (по умолчанию: \$SUPABASE_URL)
  -k, --key KEY        Supabase Anon / Publishable Key (по умолчанию: \$SUPABASE_ANON_KEY)
  --timeout SEC        Таймаут запроса в секундах (по умолчанию: 15)
  -h, --help           Показать эту справку

Переменные окружения:
  SUPABASE_URL / NEXT_PUBLIC_SUPABASE_URL
  SUPABASE_ANON_KEY / NEXT_PUBLIC_SUPABASE_ANON_KEY
  BUCKET_NAME
  PREFIX
  LIMIT
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--bucket)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -u|--url)
            SUPABASE_URL="$2"
            shift 2
            ;;
        -k|--key)
            SUPABASE_ANON_KEY="$2"
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
            # Позиционный аргумент: если первый, то BUCKET_NAME
            if [ -z "${BUCKET_NAME_SET:-}" ]; then
                BUCKET_NAME="$1"
                BUCKET_NAME_SET=1
                shift
            else
                echo "❌ Неизвестный параметр: $1" >&2
                show_help
                exit 1
            fi
            ;;
    esac
done

if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
    echo "❌ Ошибка: SUPABASE_URL и SUPABASE_ANON_KEY должны быть заданы." >&2
    echo "   Укажите их через .env.local, переменные окружения (GitHub Secrets / Vault) или параметры CLI (-u, -k)." >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# 4. Storage List Request
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  SHOWCASE · Supabase Storage Object List"
echo "=========================================================="
echo "  Target URL : ${SUPABASE_URL}"
echo "  Bucket     : ${BUCKET_NAME}"
echo "  Prefix     : ${PREFIX:-<root>}"
echo "  Limit      : ${LIMIT}"
echo "----------------------------------------------------------"

ENDPOINT="${SUPABASE_URL}/storage/v1/object/list/${BUCKET_NAME}"
PAYLOAD=$(cat <<EOF
{
  "prefix": "${PREFIX}",
  "limit": ${LIMIT},
  "offset": 0,
  "sortBy": {
    "column": "name",
    "order": "asc"
  }
}
EOF
)

echo "📡 Запрос объектов из бакета '${BUCKET_NAME}' ..."
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time "${TIMEOUT}" \
    -X POST \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}" \
    "${ENDPOINT}" 2>&1) || {
        echo "❌ Ошибка сетевого соединения при обращении к Storage API" >&2
        exit 1
    }

HTTP_CODE=$(echo "${HTTP_RESPONSE}" | tail -n1)
BODY=$(echo "${HTTP_RESPONSE}" | sed '$d')

echo "📊 HTTP Status Code: ${HTTP_CODE}"
echo "----------------------------------------------------------"

if [ "${HTTP_CODE}" -ge 200 ] && [ "${HTTP_CODE}" -lt 300 ]; then
    if command -v jq &>/dev/null; then
        TOTAL=$(echo "${BODY}" | jq 'length')
        echo "✅ Найдено объектов: ${TOTAL}"
        echo ""
        printf "%-35s %-12s %-25s\n" "ИМЯ ФАЙЛА" "РАЗМЕР" "ОБНОВЛЕН"
        printf "%-35s %-12s %-25s\n" "-----------------------------------" "------------" "-------------------------"
        echo "${BODY}" | jq -r '.[] | [
            .name, 
            (if .metadata.size then (.metadata.size | tostring) else "-" end), 
            (if .updated_at then .updated_at else "-" end)
        ] | @tsv' | while IFS=$'\t' read -r name size updated; do
            # Форматирование размера в удобочитаемый вид
            if [[ "$size" =~ ^[0-9]+$ ]]; then
                if [ "$size" -ge 1048576 ]; then
                    human_size="$(awk "BEGIN {printf \"%.2f MB\", $size/1048576}")"
                elif [ "$size" -ge 1024 ]; then
                    human_size="$(awk "BEGIN {printf \"%.2f KB\", $size/1024}")"
                else
                    human_size="${size} B"
                fi
            else
                human_size="[folder]"
            fi
            printf "%-35s %-12s %-25s\n" "${name}" "${human_size}" "${updated:0:19}"
        done
    else
        echo "${BODY}"
    fi
    exit 0
else
    echo "⚠️ Ошибка при получении списка объектов (HTTP ${HTTP_CODE}):"
    if command -v jq &>/dev/null; then
        echo "${BODY}" | jq . 2>/dev/null || echo "${BODY}"
    else
        echo "${BODY}"
    fi
    exit 1
fi
