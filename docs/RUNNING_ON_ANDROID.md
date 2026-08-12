# Run CivicVote on a physical Android phone

This project is **Expo SDK 57**. Google Play’s Expo Go build is still an
older SDK, so it will refuse the project with:

> Project is incompatible with this version of Expo Go

That is expected. Updating Expo Go from the Play Store will not help until
Expo’s SDK 57 client is approved. Install the official SDK 57 APK instead.

## 1. Remove the global Expo CLI

The global `expo` under `%AppData%\npm\node_modules\expo` is a different
SDK. It is what caused:

- `EXPO_ROUTER_APP_ROOT` / `require.context`
- `VirtualViewNativeComponent.js: Unable to determine event arguments for "onModeChange"`

```powershell
npm uninstall -g expo
```

Always start this app with `npm start` from the project folder.

## 2. Install Expo Go 57 on the phone

1. On **The_DevOps** (or any Android device), uninstall Play Store **Expo Go**.
2. In Chrome on the phone, open:

   https://github.com/expo/expo-go-releases/releases/download/Expo-Go-57.0.3/Expo-Go-57.0.3.apk

3. Allow **Install unknown apps** for Chrome if Android asks.
4. Install and open **Expo Go 57.0.3**.

Or download the same APK on the PC from [expo.dev/go](https://expo.dev/go?sdkVersion=57&platform=android&device=true) and copy it to the phone.

## 3. Start Metro with the local CLI

```powershell
cd C:\Users\MAFIA\Documents\Projects\Apps\mobileapps\mobile_voting_application
npm install
npm start
```

If Metro cache permissions fail (`EPERM ... metro-cache`):

1. Stop every Expo / Node process using the project.
2. Delete `%LOCALAPPDATA%\Temp\metro-cache`.
3. Run `npm run start:clear`.

## 4. Open the app

Scan the QR code **from the Expo Go 57 app** (not the Camera app’s Play Store listing).

Do **not** press `a` if `adb` reports `Broken pipe`. That only talks to USB
debugging; the QR code does not need `adb`.

Phone and PC must be on the same Wi‑Fi. If the LAN URL fails, in the Metro
terminal press `s` only to switch client type if you later use a dev build;
for Expo Go leave it on Expo Go, and press `?` then use tunnel if needed:

```powershell
npm start -- --tunnel
```

## Why `expo start` still fails

`expo start` (no `npx` / no `npm start`) launches the **global** CLI. That
CLI transforms React Native 0.86 with an older `@react-native/codegen` and
crashes on `onModeChange`. `npm start` always runs `node_modules/expo`.
