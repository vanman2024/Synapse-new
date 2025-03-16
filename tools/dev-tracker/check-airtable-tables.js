/**
 * Script to check the table structure in Airtable
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// List of tables to check
const tables = ['Phases', 'Modules', 'Sessions'];

// Check table structure
async function checkTables() {
  console.log(`Checking Airtable base: ${process.env.DEV_AIRTABLE_BASE_ID}`);
  console.log(`Using PAT: ${process.env.DEV_AIRTABLE_PAT ? '✓ (set)' : '✗ (not set)'}`);
  
  for (const tableName of tables) {
    console.log(`\n[Checking table: ${tableName}]`);
    
    try {
      // Try to get records from the table
      const records = await base(tableName).select({ maxRecords: 5 }).firstPage();
      
      console.log(`Table status: ✓ (exists)`);
      console.log(`Records found: ${records.length}`);
      
      if (records.length > 0) {
        // Get field information from the first record
        console.log('\nFields available:');
        Object.keys(records[0].fields).forEach(field => {
          const value = records[0].fields[field];
          let valueType = typeof value;
          
          // For arrays, check if they're links
          if (Array.isArray(value)) {
            if (value.length > 0 && typeof value[0] === 'string' && value[0].startsWith('rec')) {
              valueType = 'Linked Records';
            } else {
              valueType = 'Array';
            }
          }
          
          console.log(`- ${field} (${valueType})`);
        });
        
        // Display sample record
        console.log('\nSample record:');
        console.log(JSON.stringify(records[0].fields, null, 2));
      } else {
        console.log('No records found in table.');
      }
    } catch (error) {
      console.log(`Table status: ✗ (error)`);
      console.log(`Error: ${error.message}`);
    }
  }
}

// Run the check
checkTables().catch(error => {
  console.error('Error checking tables:', error);
});