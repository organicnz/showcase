#!/bin/bash
# Daily Supabase Cleanup Setup Script
# This script sets up the daily cleanup for Disk IO budget management

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load environment variables if available
if [ -f "${REPO_ROOT}/.env.local" ]; then
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/.env.local"
elif [ -f "${REPO_ROOT}/.env" ]; then
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/.env"
fi

PROJECT_REF="${PROJECT_REF:-smyfjmdjzfwdehynwfep}"
FUNCTION_NAME="${FUNCTION_NAME:-daily-cleanup}"
DEPLOYED=false

echo "============================================"
echo "DAILY SUPABASE CLEANUP SETUP"
echo "============================================"
echo ""

# Step 1: Verify GitHub secrets are set
echo "--- Step 1: Checking GitHub Secrets ---"
GH_URL_SECRET=$(gh secret get SUPABASE_FUNCTIONS_URL 2>/dev/null || echo "NOT_SET")
GH_SERVICE_KEY=$(gh secret get SUPABASE_SERVICE_ROLE_KEY 2>/dev/null || echo "NOT_SET")

if [ "$GH_URL_SECRET" = "NOT_SET" ] || [ "$GH_SERVICE_KEY" = "NOT_SET" ]; then
    echo "❌ GitHub secrets not found. Setting up..."
    if [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
        echo "Error: Please set SUPABASE_SERVICE_ROLE_KEY in your environment before running this script."
        exit 1
    fi
    gh secret set SUPABASE_FUNCTIONS_URL --body "https://${PROJECT_REF}.supabase.co/functions/v1/${FUNCTION_NAME}"
    gh secret set SUPABASE_SERVICE_ROLE_KEY --body "$SUPABASE_SERVICE_ROLE_KEY"
    echo "✅ GitHub secrets set"
else
    echo "✅ GitHub secrets already configured"
fi

echo ""

# Step 2: Verify edge function source code exists
echo "--- Step 2: Checking Edge Function Source ---"
if [ -f "supabase/functions/${FUNCTION_NAME}/index.ts" ]; then
    echo "✅ Edge function source found: supabase/functions/${FUNCTION_NAME}/index.ts"
    echo "   Lines: $(wc -l < supabase/functions/${FUNCTION_NAME}/index.ts)"
else
    echo "❌ Edge function source NOT found"
    echo "   Expected: supabase/functions/${FUNCTION_NAME}/index.ts"
    exit 1
fi

echo ""

# Step 3: Verify GitHub workflow exists
echo "--- Step 3: Checking GitHub Workflow ---"
if [ -f ".github/workflows/daily-cleanup.yml" ]; then
    echo "✅ GitHub workflow found: .github/workflows/daily-cleanup.yml"
else
    echo "❌ GitHub workflow NOT found"
    exit 1
fi

echo ""

# Step 4: Attempt Supabase function deployment
echo "--- Step 4: Deploying Edge Function to Supabase ---"

# Method 1: Try supabase CLI
if command -v supabase &>/dev/null; then
    echo "   Trying supabase CLI..."
    supabase functions deploy "${FUNCTION_NAME}" 2>/dev/null && {
        echo "   ✅ Deployed via supabase CLI"
        DEPLOYED=true
    }
fi

# Method 2: Try Supabase API (requires proper auth)
if [ "$DEPLOYED" != "true" ]; then
    echo "   Trying Supabase management API..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://api.supabase.com/v1/projects/${PROJECT_REF}/functions" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY:-}" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"${FUNCTION_NAME}\"}" 2>&1)
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo "   ✅ Deployed via Supabase API"
        DEPLOYED=true
    else
        echo "   ⚠️ API deployment attempted (may need manual deploy)"
    fi
fi

# Method 3: Provide Dashboard instructions
if [ "$DEPLOYED" != "true" ]; then
    echo ""
    echo "   ⚠️ Automatic deployment failed."
    echo "   Please deploy manually:"
    echo "   1. Go to: https://app.supabase.io/project/${PROJECT_REF}/functions"
    echo "   2. Find '${FUNCTION_NAME}' function"
    echo "   3. Click 'Deploy'"
    echo ""
    echo "   OR via Supabase Dashboard > Functions > Deploy"
fi

echo ""
echo "============================================"
echo "SETUP COMPLETE"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. ✅ GitHub secrets configured"
echo "2. ✅ Edge function source ready"
echo "3. ✅ GitHub workflow ready"
echo "4. Please complete: Deploy function to Supabase Dashboard"
echo ""
echo "After deployment, the workflow will run daily at 02:00 UTC"
echo "and call the cleanup function to manage Disk IO budget."
