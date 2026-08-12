# SDK upgrade — Expo 53 → 57

This records the dependency upgrade of the CivicVote app, what changed in the
source, and what a maintainer still has to verify on real devices.

## Version summary

| Package | Before | After |
| --- | --- | --- |
| `expo` | ~53.0.0 | ~57.0.12 |
| `react-native` | 0.79.2 | 0.86.2 |
| `react` | 19.0.0 | 19.2.3 |
| `expo-router` | ~5.1.0 | ~57.0.12 |
| `expo-constants` | ~17.1.0 | ~57.0.10 |
| `expo-font` | ~13.3.0 | ~57.0.1 |
| `expo-status-bar` | ~2.2.3 | ~57.0.1 |
| `@expo/vector-icons` | ^14.1.0 | ^15.0.2 |
| `@react-native-async-storage/async-storage` | 2.1.2 | 2.2.0 |
| `react-native-safe-area-context` | 5.4.0 | ~5.7.0 |
| `react-native-screens` | ~4.11.1 | ~4.26.0 |
| `@supabase/supabase-js` | ^2.49.4 | ^2.112.2 |
| `typescript` | ~5.8.3 | ~6.0.3 |
| `eslint-config-expo` | ~9.2.0 | ~57.0.1 |
| `eslint` | ^9.25.0 | ^9.39.1 |
| `@types/react` | ~19.0.10 | ~19.2.2 |

Newly added, because Expo SDK 57 and `expo-router` 57 expect them: `react-dom`,
`react-native-web`, `@expo/metro-runtime`, `expo-linking`,
`react-native-gesture-handler`, `react-native-reanimated`,
`react-native-worklets`, plus `expo-doctor` as a dev dependency.

Versions were taken from the `bundledNativeModules.json` manifest published
inside `expo@57.0.12` and the official `expo-template-default@sdk-57`, so they
match exactly what `expo install --fix` would pick.

## Source changes required by the upgrade

1. **Impure `Date.now()` during render** (`app/index.tsx`) — the receipt code was
   computed inline in JSX, so every re-render produced a different receipt. The
   new `react-hooks/purity` rule in `eslint-config-expo` 57 flags this as an
   error. The receipt is now generated once in the submit handler and held in
   state (`receipt`), which replaced the previous `submitted` boolean. This was a
   real correctness bug, not only a lint failure.
2. **Deprecated `SafeAreaView`** (`app/index.tsx`) — React Native's built-in
   `SafeAreaView` is deprecated and slated for removal, and it never applied
   insets on Android. It now comes from `react-native-safe-area-context`.
3. **`SafeAreaProvider`** (`app/_layout.tsx`) — required by the safe-area
   context component above; the root layout now wraps the router stack.

## Configuration changes

- `index.js` + `package.json` `main`: Expo Router now boots through a project
  entry that calls `require.context('./app')` with a string literal. This
  avoids the Metro `EXPO_ROUTER_APP_ROOT` / `require.context` crash that
  appears when a globally installed Expo CLI (a different SDK) transforms
  `node_modules/expo-router/_ctx.android.js`.
- `metro.config.js`: extends `expo/metro-config` so Metro context modules
  stay enabled for Expo Router.
- `babel.config.js`: sets `EXPO_ROUTER_APP_ROOT` if the CLI never injects it.
- `app.json`: added `newArchEnabled`, Android `edgeToEdgeEnabled` and
  `predictiveBackGestureEnabled`, and enabled the React Compiler
  (`experiments.reactCompiler`). App version bumped to 4.0.0.
- `tsconfig.json`: added `.expo/types` and `expo-env.d.ts` to `include` so
  generated typed-route definitions are picked up; excluded `node_modules`.
- `eslint.config.js`: also ignores `node_modules`, `dist` and `.expo`.
- `.gitignore`: ignores `expo-env.d.ts` and the generated `/android` and `/ios`
  directories (this project uses Continuous Native Generation).
- `package.json`: added `engines.node >= 22.13.0` and a `doctor` script.
- `docs/github-actions-quality.yml.example`: the template still ran
  `flutter analyze` / `flutter test` against a codebase that no longer contains
  Flutter. It now runs the Node/Expo checks instead.

## Verification performed

- `npm run typecheck` — passes on TypeScript 6.
- `npm run lint` — passes with zero warnings.
- `npx expo export --platform all` — web, iOS and Android bundles all build,
  including Hermes bytecode compilation for both native platforms.
- `npx expo-doctor` — 18/20 checks pass, including "packages match versions
  required by installed Expo SDK" and "required peer dependencies are
  installed". The 2 failures are network-only checks (Expo config schema and the
  React Native Directory lookup) that cannot reach `api.expo.dev` from the build
  sandbox; they are not project defects.

## Known advisories

`npm audit` reports findings that all originate from Expo's own build tooling:

- `image-size` (via `metro`, itself via `expo`) — advisory range is `<=2.0.2`
  and 2.0.2 is the newest published version, so **no fixed release exists
  upstream**. Not resolvable by this repository.
- `uuid@7` (via `@expo/config-plugins` → `xcode`) — transitive build-time
  dependency of the Expo CLI.

Neither package is present in the shipped app bundle (verified by grepping the
exported iOS bundle), so they do not affect the runtime attack surface. Running
`npm audit fix --force` would downgrade or break the Expo SDK and was
deliberately not done.

## Still to do before release

The upgrade is verified as far as bundling and static analysis can go. A
maintainer should still:

1. Run the app on a physical iOS and Android device (Expo Go for SDK 57, or a
   development build) and walk the full ballot → review → submit → receipt flow.
2. Re-test accessibility: screen-reader labels, 48 px targets and large text
   scaling, especially around the migrated safe-area layout.
3. Check Android edge-to-edge rendering, which changed in React Native 0.86.
4. If native directories were ever generated locally, delete them and re-run
   `npx expo prebuild` — SDK 57 makes prebuild clean by default.
5. Watch the Reanimated + Hermes V1 memory regression noted in the SDK 57
   release notes if animation usage grows; enable worklets bundle mode if needed.
