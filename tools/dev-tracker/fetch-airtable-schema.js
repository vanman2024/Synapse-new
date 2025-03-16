/**
 * fetch-airtable-schema.js - Get full schema details from Airtable
 */
require('dotenv').config();
const Airtable = require('airtable');
const fs = require('fs');

async function fetchAirtableSchema() {
  try {
    console.log('Connecting to Airtable...');
    
    const apiKey = process.env.DEV_AIRTABLE_PAT;
    const baseId = process.env.DEV_AIRTABLE_BASE_ID;
    
    if (!apiKey || !baseId) {
      throw new Error('Missing Airtable credentials in environment variables');
    }
    
    const base = new Airtable({ apiKey }).base(baseId);
    
    // Get the Sessions table
    console.log('Fetching Sessions records...');
    const sessionsRecords = await base('Sessions').select({
      maxRecords: 3,
      view: 'Grid view'
    }).firstPage();
    
    if (sessionsRecords && sessionsRecords.length > 0) {
      console.log(`\nFound ${sessionsRecords.length} session records.`);
      console.log('\nSample Session Record:');
      
      // Log the full record including _rawJson which contains all metadata
      const fullRecord = sessionsRecords[0]._rawJson;
      console.log(JSON.stringify(fullRecord, null, 2));
      
      // Save to a file for reference
      fs.writeFileSync('airtable-session-schema.json', JSON.stringify(fullRecord, null, 2));
      console.log('\nSaved full schema to airtable-session-schema.json');
    } else {
      console.log('No session records found.');
    }
  } catch (error) {
    console.error('Error fetching Airtable schema:', error);
  }
}

// Run the function
fetchAirtableSchema();