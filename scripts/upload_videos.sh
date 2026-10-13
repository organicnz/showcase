#!/usr/bin/env bash
# ==============================================================================
# Showcase App · Upload Video Assets to Supabase Storage
#
# Uploads video files from assets/videos to Supabase Storage ('videos' bucket)
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
VIDEOS_DIR="${VIDEOS_DIR:-${REPO_ROOT}/assets/videos}"
PREFIX="${PREFIX:-}"
UPSERT="${UPSERT:-true}"
TIMEOUT="${TIMEOUT:-300}"
SINGLE_FILE=""

# Стандартный список видео по умолчанию (5 базовых сценариев)
DEFAULT_FILES=(
    "v_family_fix.mp4"
    "v_wellness_fix.mp4"
    "v_guests_fix.mp4"
    "v_investor_fix.mp4"
    "v_architecture_fix.mp4"
)

# ------------------------------------------------------------------------------
# 3. CLI Argument Parsing
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Использование: $(basename "$0") [ПАРАМЕТРЫ] [КОНКРЕТНЫЙ_ФАЙЛ]

Параметры:
  -f, --file FILE      Загрузить один файл (по имени в VIDEOS_DIR или абсолютный путь)
  -d, --dir DIR        Директория с видеофайлами (по умолчанию: assets/videos)
  -b, --bucket BUCKET  Имя бакета (по умолчанию: videos)
  -p, --prefix PREFIX  Префикс / подпапка в бакете (например: family/)
  -u, --url URL        Supabase URL (по умолчанию: \$SUPABASE_URL)
  -k, --key KEY        Supabase Anon / Publishable Key (по умолчанию: \$SUPABASE_ANON_KEY)
  --no-upsert          Запретить перезапись файлов
  --timeout SEC        Таймаут одного файла в секундах (по умолчанию: 300)
  -h, --help           Показать эту справку

Переменные окружения:
  SUPABASE_URL / NEXT_PUBLIC_SUPABASE_URL
  SUPABASE_ANON_KEY / NEXT_PUBLIC_SUPABASE_ANON_KEY
  BUCKET_NAME
  VIDEOS_DIR
  PREFIX
  UPSERT
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            SINGLE_FILE="$2"
            shift 2
            ;;
        -d|--dir)
            VIDEOS_DIR="$2"
            shift 2
            ;;
        -b|--bucket)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -p|--prefix)
            PREFIX="$2"
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
            if [ -z "${SINGLE_FILE}" ]; then
                SINGLE_FILE="$1"
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
# 4. Upload Function
# ------------------------------------------------------------------------------
upload_one_video() {
    local file_path="$1"
    local filename
    filename="$(basename "${file_path}")"

    if [ ! -f "${file_path}" ]; then
        echo "⚠️ Файл не найден: ${file_path} (пропуск)"
        return 1
    fi

    local file_size
    file_size=$(wc -c < "${file_path}" | tr -d ' ')
    local human_size
    human_size="$(awk "BEGIN {printf \"%.2f MB\", ${file_size}/1048576}")"

    local remote_path="${filename}"
    if [ -n "${PREFIX}" ]; then
        # Удаляем ведущий/хвостовой слэш из префикса
        local clean_prefix="${PREFIX#/}"
        clean_prefix="${clean_prefix%/}"
        remote_path="${clean_prefix}/${filename}"
    fi

    local endpoint="${SUPABASE_URL}/storage/v1/object/${BUCKET_NAME}/${remote_path}"

    echo "▶️ Загрузка: ${filename} (${human_size}) -> [${BUCKET_NAME}/${remote_path}] ..."

    local response
    response=$(curl -s -w "\n%{http_code}" --max-time "${TIMEOUT}" \
        -X POST \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: video/mp4" \
        -H "x-upsert: ${UPSERT}" \
        --data-binary "@${file_path}" \
        "${endpoint}" 2>&1) || {
            echo "❌ Сетевая ошибка при загрузке ${filename}"
            return 1
        }

    local http_code
    http_code=$(echo "${response}" | tail -n1)
    local body
    body=$(echo "${response}" | sed '$d')

    if [ "${http_code}" -ge 200 ] && [ "${http_code}" -lt 300 ]; then
        echo "  ✅ Успешно загружен (HTTP ${http_code})"
        return 0
    else
        echo "  ❌ Ошибка загрузки (HTTP ${http_code}): ${body}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 5. Execution Loop
# ------------------------------------------------------------------------------
echo "=========================================================="
echo "  SHOWCASE · Supabase Videos Batch Upload"
echo "=========================================================="
echo "  Target URL : ${SUPABASE_URL}"
echo "  Bucket     : ${BUCKET_NAME}"
echo "  Videos Dir : ${VIDEOS_DIR}"
echo "  Prefix     : ${PREFIX:-<root>}"
echo "  Upsert     : ${UPSERT}"
echo "----------------------------------------------------------"

FILES_TO_UPLOAD=()

if [ -n "${SINGLE_FILE}" ]; then
    if [ -f "${SINGLE_FILE}" ]; then
        FILES_TO_UPLOAD+=("${SINGLE_FILE}")
    elif [ -f "${VIDEOS_DIR}/${SINGLE_FILE}" ]; then
        FILES_TO_UPLOAD+=("${VIDEOS_DIR}/${SINGLE_FILE}")
    else
        echo "❌ Указанный файл не найден: ${SINGLE_FILE}" >&2
        exit 1
    fi
else
    # Проверяем файлы по умолчанию
    for default_name in "${DEFAULT_FILES[@]}"; do
        if [ -f "${VIDEOS_DIR}/${default_name}" ]; then
            FILES_TO_UPLOAD+=("${VIDEOS_DIR}/${default_name}")
        fi
    done

    # Если файлов по умолчанию нет, ищем все .mp4 в директории
    if [ ${#FILES_TO_UPLOAD[@]} -eq 0 ] && [ -d "${VIDEOS_DIR}" ]; then
        while IFS= read -r -d '' f; do
            FILES_TO_UPLOAD+=("$f")
        done < <(find "${VIDEOS_DIR}" -maxdepth 1 -name "*.mp4" -print0)
    fi
fi

if [ ${#FILES_TO_UPLOAD[@]} -eq 0 ]; then
    echo "⚠️ Видеофайлы для загрузки не найдены в ${VIDEOS_DIR}"
    exit 0
fi

echo "📋 Всего файлов к загрузке: ${#FILES_TO_UPLOAD[@]}"
echo "----------------------------------------------------------"

SUCCESS_COUNT=0
FAIL_COUNT=0

for file_path in "${FILES_TO_UPLOAD[@]}"; do
    if upload_one_video "${file_path}"; then
        ((SUCCESS_COUNT++)) || true
    else
        ((FAIL_COUNT++)) || true
    fi
done

echo "----------------------------------------------------------"
echo "🏁 Итог загрузки: успешно: ${SUCCESS_COUNT}, ошибок: ${FAIL_COUNT}"

if [ "${FAIL_COUNT}" -gt 0 ]; then
    exit 1
fi
exit 0
