/**
 * Script to set up the field structure for Airtable tables
 * This script doesn't use the Airtable API to create fields (which is not possible via the standard API)
 * Instead, it creates example records with the expected field structure to help manually set up the tables
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');
const fs = require('fs');

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

// Example records with expected field structure
const exampleRecords = {
  // Phases table
  Phases: [
    {
      Name: 'Foundation & Verification',
      PhaseNumber: 1,
      Status: 'Completed',
      Description: 'Setting up the core foundation of the application'
    }
  ],
  
  // Modules table
  Modules: [
    {
      Name: 'Set up Express server with basic routes',
      PhaseName: 'Foundation & Verification',
      PhaseNumber: 1,
      Status: 'Completed',
      Description: 'Configure Express server and basic routing structure',
      LastUpdated: new Date().toISOString()
    }
  ],
  
  // Sessions table
  Sessions: [
    {
      Date: new Date().toISOString(),
      Branch: 'feature/example-branch',
      Focus: 'Example Module',
      Status: 'Completed',
      StartTime: '10:00',
      EndTime: '11:00',
      Summary: 'This is an example session summary',
      Commits: JSON.stringify(['abc123 Example commit message']),
      Notes: 'Additional notes about the session'
    }
  ]
};

// Create example records in each table
async function setupTableFields() {
  try {
    console.log('Setting up table field structure with example records...');
    
    // Process each table
    for (const [tableName, records] of Object.entries(exampleRecords)) {
      console.log(`\nSetting up ${tableName} table...`);
      
      try {
        // Attempt to create example record
        const createdRecords = await base(tableName).create(records.map(record => ({ fields: record })));
        console.log(`Created ${createdRecords.length} records in ${tableName} table.`);
        
        // Log the structure for reference
        console.log(`${tableName} table structure:`);
        for (const fieldName of Object.keys(records[0])) {
          console.log(`- ${fieldName}: ${typeof records[0][fieldName]}`);
        }
        
        // Optionally output a guide for setting up fields manually
        const fieldTypeGuide = Object.entries(records[0]).map(([field, value]) => {
          let type = 'Single line text';
          if (typeof value === 'number') type = 'Number';
          if (typeof value === 'boolean') type = 'Checkbox';
          if (field === 'Status') type = 'Single select';
          if (field === 'Description' || field === 'Summary' || field === 'Notes') type = 'Long text';
          if (field === 'Date' || field === 'LastUpdated') type = 'Date';
          if (field === 'Commits') type = 'Long text';
          
          return `${field}: ${type}`;
        });
        
        console.log('\nRecommended field types:');
        fieldTypeGuide.forEach(guide => console.log(`- ${guide}`));
        
      } catch (error) {
        console.error(`Error setting up ${tableName} table:`, error.message);
      }
    }
    
    console.log('\nTable setup guide completed!');
    console.log('IMPORTANT: If fields are missing, please add them manually in the Airtable UI.');
    console.log('Then run the setup-airtable.js script to populate the data from the Development Overview document.');
    
  } catch (error) {
    console.error('Error setting up table fields:', error);
  }
}

// Run the setup
setupTableFields();