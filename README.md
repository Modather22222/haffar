# حفّار (Haffar)

RTL Arabic gamified learning app — Flutter + Supabase.

## Stack

| Layer | Choice |
|---|---|
| UI | Flutter 3.x, Material 3, RTL (`ar-SA`) |
| State | `provider` (focused `ChangeNotifier`s under `lib/providers/`) |
| Routing | `go_router` for all navigation (`Routes` constants) |
| Backend | Supabase (Postgres + Auth + PostgREST RPCs) |
| Design | `lib/design_system/` — `HaffarColors`, `HaffarTextStyles`, components |

## Project layout

```
lib/
  screens/          Full-page UIs
  widgets/          Reusable widgets (+ question_widgets/ factory)
  providers/        ChangeNotifiers (content, economy, progress, session)
  services/         Repositories — sole data layer (no raw RPCs in screens)
  models/           Immutable fromMap data classes
  design_system/    Colors, text styles, shared components
  utils/            Routes, game constants, logging, sound
supabase/migrations/ SQL migrations (mirror cloud history)
test/               Unit tests
```

## Prerequisites

- Flutter SDK matching `pubspec.yaml` (`^3.11.5`)
- JDK 17 (Android builds)
- A keystore for release builds (see `docs/SECRETS_SETUP.md`)

## Local development

```bash
# 1. Install deps
flutter pub get

# 2. Configure Supabase defines (gitignored)
cp env.example.json env.json
# edit env.json with your project URL + publishable key

# 3. Run
flutter run --dart-define-from-file=env.json
```

`env.json` is gitignored. Never commit keys.

## Quality gates

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib/ test/
flutter test
```

CI runs all three on every push to `main` and only then builds the release APK.

## Release build (local)

```bash
export KEYSTORE_PATH=/path/to/release.keystore
export KEYSTORE_PASSWORD=...
export KEY_ALIAS=...
export KEY_PASSWORD=...
export VERSION_CODE=1 VERSION_NAME=1.0.0

flutter build apk --release --target-platform=android-arm64 \
  --dart-define-from-file=env.json \
  --dart-define=VERSION_CODE=$VERSION_CODE \
  --dart-define=VERSION_NAME=$VERSION_NAME
```

Release builds require a keystore — they fail fast if `KEYSTORE_PATH` /
`key.store` is missing (no silent debug signing). R8 minification is enabled.

## CI

`.github/workflows/build-release-apk.yml` on push to `main`:

1. Validate 6 secrets (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, keystore ×4)
2. `dart format` gate → `flutter analyze` → `flutter test` (all hard gates)
3. Decode keystore from `KEYSTORE_BASE64`
4. Build ARM64 release APK with `--dart-define` secrets
5. Upload APK + R8 mapping (30-day retention)

## Backend

- Migrations: `supabase/migrations/*.sql` (see README there)
- Game economy is **server-authoritative**: clients never UPDATE
  `profiles` / `xp_events` / `heart_events` — only SECURITY DEFINER RPCs
  (`get_hearts`, `consume_heart`, `add_xp_event`, `update_streak`,
  `update_own_profile`, `reset_progress`).
- RLS on every table; user RPCs require `authenticated` and assert
  `auth.uid() = p_user_id`.

## Docs

- `plan.md` — product/UX plan
- `docs/SECRETS_SETUP.md` — GitHub secrets + keystore guide
- `docs/project.md`, `docs/mascot.md` — project notes
