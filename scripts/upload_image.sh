#!/usr/bin/env bash
# ==============================================================================
# Showcase App · Upload Image to Supabase Storage
#
# Uploads image asset (default: assets/photos/family_white.jpg) to Supabase Storage
# (default: 'photos' bucket) using configurable environment variables and REST API.
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
BUCKET_NAME="${BUCKET_NAME:-photos}"
FILE_PATH="${FILE_PATH:-${REPO_ROOT}/assets/photos/family_white.jpg}"
DEST_NAME="${DEST_NAME:-}"
UPSERT="${UPSERT:-true}"
TIMEOUT="${TIMEOUT:-60}"

# ------------------------------------------------------------------------------
# 3. CLI Argument Parsing
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Использование: $(basename "$0") [ПАРАМЕТРЫ] [ПУТЬ_К_ФАЙЛУ]

Параметры:
  -f, --file PATH      Путь к локальному файлу (по умолчанию: assets/photos/family_white.jpg)
  -b, --bucket BUCKET  Имя бакета (по умолчанию: photos)
  -d, --dest NAME      Имя объекта в хранилище (по умолчанию: имя исходного файла)
  -u, --url URL        Supabase URL (по умолчанию: \$SUPABASE_URL)
  -k, --key KEY        Supabase Anon / Publishable Key (по умолчанию: \$SUPABASE_ANON_KEY)
  --no-upsert          Запретить перезапись существующего файла
  --timeout SEC        Таймаут загрузки в секундах (по умолчанию: 60)
  -h, --help           Показать эту справку

Переменные окружения:
  SUPABASE_URL / NEXT_PUBLIC_SUPABASE_URL
  SUPABASE_ANON_KEY / NEXT_PUBLIC_SUPABASE_ANON_KEY
  BUCKET_NAME
  FILE_PATH
  DEST_NAME
  UPSERT
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            FILE_PATH="$2"
            shift 2
            ;;
        -b|--bucket)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -d|--dest)
            DEST_NAME="$2"
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
        --no-upsert)
            UPSERT="false"
            shift
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
            if [ -z "${POSITIONAL_FILE:-}" ]; then
                FILE_PATH="$1"
                POSITIONAL_FILE=1
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
# 4. Validation & MIME Type Detection
# ------------------------------------------------------------------------------
if [ ! -f "${FILE_PATH}" ]; then
    echo "❌ Ошибка: файл не найден: ${FILE_PATH}" >&2
    exit 1
fi

if [ -z "${DEST_NAME}" ]; then
    DEST_NAME="$(basename "${FILE_PATH}")"
fi

FILE_SIZE=$(wc -c < "${FILE_PATH}" | tr -d ' ')
EXTENSION="${FILE_PATH##*.}"

case "${EXTENSION,,}" in
    jpg|jpeg)
        CONTENT_TYPE="image/jpeg"
        ;;
    png)
        CONTENT_TYPE="image/png"
        ;;
    webp)
        CONTENT_TYPE="image/webp"
        ;;
    svg)
        CONTENT_TYPE="image/svg+xml"
        ;;
    gif)
        CONTENT_TYPE="image/gif"
        ;;
    *)
        CONTENT_TYPE="application/octet-stream"
        ;;
esac

echo "=========================================================="
echo "  SHOWCASE · Supabase Image Upload"
echo "=========================================================="
echo "  Target URL   : ${SUPABASE_URL}"
echo "  Bucket       : ${BUCKET_NAME}"
echo "  Local File   : ${FILE_PATH}"
echo "  Remote Path  : ${DEST_NAME}"
echo "  Size         : $((FILE_SIZE / 1024)) KB (${FILE_SIZE} bytes)"
echo "  Content-Type : ${CONTENT_TYPE}"
echo "  Upsert       : ${UPSERT}"
echo "----------------------------------------------------------"

ENDPOINT="${SUPABASE_URL}/storage/v1/object/${BUCKET_NAME}/${DEST_NAME}"

echo "🚀 Загрузка изображения в хранилище ..."
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time "${TIMEOUT}" \
    -X POST \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: ${CONTENT_TYPE}" \
    -H "x-upsert: ${UPSERT}" \
    --data-binary "@${FILE_PATH}" \
    "${ENDPOINT}" 2>&1) || {
        echo "❌ Ошибка сетевого соединения при вызове Storage API" >&2
        exit 1
    }

HTTP_CODE=$(echo "${HTTP_RESPONSE}" | tail -n1)
BODY=$(echo "${HTTP_RESPONSE}" | sed '$d')

echo "📊 HTTP Status Code: ${HTTP_CODE}"
echo "----------------------------------------------------------"

if [ "${HTTP_CODE}" -ge 200 ] && [ "${HTTP_CODE}" -lt 300 ]; then
    PUBLIC_URL="${SUPABASE_URL}/storage/v1/object/public/${BUCKET_NAME}/${DEST_NAME}"
    echo "✅ Изображение успешно загружено!"
    echo "🔗 Публичный URL: ${PUBLIC_URL}"
    if command -v jq &>/dev/null && [ -n "${BODY}" ]; then
        echo "${BODY}" | jq . 2>/dev/null || echo "${BODY}"
    fi
    exit 0
else
    echo "⚠️ Ошибка загрузки (HTTP ${HTTP_CODE}):"
    if command -v jq &>/dev/null && [ -n "${BODY}" ]; then
        echo "${BODY}" | jq . 2>/dev/null || echo "${BODY}"
    else
        echo "${BODY}"
    fi
    exit 1
fi
