/**
 * Script to set up example session records in Airtable
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

// Create example session records
async function setupSessions() {
  try {
    console.log('Setting up example session records...');
    
    const sessions = [
      {
        Date: new Date().toISOString().split('T')[0],
        Branch: 'feature/content-controller-implementation',
        Focus: 'Implement Content Service with AI integration',
        Status: 'Complete',
        StartTime: '09:00',
        EndTime: '11:30',
        Summary: 'Implemented Content Service with OpenAI integration. Added tests and documentation.',
        Commits: 'feat: Implement Content Service with AI integration'
      }
    ];
    
    // Create session records
    const records = await base('Sessions').create(sessions.map(session => ({ fields: session })));
    
    console.log(`Created ${records.length} session records.`);
    console.log('Sessions setup complete.');
  } catch (error) {
    console.error('Error setting up sessions:', error.message);
  }
}

// Run the script
setupSessions();