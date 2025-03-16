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
    
    // Find the module record using our improved helper function
    const moduleRecord = await findModuleByName(moduleName);
    
    if (!moduleRecord) {
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
        let phaseNameToSearch = phaseName;
        if (phaseName.includes(':')) {
          phaseNameToSearch = phaseName.split(':')[1].trim();
        }
        
        // First try to search by Phase Name
        let phaseRecords = [];
        try {
          phaseRecords = await airtableClient.findRecords('Phases', 
            `{Phase Name} = "${phaseNameToSearch}"`);
        } catch (error) {
          console.log(`Error searching by Phase Name: ${error.message}`);
        }
        
        // If no results, try partial match on Phase Name
        if (phaseRecords.length === 0) {
          try {
            phaseRecords = await airtableClient.findRecords('Phases', 
              `FIND("${phaseNameToSearch}", {Phase Name}) > 0`);
          } catch (error) {
            console.log(`Error searching by Phase Name partial match: ${error.message}`);
          }
        }
        
        // If still no results, try partial match on Description
        if (phaseRecords.length === 0) {
          try {
            phaseRecords = await airtableClient.findRecords('Phases', 
              `FIND("${phaseNameToSearch}", {Description}) > 0`);
          } catch (error) {
            console.log(`Error searching by Description partial match: ${error.message}`);
          }
        }
        
        // Last resort - get all phases and search in memory
        if (phaseRecords.length === 0) {
          console.log('Fetching all phases for in-memory search...');
          const allPhases = await airtableClient.getAllRecords('Phases');
          
          for (const record of allPhases) {
            const phaseName = record.fields['Phase Name'] || '';
            const description = record.fields['Description'] || '';
            
            if (phaseName.includes(phaseNameToSearch) || 
                description.includes(phaseNameToSearch)) {
              phaseRecords = [record];
              break;
            }
          }
        }
        
        if (phaseRecords.length > 0) {
          // Set linked record field - must be an array of IDs
          updateFields['Phase'] = [phaseRecords[0].id];
          console.log(`Linked module to phase: ${phaseRecords[0].fields['Phase Name'] || phaseName}`);
        } else {
          console.log(`Phase "${phaseName}" not found for linking`);
        }
      } catch (error) {
        console.log(`Could not link to phase: ${error.message}`);
      }
    }
    
    // Update the record
    const recordId = moduleRecord.id;
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
      'Branch': session.branch || '',
      'Status': session.status || 'Completed',
      'Summary': session.summary || '',
      'Commits': session.commits ? session.commits.join(', ') : '',
      'Notes': session.notes || session.summary || '',
      'BranchContext': session.branchContext || ''
    };
    
    // Add Git commit hashes
    if (session.startCommit) {
      sessionRecord['StartCommit'] = session.startCommit;
    } else if (session.startTime) {
      // For backward compatibility, if startCommit isn't provided but startTime is
      sessionRecord['StartCommit'] = session.startTime;
    }
    
    if (session.endCommit) {
      sessionRecord['EndCommit'] = session.endCommit;
    } else if (session.endTime) {
      // For backward compatibility, if endCommit isn't provided but endTime is
      sessionRecord['EndCommit'] = session.endTime;
    }
    
    // If there's a related module, look up its ID and establish the link
    if (session.module) {
      try {
        console.log(`Looking up module: "${session.module}"`);
        
        // Use our improved helper function to find the module
        const moduleRecord = await findModuleByName(session.module);
        
        if (moduleRecord) {
          // Set linked record field for Focus - must be an array of IDs
          sessionRecord['Focus'] = [moduleRecord.id];
          console.log(`Linked session to module: ${moduleRecord.fields['Module Name']}`);
        } else {
          console.log(`No matching module found for "${session.module}"`);
        }
      } catch (error) {
        console.log(`Could not link to module: ${error.message}`);
      }
    }
    
    // If there are components to link, look them up and create the links
    if (session.components && session.components.length > 0) {
      try {
        console.log(`Looking up components: ${session.components.join(', ')}`);
        
        const componentIds = [];
        
        // For each component, find its record in Airtable
        for (const componentName of session.components) {
          if (!componentName) continue;
          
          const componentRecords = await airtableClient.findRecords('ComponentRegistry', 
            `{Name} = "${componentName}"`);
            
          if (componentRecords.length > 0) {
            componentIds.push(componentRecords[0].id);
            console.log(`Found component: ${componentName}`);
          } else {
            console.log(`Component not found: ${componentName}`);
          }
        }
        
        if (componentIds.length > 0) {
          // Set linked record field for Components - must be an array of IDs
          sessionRecord['Components'] = componentIds;
          console.log(`Linked session to ${componentIds.length} components`);
        }
      } catch (error) {
        console.log(`Could not link to components: ${error.message}`);
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
    
    // Use our improved findModuleByName function to get the module record
    const moduleRecord = await findModuleByName(moduleName);
    
    if (moduleRecord) {
      console.log(`Found module "${moduleRecord.fields['Module Name']}"`);
      return moduleRecord.fields;
    }
    
    console.error(`Module "${moduleName}" not found in Airtable.`);
    return null;
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
    
    // Based on list-fields.js, we know the actual field names in Phases table:
    // - Description
    // - Modules
    // - Phase Name
    // - Phase Number
    
    // Get all phases and look for the lowest Phase Number
    // which usually indicates the current phase
    const allPhases = await airtableClient.getAllRecords('Phases');
    
    if (allPhases.length === 0) {
      console.error('No phases found in Airtable.');
      return null;
    }
    
    // Sort phases by Phase Number and get the first one
    allPhases.sort((a, b) => {
      const aNum = a.fields['Phase Number'] || 999;
      const bNum = b.fields['Phase Number'] || 999;
      return aNum - bNum;
    });
    
    console.log(`Found current phase: ${allPhases[0].fields['Phase Name'] || 'Unknown'}`);
    return allPhases[0].fields;
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
    
    // First, try to get the phase record
    let phaseRecord = null;
    try {
      const phases = await airtableClient.findRecords('Phases', 
        `{Phase Number} = ${phaseNumber}`);
      
      if (phases.length > 0) {
        phaseRecord = phases[0];
      }
    } catch (error) {
      console.log(`Error finding phase by number: ${error.message}`);
    }
    
    if (!phaseRecord) {
      console.log(`Phase ${phaseNumber} not found, getting all modules instead`);
      const allModules = await airtableClient.getAllRecords('Modules');
      return allModules.map(record => record.fields);
    }
    
    // Check if the phase has linked modules
    if (phaseRecord.fields.Modules && 
        Array.isArray(phaseRecord.fields.Modules) && 
        phaseRecord.fields.Modules.length > 0) {
      
      console.log(`Found ${phaseRecord.fields.Modules.length} linked modules for phase ${phaseNumber}`);
      
      // Get all modules that are linked to this phase
      const linkedModules = [];
      
      for (const moduleId of phaseRecord.fields.Modules) {
        try {
          const module = await airtableClient.getTable('Modules').find(moduleId);
          linkedModules.push(module);
        } catch (error) {
          console.log(`Error fetching linked module ${moduleId}: ${error.message}`);
        }
      }
      
      return linkedModules.map(record => record.fields);
    }
    
    // If there are no linked modules, try to find by Phase field
    try {
      // Get all modules
      const allModules = await airtableClient.getAllRecords('Modules');
      
      // Filter modules by phase
      const phaseModules = allModules.filter(module => {
        if (!module.fields.Phase || !Array.isArray(module.fields.Phase)) {
          return false;
        }
        
        // Check if any of the linked phases match our phase
        return module.fields.Phase.includes(phaseRecord.id);
      });
      
      console.log(`Found ${phaseModules.length} modules for phase ${phaseNumber} via Phase field`);
      return phaseModules.map(record => record.fields);
    } catch (error) {
      console.log(`Error finding modules by Phase field: ${error.message}`);
    }
    
    console.log(`No modules found for phase ${phaseNumber}, returning all modules`);
    const allModules = await airtableClient.getAllRecords('Modules');
    return allModules.map(record => record.fields);
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
    if (updateData.summary) updateObject['Summary'] = updateData.summary;
    if (updateData.commits) updateObject['Commits'] = updateData.commits.join(', ');
    
    // Add Git context fields
    if (updateData.branchContext) updateObject['BranchContext'] = updateData.branchContext;
    
    // Handle commit hashes
    if (updateData.endCommit) {
      updateObject['EndCommit'] = updateData.endCommit;
    } else if (updateData.endTime) {
      // For backward compatibility
      updateObject['EndCommit'] = updateData.endTime;
    }
    
    // If there's a module to link, look it up and create the link
    if (updateData.module) {
      try {
        console.log(`Looking up module: "${updateData.module}"`);
        
        // Use our improved helper function to find the module
        const moduleRecord = await findModuleByName(updateData.module);
        
        if (moduleRecord) {
          // Set linked record field for Focus - must be an array of IDs
          updateObject['Focus'] = [moduleRecord.id];
          console.log(`Linked session to module: ${moduleRecord.fields['Module Name']}`);
        } else {
          console.log(`No matching module found for "${updateData.module}"`);
        }
      } catch (error) {
        console.log(`Could not link to module: ${error.message}`);
      }
    }
    
    // If there are components to link, look them up and create the links
    if (updateData.components && updateData.components.length > 0) {
      try {
        console.log(`Looking up components: ${updateData.components.join(', ')}`);
        
        const componentIds = [];
        
        // For each component, find its record in Airtable
        for (const componentName of updateData.components) {
          if (!componentName) continue;
          
          const componentRecords = await airtableClient.findRecords('ComponentRegistry', 
            `{Name} = "${componentName}"`);
            
          if (componentRecords.length > 0) {
            componentIds.push(componentRecords[0].id);
            console.log(`Found component: ${componentName}`);
          } else {
            console.log(`Component not found: ${componentName}`);
          }
        }
        
        if (componentIds.length > 0) {
          // Set linked record field for Components - must be an array of IDs
          updateObject['Components'] = componentIds;
          console.log(`Linked session to ${componentIds.length} components`);
        }
      } catch (error) {
        console.log(`Could not link to components: ${error.message}`);
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

/**
 * Find a module by name
 * @param {string} moduleName - Name of the module to find
 * @returns {Promise<Object>} - The module record
 */
async function findModuleByName(moduleName) {
  try {
    console.log(`Finding module: ${moduleName}`);
    
    // Based on list-fields.js, we know the actual field in Modules table:
    // - Module Name (this is correct, so try the exact match first)
    
    try {
      // Try exact match with Module Name field
      const records = await airtableClient.findRecords('Modules', 
        `{Module Name} = "${moduleName}"`);
        
      if (records.length > 0) {
        console.log(`Found exact match for module: ${moduleName}`);
        return records[0];
      }
    } catch (error) {
      console.log(`Exact match error: ${error.message}`);
    }
    
    // Try partial match with Module Name field
    try {
      // Create a simplified search pattern (first word or two)
      const moduleParts = moduleName.split(' ');
      if (moduleParts.length > 1) {
        const searchPattern = moduleParts.slice(0, 2).join(' ');
        
        // Use FIND to search for the pattern within the field value
        const formula = `FIND("${searchPattern}", {Module Name}) > 0`;
        console.log(`Trying partial match with formula: ${formula}`);
        
        const partialRecords = await airtableClient.findRecords('Modules', formula);
          
        if (partialRecords.length > 0) {
          console.log(`Found partial match for module: ${moduleName} -> ${partialRecords[0].fields['Module Name']}`);
          return partialRecords[0];
        }
      }
    } catch (error) {
      console.log(`Partial match error: ${error.message}`);
    }
    
    // If the above doesn't work, get all modules and filter in memory
    console.log('Fetching all modules for in-memory search...');
    const allModules = await airtableClient.getAllRecords('Modules');
    
    // Loop through all modules and look for partial matches
    for (const record of allModules) {
      const name = record.fields['Module Name'] || '';
      if (name && (
        name.toLowerCase().includes(moduleName.toLowerCase()) || 
        moduleName.toLowerCase().includes(name.toLowerCase())
      )) {
        console.log(`Found in-memory match: ${name}`);
        return record;
      }
    }
    
    console.log(`No matching module found for: ${moduleName}`);
    return null;
  } catch (error) {
    console.error(`Error finding module by name: ${error}`);
    return null;
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
  getRecentSessions,
  findModuleByName
};