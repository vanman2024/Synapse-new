/**
 * Script to set up example phase records in Airtable
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');
const fs = require('fs');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Create example phase records
async function setupPhases() {
  try {
    console.log('Setting up example phase records...');
    
    const phases = [
      {
        Name: 'Foundation & Verification',
        Status: 'Complete',
        Description: 'Setting up the core foundation of the application'
      },
      {
        Name: 'Content Generation Enhancement',
        Status: 'Current',
        Description: 'Enhancing content generation capabilities'
      },
      {
        Name: 'User Management & Security',
        Status: 'Planned',
        Description: 'Implementing user authentication and security'
      }
    ];
    
    // Create phase records
    const records = await base('Phases').create(phases.map(phase => ({ fields: phase })));
    
    console.log(`Created ${records.length} phase records.`);
    console.log('Phases setup complete.');
  } catch (error) {
    console.error('Error setting up phases:', error.message);
  }
}

// Run the script
setupPhases();