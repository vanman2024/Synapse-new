/**
 * Script to update Sessions table with linked records to Modules
 * and populate the Summary field
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Update sessions with module links and summaries
async function updateSessions() {
  try {
    console.log('Updating Sessions table with module links and summaries...');
    
    // Get all sessions
    const sessions = await base('Sessions').select().all();
    console.log(`Found ${sessions.length} sessions to update`);
    
    // Get all modules for matching
    const modules = await base('Modules').select({
      fields: ['Module Name']
    }).all();
    
    console.log(`Found ${modules.length} modules for linking`);
    
    // Map module names to IDs for quick lookup
    const moduleMap = new Map();
    modules.forEach(module => {
      moduleMap.set(module.fields['Module Name'], module.id);
    });
    
    // Update each session
    for (const session of sessions) {
      // Extract data from session
      const branch = session.fields.Branch || '';
      const status = session.fields.Status || '';
      const commits = session.fields.Commits || '';
      const notes = session.fields.Notes || '';
      
      // Determine which module this session is about
      let moduleToLink = null;
      
      // Try to find a module mentioned in the notes or commits
      for (const [moduleName, moduleId] of moduleMap.entries()) {
        if (notes.includes(moduleName) || commits.includes(moduleName)) {
          moduleToLink = moduleId;
          console.log(`Found module "${moduleName}" in session notes/commits`);
          break;
        }
      }
      
      // If no exact match, try a fuzzy match
      if (!moduleToLink) {
        // Look for common module patterns in commits
        let moduleName = null;
        
        if (commits.includes('Content Service')) {
          moduleName = 'Implement Content Service with AI integration';
        } else if (commits.includes('Content Controller')) {
          moduleName = 'Implement Content Controller for API endpoints';
        } else if (commits.includes('Content Repository')) {
          moduleName = 'Implement Content Repository for content entities';
        } else if (commits.includes('prompt template')) {
          moduleName = 'Improve and formalize OpenAI prompt templates';
        }
        
        if (moduleName && moduleMap.has(moduleName)) {
          moduleToLink = moduleMap.get(moduleName);
          console.log(`Fuzzy matched module "${moduleName}" from commits`);
        }
      }
      
      // Create update fields
      const updateFields = {};
      
      // Generate summary if not present
      if (!session.fields.Summary) {
        updateFields.Summary = notes || 
                              `Work on ${branch} branch with status: ${status}` +
                              (commits ? `. Commits: ${commits}` : '');
      }
      
      // Add module link if found
      if (moduleToLink) {
        updateFields.Focus = [moduleToLink];
      }
      
      // Update the session if there are fields to update
      if (Object.keys(updateFields).length > 0) {
        await base('Sessions').update(session.id, updateFields);
        console.log(`Updated session ${session.id} with:`, updateFields);
      } else {
        console.log(`No updates needed for session ${session.id}`);
      }
    }
    
    console.log('\nSessions updated successfully!');
    console.log('Some sessions may not have been linked to modules if no matches were found.');
    console.log('You can manually link them in the Airtable UI if needed.');
    
  } catch (error) {
    console.error('Error updating sessions:', error);
  }
}

// Run the update
updateSessions();