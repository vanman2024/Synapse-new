/**
 * Setup script for Airtable development tracking
 * This script populates Airtable tables with data from CSV files
 * and sets up new tables for enhanced tracking
 */
const airtableClient = require('./airtable-client');
const fs = require('fs');
const path = require('path');
const { parse } = require('csv-parse/sync');
const { createComponentRegistryTable } = require('./create-component-registry');
const { enhanceSessionsTable } = require('./enhance-sessions');
// Import the maintain-sessions script but don't run it immediately
// It will be run separately after setup to avoid circular dependencies
const maintainSessions = require('./maintain-sessions');

// CSV file paths
const phasesCSV = path.join(__dirname, 'csv/phases.csv');
const modulesCSV = path.join(__dirname, 'csv/modules.csv');
const sessionsCSV = path.join(__dirname, 'csv/sessions.csv');

// Parse CSV and create records
async function importCSV(filePath, tableName, fieldMap = {}) {
  try {
    console.log(`Importing ${tableName} from ${path.basename(filePath)}...`);
    
    // Read and parse CSV
    const content = fs.readFileSync(filePath, 'utf8');
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true
    });
    
    console.log(`Found ${records.length} records to import.`);
    
    // Import records
    let successCount = 0;
    for (const record of records) {
      try {
        // Map fields if needed
        const mappedRecord = {};
        for (const [key, value] of Object.entries(record)) {
          const mappedKey = fieldMap[key] || key;
          mappedRecord[mappedKey] = value;
        }
        
        await airtableClient.createRecord(tableName, mappedRecord);
        successCount++;
      } catch (error) {
        console.error(`Error importing record:`, error.message);
      }
    }
    
    console.log(`Successfully imported ${successCount} of ${records.length} records.`);
    return successCount;
  } catch (error) {
    console.error(`Error importing ${tableName}:`, error);
    return 0;
  }
}

// Setup tables in Airtable
async function setupTables() {
  try {
    console.log('Setting up Airtable for enhanced tracking...');
    
    // Create new ComponentRegistry table
    await createComponentRegistryTable();
    
    // Enhance Sessions table with Git context fields
    await enhanceSessionsTable();
    
    console.log('Populating Airtable tables from CSV files...');
    
    // Import phases
    if (fs.existsSync(phasesCSV)) {
      await importCSV(phasesCSV, 'Phases');
    } else {
      console.error(`Phases CSV file not found: ${phasesCSV}`);
    }
    
    // Import modules
    if (fs.existsSync(modulesCSV)) {
      await importCSV(modulesCSV, 'Modules');
    } else {
      console.error(`Modules CSV file not found: ${modulesCSV}`);
    }
    
    // Import sessions
    if (fs.existsSync(sessionsCSV)) {
      await importCSV(sessionsCSV, 'Sessions');
    } else {
      console.error(`Sessions CSV file not found: ${sessionsCSV}`);
    }
    
    console.log('Airtable setup complete!');
  } catch (error) {
    console.error('Error setting up Airtable tables:', error);
  }
}

// Run setup
setupTables();