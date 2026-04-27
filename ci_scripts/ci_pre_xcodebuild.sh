#!/bin/sh

# Skip validation for package plugins (Fixes "Plugin must be enabled before it can be used" in Xcode Cloud)
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipMacroFingerprintValidation -bool YES

