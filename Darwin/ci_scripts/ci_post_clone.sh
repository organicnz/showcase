#!/bin/sh

#  ci_post_clone.sh
#  Showcase
#
#  This script runs after Xcode Cloud checks out the code but before it builds.
#  It injects the secure environment variables configured in the Xcode Cloud UI
#  and trusts Swift package plugins for non-interactive CI builds.

set -e

echo "=== Xcode Cloud Post-Clone Script ==="

# ──────────────────────────────────────────────
# 1. Trust Swift Package Plugins & Macros
#    NOTE: The key "IDESkipPackagePluginFingerprintValidatation" is Apple's
#    actual key name (with the intentional double "ata"). Do NOT "fix" this typo.
# ──────────────────────────────────────────────
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
echo "✅ Plugin and macro validation bypassed"

# ──────────────────────────────────────────────
# 2. Inject Supabase secrets into Skip.env
# ──────────────────────────────────────────────
# Navigate to the repository root (Xcode Cloud runs scripts from ci_scripts/)
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Append the SLASH workaround for xcconfig (// is treated as a comment)
echo "SLASH = /" >> Skip.env

if [ -n "$SUPABASE_URL" ]; then
    # Replace // with $(SLASH)$(SLASH) to prevent xcconfig from treating it as a comment
    SAFE_URL=$(echo "$SUPABASE_URL" | sed 's/\/\//$(SLASH)$(SLASH)/g')
    echo "SUPABASE_URL = $SAFE_URL" >> Skip.env
    echo "✅ Injected SUPABASE_URL"
else
    echo "⚠️  WARNING: SUPABASE_URL environment variable is not set in Xcode Cloud Workflow!"
fi

if [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "SUPABASE_ANON_KEY = $SUPABASE_ANON_KEY" >> Skip.env
    echo "✅ Injected SUPABASE_ANON_KEY"
else
    echo "⚠️  WARNING: SUPABASE_ANON_KEY environment variable is not set in Xcode Cloud Workflow!"
fi

echo "=== Post-Clone Script Complete ==="
