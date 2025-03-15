/**
 * Script to set up example module records in Airtable
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

// Create example module records
async function setupModules() {
  try {
    console.log('Setting up example module records...');
    
    const modules = [
      {
        Name: 'Set up Express server with basic routes',
        Phase: 'Foundation & Verification',
        Status: 'Complete',
        Description: 'Configure Express server and basic routing structure'
      },
      {
        Name: 'Implement Content Service with AI integration',
        Phase: 'Content Generation Enhancement',
        Status: 'Complete',
        Description: 'Implement service to handle content generation with AI'
      },
      {
        Name: 'Improve and formalize OpenAI prompt templates',
        Phase: 'Content Generation Enhancement',
        Status: 'In Progress',
        Description: 'Create standardized templates for OpenAI prompts'
      }
    ];
    
    // Create module records
    const records = await base('Modules').create(modules.map(module => ({ fields: module })));
    
    console.log(`Created ${records.length} module records.`);
    console.log('Modules setup complete.');
  } catch (error) {
    console.error('Error setting up modules:', error.message);
  }
}

// Run the script
setupModules();