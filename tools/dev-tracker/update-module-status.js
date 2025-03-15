/**
 * Script to update a module's status and phase
 * Usage: node update-module-status.js "Module Name" "Status" "Phase Name"
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Process command line arguments
const moduleName = process.argv[2];
const status = process.argv[3];
const phaseName = process.argv[4];

if (!moduleName || !status) {
  console.error('Usage: node update-module-status.js "Module Name" "Status" ["Phase Name"]');
  process.exit(1);
}

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Update module status
async function updateModule() {
  try {
    console.log(`Updating module "${moduleName}" to status "${status}"${phaseName ? ` and phase "${phaseName}"` : ''}...`);
    
    // Find the module record
    const moduleRecords = await base('Modules').select({
      filterByFormula: `{Module Name} = "${moduleName}"`
    }).firstPage();
    
    if (moduleRecords.length === 0) {
      console.error(`Module "${moduleName}" not found in Airtable.`);
      process.exit(1);
    }
    
    const moduleRecord = moduleRecords[0];
    
    // Map status to Airtable value
    let airtableStatus;
    switch (status.toLowerCase()) {
      case 'complete':
      case 'completed':
        airtableStatus = 'Completed';
        break;
      case 'in-progress':
      case 'in progress':
        airtableStatus = 'In Progress';
        break;
      case 'planned':
      case 'to do':
        airtableStatus = 'Planned';
        break;
      default:
        airtableStatus = status;
    }
    
    // Prepare update fields
    const updateFields = {
      'Status': airtableStatus
    };
    
    // If phase name provided, look up phase record and set link
    if (phaseName) {
      // Find the phase record
      const phaseRecords = await base('Phases').select({
        filterByFormula: `FIND("${phaseName}", {Description}) > 0`
      }).firstPage();
      
      if (phaseRecords.length > 0) {
        updateFields['Phase'] = [phaseRecords[0].id];
        console.log(`Linking to phase: ${phaseName}`);
      } else {
        console.log(`Phase "${phaseName}" not found.`);
      }
    }
    
    // Update the module
    const updatedRecord = await base('Modules').update(moduleRecord.id, updateFields);
    
    console.log(`Module "${moduleName}" successfully updated.`);
    process.exit(0);
    
  } catch (error) {
    console.error('Error updating module:', error.message);
    process.exit(1);
  }
}

// Run update
updateModule();