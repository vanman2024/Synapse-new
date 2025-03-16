/**
 * Airtable integration for synergy.sh
 * This module provides functions for synergy.sh to integrate with Airtable
 */
const airtableClient = require('./airtable-client');

/**
 * Update module status in Airtable
 * @param {string} moduleName - Name of the module
 * @param {string} status - Status (complete, in-progress, planned)
 * @param {string} phaseName - Optional phase name to link
 * @returns {Promise<Object>} - Updated record
 */
async function updateModuleStatus(moduleName, status, phaseName = null) {
  try {
    console.log(`Updating module "${moduleName}" to status "${status}" in Airtable...`);
    
    // Find the module record
    const formula = `{Module Name} = "${moduleName}"`;
    const records = await airtableClient.findRecords('Modules', formula);
    
    if (records.length === 0) {
      console.error(`Module "${moduleName}" not found in Airtable.`);
      return null;
    }
    
    // Map synergy status to Airtable status
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
    
    // Prepare fields to update
    const updateFields = {
      'Status': airtableStatus
    };
    
    // If phase name provided, look up phase record and link it
    if (phaseName) {
      try {
        // Extract the main phase name from format like "Phase 2: Content Generation Enhancement (Current)"
        const simplePhaseName = phaseName.includes(':') ? 
          phaseName.split(':')[1].trim() : phaseName;
        
        // Look up by partial name match (using FIND function in formula)
        const phaseRecords = await airtableClient.findRecords('Phases', 
          `FIND("${simplePhaseName}", {Description}) > 0`);
        
        if (phaseRecords.length > 0) {
          // Set linked record field - must be an array of IDs
          updateFields['Phase'] = [phaseRecords[0].id];
          console.log(`Linked module to phase: ${simplePhaseName}`);
        } else {
          console.log(`Phase "${simplePhaseName}" not found for linking`);
        }
      } catch (error) {
        console.log(`Could not link to phase: ${error.message}`);
      }
    }
    
    // Update the record
    const recordId = records[0].id;
    const updatedRecord = await airtableClient.updateRecord('Modules', recordId, updateFields);
    
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
      'Date': session.date || new Date().toISOString().split('T')[0],
      'Branch': session.branch || '',
      'Status': session.status || 'Completed',
      'StartTime': session.startTime || '',
      'EndTime': session.endTime || '',
      'Summary': session.summary || '',
      'Commits': session.commits ? session.commits.join(', ') : '',
      'Notes': session.notes || ''
    };
    
    // If there's a related module, look up its ID and establish the link
    if (session.module) {
      try {
        console.log(`Looking up module: "${session.module}"`);
        
        // Try exact match first
        let moduleRecords = await airtableClient.findRecords('Modules', 
          `{Module Name} = "${session.module}"`);
          
        // If no exact match, try partial match
        if (moduleRecords.length === 0) {
          // Create a more flexible search pattern
          const moduleParts = session.module.split(' ');
          // If module has multiple words, search for records containing the first two words
          if (moduleParts.length > 1) {
            const searchPattern = moduleParts.slice(0, 2).join(' ');
            moduleRecords = await airtableClient.findRecords('Modules', 
              `FIND("${searchPattern}", {Module Name}) > 0`);
          }
        }
        
        if (moduleRecords.length > 0) {
          // Set linked record field for Focus - must be an array of IDs
          sessionRecord['Focus'] = [moduleRecords[0].id];
          console.log(`Linked session to module: ${moduleRecords[0].fields['Module Name']}`);
        } else {
          console.log(`No matching module found for "${session.module}"`);
        }
      } catch (error) {
        console.log(`Could not link to module: ${error.message}`);
      }
    }
    
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

/**
 * Update an existing session in Airtable
 * @param {string} sessionId - The Airtable record ID of the session
 * @param {Object} updateData - Data to update (status, endTime, summary, etc.)
 * @returns {Promise<Object>} - Updated record
 */
async function updateSession(sessionId, updateData) {
  try {
    console.log(`Updating session ${sessionId} in Airtable...`);
    
    // Prepare update object
    const updateObject = {};
    
    // Map standard fields directly
    if (updateData.status) updateObject['Status'] = updateData.status;
    if (updateData.endTime) updateObject['EndTime'] = updateData.endTime;
    if (updateData.summary) updateObject['Summary'] = updateData.summary;
    if (updateData.commits) updateObject['Commits'] = updateData.commits.join(', ');
    
    // If there's a module to link, look it up and create the link
    if (updateData.module) {
      try {
        console.log(`Looking up module: "${updateData.module}"`);
        
        // Try exact match first
        let moduleRecords = await airtableClient.findRecords('Modules', 
          `{Module Name} = "${updateData.module}"`);
          
        // If no exact match, try partial match
        if (moduleRecords.length === 0) {
          // Create a more flexible search pattern
          const moduleParts = updateData.module.split(' ');
          // If module has multiple words, search for records containing the first two words
          if (moduleParts.length > 1) {
            const searchPattern = moduleParts.slice(0, 2).join(' ');
            moduleRecords = await airtableClient.findRecords('Modules', 
              `FIND("${searchPattern}", {Module Name}) > 0`);
          }
        }
        
        if (moduleRecords.length > 0) {
          // Set linked record field for Focus - must be an array of IDs
          updateObject['Focus'] = [moduleRecords[0].id];
          console.log(`Linked session to module: ${moduleRecords[0].fields['Module Name']}`);
        } else {
          console.log(`No matching module found for "${updateData.module}"`);
        }
      } catch (error) {
        console.log(`Could not link to module: ${error.message}`);
      }
    }
    
    // Update the record
    const updatedRecord = await airtableClient.updateRecord('Sessions', sessionId, updateObject);
    
    console.log(`Session ${sessionId} updated successfully.`);
    return updatedRecord;
  } catch (error) {
    console.error('Error updating session in Airtable:', error);
    return null;
  }
}

/**
 * Get session information from Airtable
 * @param {string} sessionId - The Airtable record ID of the session
 * @returns {Promise<Object>} - Session data
 */
async function getSession(sessionId) {
  try {
    console.log(`Getting session ${sessionId} from Airtable...`);
    
    // Directly fetch the record by ID
    const record = await airtableClient.getTable('Sessions').find(sessionId);
    
    console.log(`Retrieved session ${sessionId}`);
    return record;
  } catch (error) {
    console.error('Error getting session from Airtable:', error);
    return null;
  }
}

/**
 * Get recent sessions from Airtable
 * @param {number} days - Number of days to look back (default: 7)
 * @returns {Promise<Array>} - List of recent sessions
 */
async function getRecentSessions(days = 7) {
  try {
    console.log(`Getting sessions from the last ${days} days...`);
    
    // Calculate the date for filtering
    const date = new Date();
    date.setDate(date.getDate() - days);
    const dateString = date.toISOString().split('T')[0];
    
    // Try to filter by date directly
    try {
      const sessions = await airtableClient.findRecords('Sessions', 
        `IS_AFTER({Date}, '${dateString}')`);
      return sessions;
    } catch (error) {
      // If the filter fails, fall back to getting all sessions and filtering in memory
      console.log(`Date filtering failed, fetching all sessions: ${error.message}`);
      const allSessions = await airtableClient.getAllRecords('Sessions');
      
      // Filter sessions in memory
      return allSessions.filter(session => {
        // If no Date field, include it for safety
        if (!session.fields.Date) return true;
        
        try {
          const sessionDate = new Date(session.fields.Date);
          return sessionDate >= date;
        } catch (e) {
          // If date parsing fails, include the session
          return true;
        }
      });
    }
  } catch (error) {
    console.error('Error getting recent sessions from Airtable:', error);
    return [];
  }
}

module.exports = {
  updateModuleStatus,
  logSession,
  getModuleInfo,
  getCurrentPhase,
  getPhaseModules,
  updateSession,
  getSession,
  getRecentSessions
};