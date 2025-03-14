module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  env: {
    node: true,
    es6: true,
  },
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  rules: {
    // Temporarily allow 'any' type but warn about it
    '@typescript-eslint/no-explicit-any': 'warn',
    
    // Better handling of unused variables
    '@typescript-eslint/no-unused-vars': ['warn', { 
      'argsIgnorePattern': '^_',
      'varsIgnorePattern': '^_',
      'caughtErrorsIgnorePattern': '^_'
    }],
    'no-unused-vars': 'off', // Use the TypeScript version instead
    
    // Keep off during development but plan to enable
    'no-undef': 'off',
    
    // Additional rules for code quality
    'no-console': 'warn', // Warn about console.log left in code
    'no-duplicate-imports': 'error',
    'no-return-await': 'error', // Return await is redundant
    'prefer-const': 'warn', // Prefer const over let when possible
  },
};