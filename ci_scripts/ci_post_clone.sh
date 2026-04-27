#!/bin/sh

#  ci_post_clone.sh
#  Showcase
#
#  Created automatically.
#  This script runs after Xcode Cloud checks out the code but before it builds.
#  It injects the secure environment variables configured in the Xcode Cloud UI.

echo "Injecting Xcode Cloud environment variables..."

# Navigate to the root folder (Xcode Cloud executes scripts from within ci_scripts/)
cd ..

# Append the secrets from Xcode Cloud UI to Skip.env
echo "SLASH = /" >> Skip.env

if [ -n "$XC_SUPABASE_URL" ]; then
    # Replace // with $(SLASH)$(SLASH) to prevent xcconfig from treating it as a comment
    SAFE_URL=$(echo "$XC_SUPABASE_URL" | sed 's/\/\//$(SLASH)$(SLASH)/g')
    echo "SUPABASE_URL = $SAFE_URL" >> Skip.env
    echo "Successfully injected SUPABASE_URL"
else
    echo "WARNING: XC_SUPABASE_URL environment variable is not set in Xcode Cloud Workflow!"
fi

if [ -n "$XC_SUPABASE_ANON_KEY" ]; then
    echo "SUPABASE_ANON_KEY = $XC_SUPABASE_ANON_KEY" >> Skip.env
    echo "Successfully injected SUPABASE_ANON_KEY"
else
    echo "WARNING: XC_SUPABASE_ANON_KEY environment variable is not set in Xcode Cloud Workflow!"
fi

# Print final status
echo "Environment injection complete."

# Skip validation for package plugins (Fixes 'Plugin must be enabled before it can be used' in Xcode Cloud)
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
