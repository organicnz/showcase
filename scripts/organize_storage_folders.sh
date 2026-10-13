#!/usr/bin/env bash
# ==============================================================================
# Showcase App · Organize Storage Bucket Video Folders
#
# Migrates flat/root video files in Supabase Storage into structured scenario
# folders (family/, wellness/, guests/, investor/, architecture/) using REST API.
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
TEMP_DIR="${TEMP_DIR:-${REPO_ROOT}/.temp_storage}"
DRY_RUN=0

# Trap for cleanup
cleanup() {
    if [ -d "${TEMP_DIR}" ]; then
        rm -rf "${TEMP_DIR}"
    fi
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# 3. CLI Argument Parsing
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Использование: $(basename "$0") [ПАРАМЕТРЫ]

Параметры:
  -b, --bucket BUCKET  Имя бакета (по умолчанию: videos)
  -u, --url URL        Supabase URL (по умолчанию: \$SUPABASE_URL)
  -k, --key KEY        Supabase Key (по умолчанию: \$SUPABASE_ANON_KEY)
  --dry-run            Режим симуляции (только показать план перемещения)
  -h, --help           Показать эту справку

Переменные окружения:
  SUPABASE_URL / NEXT_PUBLIC_SUPABASE_URL
  SUPABASE_ANON_KEY / NEXT_PUBLIC_SUPABASE_ANON_KEY
  BUCKET_NAME
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--bucket)
            BUCKET_NAME="$2"
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
        --dry-run)
            DRY_RUN=1
            shift
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

echo "=========================================================="
echo "  SHOWCASE · Supabase Storage Folder Organizer"
echo "=========================================================="
echo "  Target URL : ${SUPABASE_URL}"
echo "  Bucket     : ${BUCKET_NAME}"
echo "  Dry Run    : $([ $DRY_RUN -eq 1 ] && echo 'ВКЛЮЧЕН (без изменений)' || echo 'ВЫКЛЮЧЕН')"
echo "----------------------------------------------------------"

mkdir -p "${TEMP_DIR}"

# Маппинг файлов: старый путь -> новый путь
declare -a MAPPINGS=(
    "family_v.mp4:family/family_01.mp4"
    "v_family_fix.mp4:family/family_02.mp4"
    "wellness_v.mp4:wellness/wellness_01.mp4"
    "v_wellness_fix.mp4:wellness/wellness_02.mp4"
    "guests_v.mp4:guests/guests_01.mp4"
    "v_guests_fix.mp4:guests/guests_02.mp4"
    "investor_v.mp4:investor/investor_01.mp4"
    "v_investor_fix.mp4:investor/investor_02.mp4"
    "architecture_v.mp4:architecture/architecture_01.mp4"
    "v_architecture_fix.mp4:architecture/architecture_02.mp4"
)

for item in "${MAPPINGS[@]}"; do
    IFS=":" read -r old_file new_file <<< "${item}"
    echo "🔄 Обработка: [${old_file}] -> [${new_file}]"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "   (Dry run) Скачивание ${old_file} -> Загрузка в ${new_file} -> Удаление ${old_file}"
        continue
    fi

    local_temp="${TEMP_DIR}/$(basename "${old_file}")"

    # 1. Скачивание старого файла
    echo "   ⬇️ Скачивание ${old_file}..."
    download_code=$(curl -s -w "%{http_code}" -o "${local_temp}" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        "${SUPABASE_URL}/storage/v1/object/public/${BUCKET_NAME}/${old_file}")

    if [ "${download_code}" -ne 200 ] || [ ! -s "${local_temp}" ]; then
        echo "   ⚠️ Файл ${old_file} отсутствует в бакете (HTTP ${download_code}), пропуск."
        rm -f "${local_temp}"
        continue
    fi

    # 2. Загрузка в новую структуру
    echo "   ⬆️ Загрузка в ${new_file}..."
    upload_code=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: video/mp4" \
        -H "x-upsert: true" \
        --data-binary "@${local_temp}" \
        "${SUPABASE_URL}/storage/v1/object/${BUCKET_NAME}/${new_file}")

    if [ "${upload_code}" -ge 200 ] && [ "${upload_code}" -lt 300 ]; then
        echo "   ✅ Успешно загружен в ${new_file}"

        # 3. Удаление старого файла
        echo "   🗑️ Удаление старого файла ${old_file}..."
        curl -s -X DELETE \
            -H "apikey: ${SUPABASE_ANON_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
            -H "Content-Type: application/json" \
            -d "{\"prefixes\": [\"${old_file}\"]}" \
            "${SUPABASE_URL}/storage/v1/object/${BUCKET_NAME}" >/dev/null || true
    else
        echo "   ❌ Ошибка загрузки в ${new_file} (HTTP ${upload_code})"
    fi

    rm -f "${local_temp}"
done

echo "----------------------------------------------------------"
echo "✅ Организация структуры хранилища завершена!"
