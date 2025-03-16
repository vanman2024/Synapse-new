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
 * Format date for Airtable
 * @param {Date|string} date - Date to format
 * @returns {string} - Formatted date string
 */
function formatDate(date) {
  if (!date) return '';
  
  const d = typeof date === 'string' ? new Date(date) : date;
  
  // If invalid date, return empty string
  if (isNaN(d.getTime())) return '';
  
  // Format as ISO string (YYYY-MM-DD)
  return d.toISOString().split('T')[0];
}

/**
 * Format time for Airtable
 * @param {Date|string} date - Date to format
 * @returns {string} - Formatted time string (HH:MM)
 */
function formatTime(date) {
  if (!date) return '';
  
  const d = typeof date === 'string' ? new Date(date) : date;
  
  // If invalid date, return empty string
  if (isNaN(d.getTime())) return '';
  
  // Format as HH:MM
  return d.toTimeString().split(' ')[0].substring(0, 5);
}

/**
 * Log a session in Airtable
 * @param {Object} session - Session data
 * @returns {Promise<Object>} - Created record
 */
async function logSession(session) {
  try {
    console.log('Logging session in Airtable...');
    
    // Get current date/time if not provided
    const now = new Date();
    const sessionDate = session.date ? new Date(session.date) : now;
    
    // Prepare session record
    const sessionRecord = {
      'Branch': session.branch || '',
      'Status': session.status || 'Active',
      'Summary': session.summary || '',
      'Commits': session.commits ? session.commits.join(', ') : '',
      'Notes': session.notes || session.summary || '',
      'BranchContext': session.branchContext || '',
      'Date Created': sessionDate.toISOString()
    };
    
    // Add properly formatted date (required field)
    sessionRecord['Date'] = formatDate(sessionDate);
    
    // Add start and end times
    if (session.startTime) {
      const startTime = typeof session.startTime === 'string' 
        ? session.startTime 
        : formatTime(session.startTime);
      sessionRecord['StartDate'] = startTime;
    }
    
    if (session.endTime) {
      const endTime = typeof session.endTime === 'string'
        ? session.endTime
        : formatTime(session.endTime);
      sessionRecord['EndDate'] = endTime;
    }
    
    // Add Git commit hashes
    if (session.startCommit) {
      sessionRecord['StartCommit'] = session.startCommit;
    }
    
    // Temporarily disable EndCommit until the field is added to Airtable
    /*if (session.endCommit) {
      sessionRecord['EndCommit'] = session.endCommit;
    }*/
    
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
          
          // If module doesn't have "In Progress" status, update it
          if (moduleRecord.fields.Status !== 'In Progress') {
            console.log(`Updating module status to "In Progress"`);
            await airtableClient.updateRecord('Modules', moduleRecord.id, {
              'Status': 'In Progress'
            });
          }
          
          // Also update the session summary if it's generic
          if (!session.summary || session.summary.includes('Development Tasks')) {
            const moduleName = moduleRecord.fields['Module Name'];
            sessionRecord['Summary'] = `Working on module: ${moduleName}`;
            console.log(`Updated session summary with module name`);
          }
        } else {
          console.log(`No matching module found for "${session.module}"`);
          
          // If no module found but we should be working on something,
          // try to find the next module to work on
          try {
            const nextModule = await getNextModuleToWorkOn();
            if (nextModule) {
              console.log(`Suggesting next module to work on: ${nextModule.fields['Module Name']}`);
              sessionRecord['Focus'] = [nextModule.id];
              sessionRecord['Summary'] = `Working on module: ${nextModule.fields['Module Name']}`;
              
              // Also update module status
              if (nextModule.fields.Status !== 'In Progress') {
                await airtableClient.updateRecord('Modules', nextModule.id, {
                  'Status': 'In Progress'
                });
                console.log(`Updated module status to "In Progress"`);
              }
            }
          } catch (nextModuleError) {
            console.log(`Error finding next module: ${nextModuleError.message}`);
          }
        }
      } catch (error) {
        console.log(`Could not link to module: ${error.message}`);
      }
    } else {
      // No module specified - try to find the next one to work on
      try {
        const nextModule = await getNextModuleToWorkOn();
        if (nextModule) {
          console.log(`No module specified, suggesting next module: ${nextModule.fields['Module Name']}`);
          sessionRecord['Focus'] = [nextModule.id];
          sessionRecord['Summary'] = `Working on module: ${nextModule.fields['Module Name']}`;
          
          // Also update module status
          if (nextModule.fields.Status !== 'In Progress') {
            await airtableClient.updateRecord('Modules', nextModule.id, {
              'Status': 'In Progress'
            });
            console.log(`Updated module status to "In Progress"`);
          }
        }
      } catch (nextModuleError) {
        console.log(`Error finding next module: ${nextModuleError.message}`);
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
 * Get all phases from Airtable
 * @returns {Promise<Array>} - Array of phase records
 */
async function getAllPhases() {
  try {
    console.log('Getting all phases from Airtable...');
    
    // Get all phases
    const allPhases = await airtableClient.getAllRecords('Phases');
    
    if (allPhases.length === 0) {
      console.error('No phases found in Airtable.');
      return [];
    }
    
    // Sort phases by Phase Number
    allPhases.sort((a, b) => {
      const aNum = a.fields['Phase Number'] || 999;
      const bNum = b.fields['Phase Number'] || 999;
      return aNum - bNum;
    });
    
    console.log(`Found ${allPhases.length} phases`);
    return allPhases;
  } catch (error) {
    console.error('Error getting phases from Airtable:', error);
    return [];
  }
}

/**
 * Get current phase from Airtable
 * @returns {Promise<Object>} - Current phase info
 */
async function getCurrentPhase() {
  try {
    console.log('Getting current phase from Airtable...');
    
    // Try to find a phase with explicit "Current" status first
    try {
      const currentPhases = await airtableClient.findRecords('Phases', '{Status} = "Current"');
      if (currentPhases && currentPhases.length > 0) {
        console.log(`Found current phase by status: ${currentPhases[0].fields['Phase Name'] || 'Unknown'}`);
        return {
          record: currentPhases[0],
          fields: currentPhases[0].fields
        };
      }
    } catch (error) {
      console.log('No phases with Current status found, checking for In Progress status...');
    }
    
    // Try looking for "In Progress" status
    try {
      const inProgressPhases = await airtableClient.findRecords('Phases', '{Status} = "In Progress"');
      if (inProgressPhases && inProgressPhases.length > 0) {
        console.log(`Found in-progress phase: ${inProgressPhases[0].fields['Phase Name'] || 'Unknown'}`);
        return {
          record: inProgressPhases[0],
          fields: inProgressPhases[0].fields
        };
      }
    } catch (error) {
      console.log('No phases with In Progress status, using phase order...');
    }
    
    // If no explicit current phase, get all phases and determine current by completion
    const allPhases = await getAllPhases();
    
    if (allPhases.length === 0) {
      return null;
    }
    
    // Check each phase in order to find the earliest incomplete one
    for (const phase of allPhases) {
      // Skip phases marked as completed
      if (phase.fields.Status === 'Completed') {
        continue;
      }
      
      // If we find a non-completed phase, that's our current one
      console.log(`Selected current phase based on completion: ${phase.fields['Phase Name'] || 'Unknown'}`);
      return {
        record: phase,
        fields: phase.fields
      };
    }
    
    // If all phases are completed, return the last one
    const lastPhase = allPhases[allPhases.length - 1];
    console.log(`All phases complete, returning last phase: ${lastPhase.fields['Phase Name'] || 'Unknown'}`);
    return {
      record: lastPhase,
      fields: lastPhase.fields
    };
  } catch (error) {
    console.error('Error getting current phase from Airtable:', error);
    return null;
  }
}

/**
 * Get all modules for a phase from Airtable
 * @param {string|Object} phase - Phase number, ID, or record object
 * @param {string} [statusFilter] - Optional status to filter modules by
 * @returns {Promise<Array>} - List of module records
 */
async function getPhaseModules(phase, statusFilter = null) {
  try {
    // Handle different phase input types
    let phaseRecord = null;
    let phaseNumber = null;
    
    if (typeof phase === 'object' && phase !== null) {
      // If a phase record object was passed directly
      phaseRecord = phase.record || phase;
      phaseNumber = phaseRecord.fields['Phase Number'];
      console.log(`Getting modules for phase "${phaseRecord.fields['Phase Name']}" (${phaseNumber}) from Airtable...`);
    } else {
      // If a phase number or ID was passed
      phaseNumber = typeof phase === 'string' ? parseInt(phase, 10) : phase;
      if (isNaN(phaseNumber)) {
        // Treat as phase ID
        try {
          phaseRecord = await airtableClient.getTable('Phases').find(phase);
          phaseNumber = phaseRecord?.fields['Phase Number'];
        } catch (error) {
          console.log(`Error finding phase by ID: ${error.message}`);
        }
      } else {
        // Find by phase number
        try {
          const phases = await airtableClient.findRecords('Phases', 
            `{Phase Number} = ${phaseNumber}`);
            
          if (phases.length > 0) {
            phaseRecord = phases[0];
          }
        } catch (error) {
          console.log(`Error finding phase by number: ${error.message}`);
        }
      }
      
      console.log(`Getting modules for phase ${phaseNumber} from Airtable...`);
    }
    
    if (!phaseRecord) {
      console.log(`Phase ${phaseNumber} not found, getting all modules instead`);
      const allModules = await airtableClient.getAllRecords('Modules');
      console.log(`Found ${allModules.length} total modules`);
      
      if (statusFilter) {
        const filteredModules = allModules.filter(
          m => m.fields.Status === statusFilter
        );
        console.log(`Filtered to ${filteredModules.length} modules with status "${statusFilter}"`);
        return filteredModules;
      }
      
      return allModules;
    }
    
    // Start with an empty array of module records
    let moduleRecords = [];
    
    // Method 1: Check if the phase has linked modules
    if (phaseRecord.fields.Modules && 
        Array.isArray(phaseRecord.fields.Modules) && 
        phaseRecord.fields.Modules.length > 0) {
      
      console.log(`Found ${phaseRecord.fields.Modules.length} linked modules for phase ${phaseNumber}`);
      
      // Get all modules that are linked to this phase
      for (const moduleId of phaseRecord.fields.Modules) {
        try {
          const module = await airtableClient.getTable('Modules').find(moduleId);
          if (module) {
            moduleRecords.push(module);
          }
        } catch (error) {
          console.log(`Error fetching linked module ${moduleId}: ${error.message}`);
        }
      }
    }
    
    // Method 2: If few or no linked modules found, try to find by Phase field
    if (moduleRecords.length === 0) {
      try {
        // Get all modules
        const allModules = await airtableClient.getAllRecords('Modules');
        console.log(`Checking all ${allModules.length} modules for phase links`);
        
        // Filter modules by phase
        moduleRecords = allModules.filter(module => {
          if (!module.fields.Phase || !Array.isArray(module.fields.Phase)) {
            return false;
          }
          
          // Check if any of the linked phases match our phase
          return module.fields.Phase.includes(phaseRecord.id);
        });
        
        console.log(`Found ${moduleRecords.length} modules for phase ${phaseNumber} via Phase field`);
      } catch (error) {
        console.log(`Error finding modules by Phase field: ${error.message}`);
      }
    }
    
    // Method 3: If still no modules found, fallback to text search in Description
    if (moduleRecords.length === 0) {
      try {
        const allModules = await airtableClient.getAllRecords('Modules');
        
        // Filter by phase in the description field (many descriptions contain phase names)
        const phaseName = phaseRecord.fields['Phase Name'] || '';
        moduleRecords = allModules.filter(module => {
          const description = module.fields.Description || '';
          return description.includes(phaseName);
        });
        
        console.log(`Found ${moduleRecords.length} modules for phase ${phaseNumber} via description text search`);
      } catch (error) {
        console.log(`Error finding modules by description: ${error.message}`);
      }
    }
    
    // Fallback: If still no modules, get all
    if (moduleRecords.length === 0) {
      console.log(`No modules found for phase ${phaseNumber}, returning all modules`);
      moduleRecords = await airtableClient.getAllRecords('Modules');
    }
    
    // De-duplicate modules by ID (in case we have duplicates)
    const uniqueModules = [];
    const seenIds = new Set();
    
    for (const module of moduleRecords) {
      if (!seenIds.has(module.id)) {
        uniqueModules.push(module);
        seenIds.add(module.id);
      }
    }
    
    console.log(`Found ${uniqueModules.length} unique modules for phase ${phaseNumber}`);
    
    // Apply status filter if requested
    if (statusFilter) {
      const filteredModules = uniqueModules.filter(
        m => m.fields.Status === statusFilter
      );
      console.log(`Filtered to ${filteredModules.length} modules with status "${statusFilter}"`);
      return filteredModules;
    }
    
    return uniqueModules;
  } catch (error) {
    console.error(`Error getting phase modules from Airtable:`, error);
    return [];
  }
}

/**
 * Get next module to work on based on current phase and module status
 * @returns {Promise<Object>} Module record to work on
 */
async function getNextModuleToWorkOn() {
  try {
    console.log('Finding next module to work on...');
    
    // 1. Get the current phase
    const currentPhase = await getCurrentPhase();
    if (!currentPhase) {
      throw new Error('Could not determine current phase');
    }
    
    console.log(`Current phase: ${currentPhase.fields['Phase Name'] || 'Unknown'}`);
    
    // 2. First check for any "In Progress" modules in this phase
    const inProgressModules = await getPhaseModules(currentPhase, 'In Progress');
    
    if (inProgressModules.length > 0) {
      console.log(`Found ${inProgressModules.length} in-progress modules in current phase`);
      
      // Return the first in-progress module
      return inProgressModules[0];
    }
    
    // 3. If no in-progress modules, look for "Planned" modules
    const plannedModules = await getPhaseModules(currentPhase, 'Planned');
    
    if (plannedModules.length > 0) {
      console.log(`Found ${plannedModules.length} planned modules in current phase`);
      
      // Return the first planned module
      return plannedModules[0];
    }
    
    // 4. If no planned modules, check all modules without a status
    const allModules = await getPhaseModules(currentPhase);
    const modulesWithoutStatus = allModules.filter(m => !m.fields.Status);
    
    if (modulesWithoutStatus.length > 0) {
      console.log(`Found ${modulesWithoutStatus.length} modules without a status in current phase`);
      
      // Return the first module without a status
      return modulesWithoutStatus[0];
    }
    
    // 5. If all modules have a status, check the next phase
    console.log('No incomplete modules in current phase, checking next phase...');
    
    const allPhases = await getAllPhases();
    const currentPhaseIndex = allPhases.findIndex(p => p.id === currentPhase.record.id);
    
    if (currentPhaseIndex >= 0 && currentPhaseIndex < allPhases.length - 1) {
      const nextPhase = allPhases[currentPhaseIndex + 1];
      
      console.log(`Checking next phase: ${nextPhase.fields['Phase Name'] || 'Unknown'}`);
      
      // Check for planned modules in the next phase
      const nextPhaseModules = await getPhaseModules(nextPhase, 'Planned');
      
      if (nextPhaseModules.length > 0) {
        console.log(`Found ${nextPhaseModules.length} planned modules in next phase`);
        
        // Return the first planned module from the next phase
        return nextPhaseModules[0];
      }
      
      // Check for modules without status in the next phase
      const allNextPhaseModules = await getPhaseModules(nextPhase);
      const nextPhaseModulesWithoutStatus = allNextPhaseModules.filter(m => !m.fields.Status);
      
      if (nextPhaseModulesWithoutStatus.length > 0) {
        console.log(`Found ${nextPhaseModulesWithoutStatus.length} modules without a status in next phase`);
        
        // Return the first module without a status from the next phase
        return nextPhaseModulesWithoutStatus[0];
      }
    }
    
    // 6. If we still couldn't find anything, return the most recently updated module
    console.log('No incomplete modules found, getting most recently updated module...');
    
    const allRecords = await airtableClient.getAllRecords('Modules');
    
    if (allRecords.length === 0) {
      throw new Error('No modules found in Airtable');
    }
    
    // Sort by last modified date
    allRecords.sort((a, b) => {
      const aDate = new Date(a.fields['Last Modified'] || a.fields['Created'] || 0);
      const bDate = new Date(b.fields['Last Modified'] || b.fields['Created'] || 0);
      return bDate - aDate; // Descending order (most recent first)
    });
    
    console.log(`Returning most recently updated module: ${allRecords[0].fields['Module Name'] || 'Unknown'}`);
    return allRecords[0];
  } catch (error) {
    console.error('Error finding next module to work on:', error);
    throw error;
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
    
    // Get current session data first
    const currentSession = await getSession(sessionId);
    if (!currentSession) {
      throw new Error(`Session ${sessionId} not found`);
    }
    
    // Prepare update object
    const updateObject = {};
    
    // Map standard fields directly
    if (updateData.status) updateObject['Status'] = updateData.status;
    if (updateData.summary) updateObject['Summary'] = updateData.summary;
    if (updateData.commits) updateObject['Commits'] = updateData.commits.join(', ');
    
    // Add Git context fields
    if (updateData.branchContext) updateObject['BranchContext'] = updateData.branchContext;
    
    // Handle date/time fields properly
    if (updateData.date) {
      updateObject['Date'] = formatDate(updateData.date);
    }
    
    if (updateData.startTime) {
      const startTime = typeof updateData.startTime === 'string'
        ? updateData.startTime
        : formatTime(updateData.startTime);
      updateObject['StartDate'] = startTime;
    }
    
    if (updateData.endTime) {
      const endTime = typeof updateData.endTime === 'string'
        ? updateData.endTime
        : formatTime(updateData.endTime);
      updateObject['EndDate'] = endTime;
    }
    
    // Handle commit hashes
    if (updateData.startCommit) {
      updateObject['StartCommit'] = updateData.startCommit;
    }
    
    // Temporarily disable EndCommit until the field is added to Airtable
    /*if (updateData.endCommit) {
      updateObject['EndCommit'] = updateData.endCommit;
    }*/
    
    // Handle session completion - when status changes to Completed
    if (updateData.status === 'Completed' && currentSession.fields.Status !== 'Completed') {
      console.log('Session is being completed - checking if we should update module status');
      
      // Set end time if not already set
      if (!updateObject['EndDate']) {
        updateObject['EndDate'] = formatTime(new Date());
      }
      
      // Temporarily disable EndCommit until the field is added to Airtable
      /*
      // Ensure we have an end commit
      if (!updateObject['EndCommit'] && !currentSession.fields.EndCommit) {
        try {
          // Try to get the latest commit
          const latestCommit = updateData.commits?.[0] || 
            currentSession.fields.Commits?.split(',')[0] ||
            'session-end';
          
          updateObject['EndCommit'] = latestCommit;
        } catch (error) {
          console.log(`Error getting latest commit: ${error.message}`);
        }
      }
      */
      
      // Check if we should mark the module as completed
      const focusModuleId = currentSession.fields.Focus?.[0];
      
      if (focusModuleId) {
        try {
          // Get the module
          const module = await airtableClient.getTable('Modules').find(focusModuleId);
          
          if (module) {
            const moduleName = module.fields['Module Name'] || 'Unknown';
            
            // Check if user indicated module is complete
            const summaryLower = (updateData.summary || '').toLowerCase();
            const hasCompleteKeyword = 
              summaryLower.includes('complet') || 
              summaryLower.includes('finish') || 
              summaryLower.includes('done');
              
            if (hasCompleteKeyword) {
              console.log(`Session summary indicates module "${moduleName}" completion, updating status`);
              
              await airtableClient.updateRecord('Modules', focusModuleId, {
                'Status': 'Completed'
              });
              
              // Add module completion to summary
              if (!updateObject['Summary']) {
                updateObject['Summary'] = `Completed module: ${moduleName}`;
              }
            } else {
              console.log(`Module "${moduleName}" likely still in progress`);
            }
          }
        } catch (error) {
          console.log(`Error checking module completion: ${error.message}`);
        }
      }
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

/**
 * Register or update a component in the ComponentRegistry
 * @param {Object} componentData - Component data to register
 * @param {string} componentData.name - Component name
 * @param {string} componentData.filePath - Component file path
 * @param {string} componentData.componentType - Type of component (Controller, Service, etc.)
 * @param {string} [componentData.purpose] - Component purpose description
 * @param {string} [componentData.moduleName] - Name of the module this component belongs to
 * @param {string} [componentData.sessionId] - Current session ID to link this component to
 * @returns {Promise<Object>} - The created or updated component record
 */
async function registerComponent(componentData) {
  try {
    console.log(`Registering/updating component "${componentData.name}" in Airtable...`);
    
    // First, check if component already exists with this name or file path
    let existingComponent = null;
    
    try {
      // Look for existing component by file path (most accurate way to identify a component)
      const components = await airtableClient.findRecords('ComponentRegistry', 
        `{FilePath} = "${componentData.filePath}"`);
      
      if (components.length > 0) {
        existingComponent = components[0];
        console.log(`Found existing component with same file path: ${componentData.filePath}`);
      } else {
        // Try to find by name if no match by path
        const nameComponents = await airtableClient.findRecords('ComponentRegistry',
          `{Name} = "${componentData.name}"`);
          
        if (nameComponents.length > 0) {
          existingComponent = nameComponents[0];
          console.log(`Found existing component with same name: ${componentData.name}`);
        }
      }
    } catch (error) {
      console.log(`Error checking for existing components: ${error.message}`);
    }
    
    // Prepare component record data
    const componentRecord = {
      'Name': componentData.name,
      'FilePath': componentData.filePath,
      'ComponentType': componentData.componentType
    };
    
    // Add purpose if provided
    if (componentData.purpose) {
      componentRecord['Purpose'] = componentData.purpose;
    }
    
    // Look up module record if module name is provided
    if (componentData.moduleName) {
      try {
        const moduleRecord = await findModuleByName(componentData.moduleName);
        
        if (moduleRecord) {
          // Set Module link - must be an array of IDs
          componentRecord['Module'] = [moduleRecord.id];
          console.log(`Linked component to module: ${moduleRecord.fields['Module Name']}`);
          
          // Also look up phase to give more context in logs
          try {
            if (moduleRecord.fields.Phase && moduleRecord.fields.Phase.length > 0) {
              const phaseId = moduleRecord.fields.Phase[0];
              const phase = await airtableClient.getTable('Phases').find(phaseId);
              if (phase) {
                console.log(`Module belongs to phase: ${phase.fields['Phase Name'] || 'Unknown'}`);
              }
            }
          } catch (error) {
            console.log(`Could not fetch phase info: ${error.message}`);
          }
        } else {
          console.log(`Module "${componentData.moduleName}" not found, component will not be linked to a module`);
        }
      } catch (error) {
        console.log(`Error linking component to module: ${error.message}`);
      }
    }
    
    // If there's a session ID, link the component to the session
    if (componentData.sessionId) {
      try {
        // Get current session
        const session = await getSession(componentData.sessionId);
        
        if (session) {
          console.log(`Linking component to session ID: ${componentData.sessionId}`);
          
          // If component already exists, we need to update the session to link to it
          if (existingComponent) {
            // Get existing components linked to the session
            const existingComponents = session.fields.Components || [];
            
            // Add the component ID if it's not already linked
            if (!existingComponents.includes(existingComponent.id)) {
              await airtableClient.updateRecord('Sessions', componentData.sessionId, {
                'Components': [...existingComponents, existingComponent.id]
              });
              console.log(`Added component to session's component list`);
            } else {
              console.log(`Component already linked to session`);
            }
          }
        }
      } catch (error) {
        console.log(`Error linking component to session: ${error.message}`);
      }
    }
    
    let result;
    
    // Update existing component or create new one
    if (existingComponent) {
      console.log(`Updating existing component: ${existingComponent.id}`);
      result = await airtableClient.updateRecord('ComponentRegistry', existingComponent.id, componentRecord);
    } else {
      console.log(`Creating new component`);
      result = await airtableClient.createRecord('ComponentRegistry', componentRecord);
      
      // If we created a new component and have a session ID, link it to the session
      if (result && componentData.sessionId) {
        try {
          const session = await getSession(componentData.sessionId);
          
          if (session) {
            const existingComponents = session.fields.Components || [];
            await airtableClient.updateRecord('Sessions', componentData.sessionId, {
              'Components': [...existingComponents, result.id]
            });
            console.log(`Linked newly created component to session`);
          }
        } catch (error) {
          console.log(`Error linking new component to session: ${error.message}`);
        }
      }
    }
    
    return result;
  } catch (error) {
    console.error(`Error registering component in Airtable:`, error);
    return null;
  }
}

module.exports = {
  // Core functionality
  updateModuleStatus,
  logSession,
  updateSession,
  getSession,
  getRecentSessions,
  registerComponent,
  
  // Phase and module functions
  getCurrentPhase,
  getAllPhases,
  getPhaseModules,
  getModuleInfo,
  findModuleByName,
  getNextModuleToWorkOn,
  
  // Utility functions
  formatDate,
  formatTime
};