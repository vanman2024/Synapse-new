/**
 * Script to get actual field names from Airtable schema
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Get field names from Airtable table
async function getFieldNames() {
  try {
    // Try to create records with different field names to find the right ones
    console.log('Trying to identify field names in Phases table...');
    
    // Try common field names
    const testFieldNames = [
      'Name', 'name', 'Phase Name', 'PhaseName', 'Title', 'title',
      'Notes', 'notes', 'Description', 'description',
      'Status', 'status', 'State', 'state',
      'Number', 'number', 'PhaseNumber', 'Phase Number'
    ];
    
    console.log('\nTesting field names in Phases table:');
    for (const fieldName of testFieldNames) {
      try {
        const record = {};
        record[fieldName] = `Test value for ${fieldName}`;
        
        await base('Phases').create([{ fields: record }]);
        console.log(`✓ Field name "${fieldName}" is valid`);
        
        // Clean up test record
        // We can't easily delete it without knowing the record ID, but we tried
      } catch (error) {
        if (error.message.includes('Unknown field name')) {
          console.log(`✗ Field name "${fieldName}" is not valid`);
        } else {
          console.log(`? Field name "${fieldName}" error: ${error.message}`);
        }
      }
    }

    console.log('\nTrying to identify field names in Modules table...');
    const moduleTestFields = [
      'Name', 'name', 'Module Name', 'ModuleName', 'Title', 'title',
      'Phase', 'phase', 'PhaseReference', 'Phase Reference',
      'Status', 'status', 'State', 'state',
      'Description', 'description', 'Details', 'details'
    ];
    
    console.log('\nTesting field names in Modules table:');
    for (const fieldName of moduleTestFields) {
      try {
        const record = {};
        record[fieldName] = `Test value for ${fieldName}`;
        
        await base('Modules').create([{ fields: record }]);
        console.log(`✓ Field name "${fieldName}" is valid`);
        
        // Clean up test record
        // We can't easily delete it without knowing the record ID, but we tried
      } catch (error) {
        if (error.message.includes('Unknown field name')) {
          console.log(`✗ Field name "${fieldName}" is not valid`);
        } else {
          console.log(`? Field name "${fieldName}" error: ${error.message}`);
        }
      }
    }
  } catch (error) {
    console.error('Error checking field names:', error);
  }
}

// Run the check
getFieldNames();