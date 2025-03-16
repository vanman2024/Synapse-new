/**
 * Script to import CSV data into Airtable
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');
const fs = require('fs');
const { parse } = require('csv-parse/sync');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Import data from CSV to Airtable
async function importCSV(csvFile, tableName) {
  console.log(`Importing ${csvFile} to ${tableName}...`);
  
  try {
    // Read and parse CSV
    const content = fs.readFileSync(path.join(__dirname, 'csv', csvFile), 'utf8');
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true
    });
    
    console.log(`Found ${records.length} records to import`);
    
    // Import in batches of 10
    const BATCH_SIZE = 10;
    let successCount = 0;
    
    // Process records in batches
    for (let i = 0; i < records.length; i += BATCH_SIZE) {
      const batch = records.slice(i, i + BATCH_SIZE).map(record => ({
        fields: record
      }));
      
      try {
        const createdRecords = await base(tableName).create(batch);
        successCount += createdRecords.length;
        console.log(`Imported batch ${i/BATCH_SIZE + 1}/${Math.ceil(records.length/BATCH_SIZE)}`);
      } catch (error) {
        console.error(`Error importing batch ${i/BATCH_SIZE + 1}:`, error.message);
      }
    }
    
    console.log(`Successfully imported ${successCount}/${records.length} records to ${tableName}`);
    return successCount;
  } catch (error) {
    console.error(`Error importing ${csvFile}:`, error);
    return 0;
  }
}

async function importAll() {
  try {
    console.log('Starting CSV imports...');
    
    // Import phases.csv to Phases table
    await importCSV('phases.csv', 'Phases');
    
    // Import modules.csv to Modules table
    await importCSV('modules.csv', 'Modules');
    
    // Import sessions.csv to Sessions table
    await importCSV('sessions.csv', 'Sessions');
    
    console.log('Import process completed');
  } catch (error) {
    console.error('Error during import:', error);
  }
}

// Run the import
importAll();