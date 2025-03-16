/**
 * list-session-fields.js - Lists fields in the Sessions table
 */

const airtable = require('./airtable-client');

async function listSessionFields() {
  try {
    console.log('Fetching Sessions records to determine field structure...');
    
    // Get a few session records
    const sessions = await airtable.getTable('Sessions').select({
      maxRecords: 3,
      view: 'Grid view'
    }).firstPage();
    
    if (sessions && sessions.length > 0) {
      console.log(`\nFound ${sessions.length} session records.`);
      console.log('\nFields in Sessions table:');
      
      // Get field names from the first record
      const fieldNames = Object.keys(sessions[0].fields);
      fieldNames.forEach(field => {
        const value = sessions[0].fields[field];
        const type = Array.isArray(value) ? 'array' : typeof value;
        console.log(`- ${field} (${type}): ${JSON.stringify(value).substring(0, 50)}${JSON.stringify(value).length > 50 ? '...' : ''}`);
      });
      
      console.log('\nSample Record:');
      console.log(JSON.stringify(sessions[0].fields, null, 2));
    } else {
      console.log('No session records found.');
    }
  } catch (error) {
    console.error('Error listing session fields:', error);
  }
}

// Run the function
listSessionFields();