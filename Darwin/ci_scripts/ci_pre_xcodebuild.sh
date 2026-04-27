#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Showcase
#
#  Runs immediately before xcodebuild. Reinforces plugin trust settings.

set -e

echo "=== Xcode Cloud Pre-Xcodebuild Script ==="

# Trust Swift Package Plugins & Macros for both Xcode and xcodebuild domains
# NOTE: "IDESkipPackagePluginFingerprintValidatation" is Apple's actual key name.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipMacroFingerprintValidation -bool YES

echo "✅ Plugin and macro validation bypassed (pre-xcodebuild)"
echo "=== Pre-Xcodebuild Script Complete ==="
