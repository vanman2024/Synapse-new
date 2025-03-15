/**
 * Script to set up linked records between tables
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Create linked records
async function createLinkedRecords() {
  try {
    console.log('Setting up linked records between tables...');
    
    // Phase data with proper structure
    const phaseData = [
      { 
        number: 1,
        name: 'Foundation & Verification',
        status: 'Completed',
        description: 'Setting up the core foundation of the application'
      },
      { 
        number: 2,
        name: 'Content Generation Enhancement',
        status: 'Current',
        description: 'Enhancing content generation capabilities'
      },
      { 
        number: 3,
        name: 'User Management & Security',
        status: 'Planned',
        description: 'Implementing user authentication and security'
      }
    ];
    
    console.log('Creating phase records with linked structure...');
    
    // Create or update phase records
    const phaseMap = new Map(); // To store phase IDs by name
    
    // Get existing phase records
    const phaseRecords = await base('Phases').select().all();
    
    // Clear existing phase records
    if (phaseRecords.length > 0) {
      console.log(`Clearing ${phaseRecords.length} existing phase records...`);
      for (const record of phaseRecords) {
        await base('Phases').destroy(record.id);
      }
    }
    
    // Create new phase records
    for (const phase of phaseData) {
      try {
        const record = await base('Phases').create({
          Description: `${phase.name} - Phase ${phase.number}: ${phase.description} (${phase.status})`
        });
        
        phaseMap.set(phase.name, record.id);
        console.log(`Created phase: ${phase.name} (ID: ${record.id})`);
      } catch (error) {
        console.error(`Error creating phase ${phase.name}:`, error.message);
      }
    }
    
    // Get existing module records
    console.log('\nUpdating module records with phase links...');
    const moduleRecords = await base('Modules').select().all();
    
    // Update module records with phase links
    let updatedCount = 0;
    for (const record of moduleRecords) {
      const moduleName = record.fields['Module Name'];
      const description = record.fields['Description'] || '';
      
      // Try to detect the phase from the description
      let phaseToLink = null;
      for (const phaseName of phaseMap.keys()) {
        if (description.includes(phaseName)) {
          phaseToLink = phaseName;
          break;
        }
      }
      
      if (phaseToLink && phaseMap.has(phaseToLink)) {
        try {
          // Update the module with a link to the phase
          await base('Modules').update(record.id, {
            'Phase': [phaseMap.get(phaseToLink)]
          });
          
          updatedCount++;
          console.log(`Linked module "${moduleName}" to phase "${phaseToLink}"`);
        } catch (error) {
          console.error(`Error linking module "${moduleName}":`, error.message);
        }
      } else {
        console.log(`Could not determine phase for module "${moduleName}"`);
      }
    }
    
    console.log(`\nUpdated ${updatedCount} of ${moduleRecords.length} module records with phase links.`);
    console.log('Linked record setup complete.');
    
  } catch (error) {
    console.error('Error setting up linked records:', error);
  }
}

// Run the setup
createLinkedRecords();