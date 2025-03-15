/**
 * Script to add a Name field to Phases table by extracting from Description
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Extract phase name from description and add it as a separate field
async function addPhaseNameField() {
  try {
    console.log('Adding Name field to Phase records...');
    
    // Get all phases
    const phases = await base('Phases').select().all();
    
    console.log(`Found ${phases.length} phases to update:`);
    for (const phase of phases) {
      // Extract phase name using regex
      // Example: "Foundation & Verification - Phase 1: Setting up the core foundation..."
      const description = phase.fields.Description || '';
      const nameMatch = description.match(/^([^-]+)/);
      
      if (nameMatch && nameMatch[1]) {
        const phaseName = nameMatch[1].trim();
        
        // Update the phase with the extracted name
        await base('Phases').update(phase.id, {
          'Phase Name': phaseName
        });
        
        console.log(`Updated phase ${phase.id} with name: "${phaseName}"`);
      } else {
        console.log(`Could not extract name from description: "${description}"`);
      }
    }
    
    console.log('\nPhase names added!');
    console.log('Next steps:');
    console.log('1. Go to Airtable UI > Phases table');
    console.log('2. Click on "Customize fields"');
    console.log('3. Set "Phase Name" as the primary field');
    console.log('4. Refresh your views to see the updated linked record names');
    
  } catch (error) {
    console.error('Error adding phase names:', error);
  }
}

// Run the update
addPhaseNameField();