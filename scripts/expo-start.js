#!/usr/bin/env node
/**
 * Always start the project-local Expo CLI. A globally installed `expo`
 * (different SDK) is what produced:
 *   - EXPO_ROUTER_APP_ROOT / require.context
 *   - VirtualViewNativeComponent "onModeChange" codegen failures
 */
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const cli = path.join(root, 'node_modules', 'expo', 'bin', 'cli');

if (!fs.existsSync(cli)) {
  console.error('Local Expo CLI is missing. From the project folder run: npm install');
  process.exit(1);
}

console.log(`
CivicVote is Expo SDK 57. The Play Store Expo Go app is still an older SDK,
so it will show "Project is incompatible with this version of Expo Go".

On the Android phone:
  1. Uninstall Play Store Expo Go
  2. Open this APK (Expo Go 57.0.3) and install it:
     https://github.com/expo/expo-go-releases/releases/download/Expo-Go-57.0.3/Expo-Go-57.0.3.apk
  3. Open that Expo Go, then scan the QR code below
  4. Do not type \`expo start\` — that hits a global CLI. Use \`npm start\`.

If Windows reports EPERM on metro-cache, stop every Expo process and delete
%LOCALAPPDATA%\\Temp\\metro-cache, then run: npm run start:clear
`);

const child = spawn(process.execPath, [cli, 'start', ...process.argv.slice(2)], {
  cwd: root,
  stdio: 'inherit',
  env: process.env,
  windowsHide: true,
});

child.on('exit', (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  process.exit(code ?? 1);
});
