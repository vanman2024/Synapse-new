/**
 * Script to list all fields in Airtable tables
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// List records in all tables to see field names
async function listFields() {
  const tables = ['Phases', 'Modules', 'Sessions'];
  
  for (const tableName of tables) {
    console.log(`\n=== Table: ${tableName} ===`);
    
    try {
      // Try creating with a test record to see errors
      let successCount = 0;
      let errorCount = 0;
      
      console.log('Attempting to create test records to identify fields...');
      
      try {
        await base(tableName).create([{ 
          fields: { 
            'Status': 'Test', 
            'Description': 'Test description' 
          }
        }]);
        console.log('✓ Created test record with Status and Description');
        successCount++;
      } catch (error) {
        console.log(`Error: ${error.message}`);
        errorCount++;
      }
      
      try {
        await base(tableName).create([{ 
          fields: { 
            'Module Name': 'Test Module', 
            'Notes': 'Test notes'
          }
        }]);
        console.log('✓ Created test record with Module Name and Notes');
        successCount++;
      } catch (error) {
        console.log(`Error: ${error.message}`);
        errorCount++;
      }
      
      try {
        await base(tableName).create([{ 
          fields: { 
            'Phase': 'Test Phase',
            'StartTime': '10:00',
            'EndTime': '11:00'
          }
        }]);
        console.log('✓ Created test record with Phase, StartTime, and EndTime');
        successCount++;
      } catch (error) {
        console.log(`Error: ${error.message}`);
        errorCount++;
      }
      
      console.log(`Created ${successCount} test records with ${errorCount} errors`);
      
      // Get all records from the table
      const records = await base(tableName).select().firstPage();
      console.log(`Total records in table: ${records.length}`);
      
      // Extract all field names from all records
      const fieldNames = new Set();
      records.forEach(record => {
        Object.keys(record.fields).forEach(field => {
          fieldNames.add(field);
        });
      });
      
      if (fieldNames.size > 0) {
        console.log('\nField names found:');
        [...fieldNames].sort().forEach(field => {
          console.log(`- ${field}`);
        });
      } else {
        console.log('No fields found in existing records');
      }
    } catch (error) {
      console.log(`Error: ${error.message}`);
    }
  }
}

listFields().catch(console.error);