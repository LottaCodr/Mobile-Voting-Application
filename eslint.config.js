const expo = require('eslint-config-expo/flat');

module.exports = [
  ...expo,
  {
    ignores: ['supabase/**', 'node_modules/**', 'dist/**', '.expo/**'],
  },
];
