/**
 * Script to add a Phase Number field to Phases table by extracting from Description
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Extract phase number from description and add it as a separate field
async function addPhaseNumberField() {
  try {
    console.log('Adding Phase Number field to Phase records...');
    
    // Get all phases
    const phases = await base('Phases').select().all();
    
    console.log(`Found ${phases.length} phases to update:`);
    for (const phase of phases) {
      // Extract phase number using regex
      // Example: "Foundation & Verification - Phase 1: Setting up the core foundation..."
      const description = phase.fields.Description || '';
      const numberMatch = description.match(/Phase\s+(\d+)/i);
      
      if (numberMatch && numberMatch[1]) {
        const phaseNumber = parseInt(numberMatch[1], 10);
        
        // Update the phase with the extracted number
        await base('Phases').update(phase.id, {
          'Phase Number': phaseNumber
        });
        
        console.log(`Updated phase ${phase.id} with number: ${phaseNumber}`);
      } else {
        console.log(`Could not extract number from description: "${description}"`);
      }
    }
    
    console.log('\nPhase numbers added!');
    console.log('Now you can use the Phase Number field for sorting and filtering.');
    console.log('You might also want to set up a formula field in the Modules table that looks up the Phase Number from linked Phase records.');
    
  } catch (error) {
    console.error('Error adding phase numbers:', error);
  }
}

// Run the update
addPhaseNumberField();