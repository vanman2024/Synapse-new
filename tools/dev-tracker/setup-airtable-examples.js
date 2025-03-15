/**
 * Master script to set up all Airtable examples
 */
const { execSync } = require('child_process');
const path = require('path');

console.log('Running all setup scripts for Airtable...');

try {
  console.log('\n1. Setting up phase examples...');
  execSync('node ' + path.join(__dirname, 'setup-phase-examples.js'), { stdio: 'inherit' });
  
  console.log('\n2. Setting up module examples...');
  execSync('node ' + path.join(__dirname, 'setup-module-examples.js'), { stdio: 'inherit' });
  
  console.log('\n3. Setting up session examples...');
  execSync('node ' + path.join(__dirname, 'setup-session-examples.js'), { stdio: 'inherit' });
  
  console.log('\nAirtable setup complete!');
  console.log('You should now see example records in your Airtable base.');
  console.log('Remember to set up the tables with the correct fields before running the import script.');
} catch (error) {
  console.error('\nError running setup scripts:', error.message);
}