/**
 * Script to check the current table structure in Airtable
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Configuration for development tracking
const config = {
  AIRTABLE: {
    PAT: process.env.DEV_AIRTABLE_PAT,
    BASE_ID: process.env.DEV_AIRTABLE_BASE_ID,
    TABLES: {
      MODULES: process.env.DEV_AIRTABLE_MODULES_TABLE || 'Modules',
      PHASES: process.env.DEV_AIRTABLE_PHASES_TABLE || 'Phases',
      SESSIONS: process.env.DEV_AIRTABLE_SESSIONS_TABLE || 'Sessions'
    }
  }
};

// Initialize Airtable
const airtable = new Airtable({
  apiKey: config.AIRTABLE.PAT
});
const base = airtable.base(config.AIRTABLE.BASE_ID);

// Check table structure
async function checkTableStructure() {
  try {
    console.log('Checking Airtable table structure...');
    
    // Get tables
    const tables = ['Modules', 'Phases', 'Sessions'];
    
    for (const tableName of tables) {
      console.log(`\nChecking table: ${tableName}`);
      try {
        // Get a single record to examine fields
        const records = await base(tableName).select({ maxRecords: 1 }).firstPage();
        
        if (records.length > 0) {
          const fields = records[0].fields;
          console.log('Fields available:');
          Object.keys(fields).forEach(field => {
            console.log(`- ${field}`);
          });
        } else {
          console.log('No records found in table. Cannot determine fields.');
        }
      } catch (error) {
        if (error.statusCode === 404) {
          console.log(`Table '${tableName}' does not exist.`);
        } else {
          console.error(`Error checking table ${tableName}:`, error.message);
        }
      }
    }
  } catch (error) {
    console.error('Error checking table structure:', error);
  }
}

// Run the check
checkTableStructure();