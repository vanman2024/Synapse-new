/**
 * Script to check phase records
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Check phase records
async function checkPhases() {
  try {
    console.log('Checking Phase records...');
    
    // Get all phases
    const phases = await base('Phases').select().all();
    
    console.log(`Found ${phases.length} phases:`);
    phases.forEach(phase => {
      console.log(`ID: ${phase.id}`);
      console.log(`Fields: ${JSON.stringify(phase.fields, null, 2)}`);
      console.log('---');
    });
    
    // Check linked records in Modules
    console.log('\nChecking linked records in Modules table...');
    const modules = await base('Modules').select({
      fields: ['Module Name', 'Phase']
    }).all();
    
    console.log(`\nModules with phase links (${modules.filter(m => m.fields.Phase && m.fields.Phase.length > 0).length}/${modules.length}):`);
    modules.forEach(module => {
      if (module.fields.Phase && module.fields.Phase.length > 0) {
        console.log(`Module: "${module.fields['Module Name']}"`);
        console.log(`Phase IDs: ${JSON.stringify(module.fields.Phase)}`);
      }
    });
    
    console.log('\nNote: If phases appear as "Unnamed record" in Airtable, you need to:');
    console.log('1. Go to Airtable UI > Phases table');
    console.log('2. Click on "Customize fields"');
    console.log('3. Add a name field (if missing) and set it as the primary field');
    console.log('4. If that\'s not possible, create a formula field that extracts the phase name from Description');
  } catch (error) {
    console.error('Error checking phases:', error);
  }
}

// Run the check
checkPhases();