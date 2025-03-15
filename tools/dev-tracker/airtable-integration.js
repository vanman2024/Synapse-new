/**
 * Airtable integration for synergy.sh
 * This module provides functions for synergy.sh to integrate with Airtable
 */
const airtableClient = require('./airtable-client');

/**
 * Update module status in Airtable
 * @param {string} moduleName - Name of the module
 * @param {string} status - Status (complete, in-progress, planned)
 * @returns {Promise<Object>} - Updated record
 */
async function updateModuleStatus(moduleName, status) {
  try {
    console.log(`Updating module "${moduleName}" to status "${status}" in Airtable...`);
    
    // Find the module record
    const formula = `{Name} = "${moduleName}"`;
    const records = await airtableClient.findRecords('Modules', formula);
    
    if (records.length === 0) {
      console.error(`Module "${moduleName}" not found in Airtable.`);
      return null;
    }
    
    // Map synergy status to Airtable status
    let airtableStatus;
    switch (status) {
      case 'complete':
        airtableStatus = 'Completed';
        break;
      case 'in-progress':
        airtableStatus = 'In Progress';
        break;
      case 'planned':
        airtableStatus = 'Planned';
        break;
      default:
        airtableStatus = status;
    }
    
    // Update the record
    const recordId = records[0].id;
    const updatedRecord = await airtableClient.updateRecord('Modules', recordId, {
      'Status': airtableStatus,
      'Last Updated': new Date().toISOString()
    });
    
    console.log(`Module "${moduleName}" updated to "${airtableStatus}" in Airtable.`);
    return updatedRecord;
  } catch (error) {
    console.error(`Error updating module status in Airtable:`, error);
    return null;
  }
}

/**
 * Log a session in Airtable
 * @param {Object} session - Session data
 * @returns {Promise<Object>} - Created record
 */
async function logSession(session) {
  try {
    console.log('Logging session in Airtable...');
    
    // Prepare session record
    const sessionRecord = {
      'Date': session.date || new Date().toISOString(),
      'Branch': session.branch || '',
      'Focus': session.focus || '',
      'Status': session.status || 'Completed',
      'Start Time': session.startTime || '',
      'End Time': session.endTime || '',
      'Summary': session.summary || '',
      'Commits': JSON.stringify(session.commits || [])
    };
    
    // Create the record
    const record = await airtableClient.createRecord('Sessions', sessionRecord);
    
    console.log('Session logged in Airtable.');
    return record;
  } catch (error) {
    console.error('Error logging session in Airtable:', error);
    return null;
  }
}

/**
 * Get module information from Airtable
 * @param {string} moduleName - Name of the module
 * @returns {Promise<Object>} - Module info
 */
async function getModuleInfo(moduleName) {
  try {
    console.log(`Getting info for module "${moduleName}" from Airtable...`);
    
    // Find the module record
    const formula = `{Name} = "${moduleName}"`;
    const records = await airtableClient.findRecords('Modules', formula);
    
    if (records.length === 0) {
      console.error(`Module "${moduleName}" not found in Airtable.`);
      return null;
    }
    
    // Return the record fields
    return records[0].fields;
  } catch (error) {
    console.error(`Error getting module info from Airtable:`, error);
    return null;
  }
}

/**
 * Get current phase from Airtable
 * @returns {Promise<Object>} - Current phase info
 */
async function getCurrentPhase() {
  try {
    console.log('Getting current phase from Airtable...');
    
    // Find the current phase
    const formula = `{Status} = "Current"`;
    const records = await airtableClient.findRecords('Phases', formula);
    
    if (records.length === 0) {
      console.error('No current phase found in Airtable.');
      return null;
    }
    
    // Return the record fields
    return records[0].fields;
  } catch (error) {
    console.error('Error getting current phase from Airtable:', error);
    return null;
  }
}

/**
 * Get all modules for a phase from Airtable
 * @param {number} phaseNumber - Phase number
 * @returns {Promise<Array>} - List of modules
 */
async function getPhaseModules(phaseNumber) {
  try {
    console.log(`Getting modules for phase ${phaseNumber} from Airtable...`);
    
    // Find modules for the phase
    const formula = `{Phase Number} = ${phaseNumber}`;
    const records = await airtableClient.findRecords('Modules', formula);
    
    // Return the records
    return records.map(record => record.fields);
  } catch (error) {
    console.error(`Error getting phase modules from Airtable:`, error);
    return [];
  }
}

module.exports = {
  updateModuleStatus,
  logSession,
  getModuleInfo,
  getCurrentPhase,
  getPhaseModules
};