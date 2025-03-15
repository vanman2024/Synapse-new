/**
 * Script to list all tables in the base
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Get base metadata
async function listTables() {
  try {
    console.log('Connecting to Airtable base:', process.env.DEV_AIRTABLE_BASE_ID);
    console.log('Using PAT:', process.env.DEV_AIRTABLE_PAT ? 'Yes (set)' : 'No (not set)');
    
    // Unfortunately, the Airtable JS SDK doesn't provide a direct method to list tables
    // As a workaround, we'll try to access some common table names and check for errors
    
    const tablesToCheck = ['Modules', 'Phases', 'Sessions', 'Table 1', 'Dev Tasks', 'Grid view'];
    
    console.log('\nAttempting to access tables in base:');
    
    for (const tableName of tablesToCheck) {
      try {
        // Try to get a single record from the table
        await base(tableName).select({ maxRecords: 1 }).firstPage();
        console.log(`✅ Table "${tableName}" exists`);
      } catch (error) {
        if (error.statusCode === 404) {
          console.log(`❌ Table "${tableName}" does not exist`);
        } else {
          console.log(`❓ Table "${tableName}" - error: ${error.message}`);
        }
      }
    }
    
    console.log("\nNote: Airtable's JavaScript SDK doesn't provide a direct method to list all tables.");
    console.log("You may need to check the Airtable UI for the correct table names.");
    
  } catch (error) {
    console.error('Error listing tables:', error);
  }
}

// Run the script
listTables();