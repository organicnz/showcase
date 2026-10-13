---
name: xcode-cloud-skip-hardening
description: CI/CD release engineering, SPM build-plugin fingerprint validation bypass, Xcode Cloud pipeline hardening, and TestFlight/APK release management for Skip-based Swift apps. Use when resolving Xcode Cloud errors (Exit Code 74, plugin trust issues), configuring ci_scripts, and managing zero-exposed-secret builds.
---

# Xcode Cloud & Skip Pipeline Hardening

This skill provides operational rules, troubleshooting runbooks, and automation scripts for deploying the Showcase application via **Xcode Cloud** to **Apple TestFlight** (iOS) and building standalone Android APKs via Skip 1.0+.

---

## 1. The SPM Build Plugin Challenge (Skipstone)

### The Problem:
Xcode 15+ blocks third-party Swift Package Manager plugins (such as `skipstone`) by default, requiring a developer to click "Trust & Enable" in the GUI. In headless CI environments like Xcode Cloud, this halts builds with:
> *"Package plugin 'skipstone' is disabled and cannot be executed in this environment."*

### The Two-Layer Hardening Fix:

1. **Workspace Trust Declaration (`IDEWorkspaceChecks.plist`):**
   Ensure `Showcase.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` declares explicit trust:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>IDEDidComputeMac32BitWarning</key>
       <true/>
   </dict>
   </plist>
   ```

2. **Apple Defaults Injection (`ci_scripts/ci_pre_xcodebuild.sh` & `ci_post_clone.sh`):**
   Execute before `xcodebuild` initiates to disable package and macro fingerprint validations across both Xcode and the `xcodebuild` CLI tool:
   ```bash
   defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
   defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
   defaults write com.apple.dt.xcodebuild IDESkipPackagePluginFingerprintValidation -bool YES
   defaults write com.apple.dt.xcodebuild IDESkipMacroFingerprintValidation -bool YES
   ```

---

## 2. Preventing Exit Code 74 (SPM Dependency Failures)

Xcode Cloud runs in an ephemeral container and will terminate with `Exit code 74` if it cannot resolve remote packages synchronously.

### Mandatory Rules:
* **Track `Package.resolved` in Git:** Never put `Package.resolved` in `.gitignore`.
* **Symlink to Workspace Directory:** Xcode Cloud expects package resolutions inside the workspace's shared data folder:
  ```bash
  mkdir -p Project.xcworkspace/xcshareddata/swiftpm/
  ln -sf ../../../Package.resolved Project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  ```

---

## 3. Dynamic Zero-Exposed-Secrets Injection

Under our security architecture, no API keys or database credentials exist in repository files. Secrets are injected at build time by Xcode Cloud.

### `ci_scripts/ci_post_clone.sh` Architecture:
```bash
#!/bin/sh
set -e

echo "Injecting Xcode Cloud environment variables..."
cd ..

# 1. Provide SLASH macro to prevent // being parsed as a comment in xcconfig
echo "SLASH = /" >> Skip.env

# 2. Inject SUPABASE_URL safely
if [ -n "$SUPABASE_URL" ]; then
    SAFE_URL=$(echo "$SUPABASE_URL" | sed 's/\/\//$(SLASH)$(SLASH)/g')
    echo "SUPABASE_URL = $SAFE_URL" >> Skip.env
    echo "Successfully injected SUPABASE_URL"
else
    echo "ERROR: SUPABASE_URL missing in Xcode Cloud environment!"
    exit 1
fi

# 3. Inject SUPABASE_ANON_KEY
if [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "SUPABASE_ANON_KEY = $SUPABASE_ANON_KEY" >> Skip.env
    echo "Successfully injected SUPABASE_ANON_KEY"
else
    echo "ERROR: SUPABASE_ANON_KEY missing in Xcode Cloud environment!"
    exit 1
fi

# 4. Disable plugin fingerprint checks
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.xcodebuild IDESkipMacroFingerprintValidation -bool YES
```

---

## 4. Release Validation & Diagnostic Checklist

Before pushing a commit that triggers an Xcode Cloud release build:

| Check | Requirement | Verification Command |
|---|---|---|
| **Compilation** | Clean Swift 6 build without errors | `xcodebuild -workspace Project.xcworkspace -scheme ShowcaseCore build` |
| **Secrets Scan** | Zero plaintext keys in tracked files | `git grep -i "supabase\.co" -- ':!*.md' ':!Skip.env'` |
| **Skip Plugins** | Fingerprints bypassed | Verify `ci_scripts/ci_pre_xcodebuild.sh` exists and is executable (`chmod +x`) |
| **Package Resolved** | Symlink active and up-to-date | `ls -la Project.xcworkspace/xcshareddata/swiftpm/Package.resolved` |

---

## 5. Dual-Platform Deployment Summary

* **iOS / iPadOS:** TestFlight internal track allows instantaneous installation on the sales office iPads without App Store review delays.
* **Android:** Standalone `.apk` generated via `./gradlew assembleRelease` and directly sideloaded onto backup Android tablets.
