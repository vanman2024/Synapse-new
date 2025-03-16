/**
 * check-phases-fields.js - Check the fields in the Phases table
 */

const airtable = require('./airtable-client');

async function checkPhasesFields() {
  try {
    console.log('Fetching Phases records to determine field structure...');
    
    // Get a few phase records
    const phases = await airtable.getTable('Phases').select({
      maxRecords: 3,
      view: 'Grid view'
    }).firstPage();
    
    if (phases && phases.length > 0) {
      console.log(`\nFound ${phases.length} phase records.`);
      console.log('\nFields in Phases table:');
      
      // Get field names from the first record
      const fieldNames = Object.keys(phases[0].fields);
      fieldNames.forEach(field => {
        const value = phases[0].fields[field];
        const type = Array.isArray(value) ? 'array' : typeof value;
        console.log(`- ${field} (${type}): ${JSON.stringify(value).substring(0, 50)}${JSON.stringify(value).length > 50 ? '...' : ''}`);
      });
      
      console.log('\nSample Record:');
      console.log(JSON.stringify(phases[0].fields, null, 2));
    } else {
      console.log('No phase records found.');
    }
  } catch (error) {
    console.error('Error listing phase fields:', error);
  }
}

// Run the function
checkPhasesFields();