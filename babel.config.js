module.exports = function (api) {
  api.cache(true);
  // Fallback if a global/mismatched Expo CLI never injects this.
  // Path is relative to node_modules/expo-router/_ctx*.js.
  if (!process.env.EXPO_ROUTER_APP_ROOT) {
    process.env.EXPO_ROUTER_APP_ROOT = '../../app';
  }
  return {
    presets: ['babel-preset-expo'],
    plugins: ['react-native-worklets/plugin'],
  };
};
