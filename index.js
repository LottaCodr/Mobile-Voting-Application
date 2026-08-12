import { registerRootComponent } from 'expo';
import { ExpoRoot } from 'expo-router';

// Hard-code the app directory so Metro never has to inline
// process.env.EXPO_ROUTER_APP_ROOT (that env var is what breaks
// expo-router/_ctx when a mismatched/global Expo CLI starts the bundler).
// Must be exported or Fast Refresh won't update the context.
export function App() {
  const ctx = require.context('./app');
  return <ExpoRoot context={ctx} />;
}

registerRootComponent(App);
