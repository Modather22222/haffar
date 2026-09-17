# GitHub Secrets Setup Guide

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

## Required Secrets

| Secret Name | Type | Description | How to Create |
|---|---|---|---|
| `SUPABASE_URL` | plain text | Your Supabase project URL | Copy from Dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | plain text | Publishable/anon key | Copy from Dashboard → Project Settings → API → anon public |

## Keystore Secrets (for release signing)

Generate a keystore once with this command (run in PowerShell):

```powershell
keytool -genkeypair -v `
  -keystore android/key/release.keystore `
  -storetype JKS `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias haffar-key `
  -keypass YourKeyPassword `
  -storepass YourStorePassword `
  -dname "CN=Haffar, OU=Dev, O=Haffar, L=Khartoum, S=Khartoum, C=SD"
```

Then base64-encode the `.keystore` file and add as secrets:

| Secret Name | Type | Description | How to Create |
|---|---|---|---|
| `KEYSTORE_BASE64` | base64 | Base64-encoded `.keystore` file content | `Convert-ToBase64String(Get-Content -Path android/key/release.keystore -Encoding byte)` |
| `KEYSTORE_PASSWORD` | plain text | Keystore password (same as `-storepass`) | `YourStorePassword` |
| `KEY_ALIAS` | plain text | Key alias | `haffar-key` |
| `KEY_PASSWORD` | plain text | Key password (same as `-keypass`) | `YourKeyPassword` |

## Workflow Trigger

The workflow runs automatically on:
- Push to `main` or `master` branch
- Manual dispatch (`workflow_dispatch`)

Artifacts are retained for 30 days.

## Local Development (no signing needed)

For local debug builds, create `android/local.properties` manually:
```properties
flutter.sdk=C:/Users/<you>/flutter   # or wherever your Flutter SDK is
```

The build will use debug signing automatically.
