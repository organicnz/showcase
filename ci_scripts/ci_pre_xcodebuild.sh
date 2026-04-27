#!/bin/sh

# Skip validation for package plugins (Fixes "Plugin must be enabled before it can be used" in Xcode Cloud)
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipMacroFingerprintValidation -bool YES

