/**
 * Daily maintenance script for Airtable sessions
 * - Links unlinked sessions to modules based on branch name and commits
 * - Generates better summaries for sessions with missing summaries
 * - Ensures all sessions have proper module links
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Initialize Airtable
const airtable = new Airtable({
  apiKey: process.env.DEV_AIRTABLE_PAT
});
const base = airtable.base(process.env.DEV_AIRTABLE_BASE_ID);

// Get sessions for the last 7 days
async function getRecentSessions() {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const dateString = sevenDaysAgo.toISOString().split('T')[0];
  
  return await base('Sessions').select({
    filterByFormula: `IS_AFTER({Date}, '${dateString}')`
  }).all();
}

// Extract feature name from branch
function extractFeatureName(branch) {
  if (!branch || !branch.startsWith('feature/')) return null;
  
  // Extract name, convert dashes to spaces, and capitalize words
  const rawName = branch.replace('feature/', '');
  return rawName
    .replace(/-/g, ' ')
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

// Generate a better summary based on session data
function generateSummary(session) {
  const fields = session.fields;
  let summary = '';
  
  // Try to extract info from branch name
  const featureName = extractFeatureName(fields.Branch);
  if (featureName) {
    summary = `Implementation of ${featureName}`;
  }
  
  // Add module context if available
  if (fields.Focus && fields.Focus.length > 0) {
    // We'll need to look up the module name later
    summary += ` related to module development`;
  }
  
  // Add commit context if available
  if (fields.Commits) {
    const commitTypes = [];
    if (fields.Commits.includes('feat:')) commitTypes.push('feature');
    if (fields.Commits.includes('fix:')) commitTypes.push('bug fix');
    if (fields.Commits.includes('docs:')) commitTypes.push('documentation');
    if (fields.Commits.includes('refactor:')) commitTypes.push('refactoring');
    if (fields.Commits.includes('test:')) commitTypes.push('testing');
    
    if (commitTypes.length > 0) {
      summary += `. Includes ${commitTypes.join(', ')} changes.`;
    }
  }
  
  return summary || 'Development session';
}

// Maintain sessions by improving summaries and linking to modules
async function maintainSessions() {
  try {
    console.log('Starting session maintenance...');
    
    // Get recent sessions and all modules
    const sessions = await getRecentSessions();
    const modules = await base('Modules').select().all();
    
    console.log(`Found ${sessions.length} recent sessions to check`);
    
    // Create map of module names to IDs
    const moduleMap = new Map();
    modules.forEach(module => {
      moduleMap.set(module.fields['Module Name'], module.id);
    });
    
    // Process each session
    for (const session of sessions) {
      const fields = session.fields;
      const needsUpdate = {};
      
      // Check for missing or empty summary
      if (!fields.Summary || fields.Summary.trim() === '') {
        needsUpdate.Summary = generateSummary(session);
      }
      
      // Check for missing module link
      if (!fields.Focus || fields.Focus.length === 0) {
        // Try to determine module from commits or branch name
        const commits = fields.Commits || '';
        const branch = fields.Branch || '';
        
        // Look for module mentions in commits
        let foundModule = null;
        for (const [moduleName, moduleId] of moduleMap.entries()) {
          if (commits.includes(moduleName) || branch.includes(moduleName)) {
            foundModule = moduleId;
            console.log(`Found module "${moduleName}" mentioned in session`);
            break;
          }
        }
        
        // If no direct match, try common patterns
        if (!foundModule) {
          // Check if branch name mentions a component we can map to a module
          const branchLower = branch.toLowerCase();
          if (branchLower.includes('content')) {
            const contentModules = ['Implement Content Repository', 'Implement Content Service with AI integration', 'Implement Content Controller for API endpoints'];
            for (const moduleName of contentModules) {
              if (moduleMap.has(moduleName)) {
                foundModule = moduleMap.get(moduleName);
                console.log(`Mapped branch "${branch}" to module "${moduleName}"`);
                break;
              }
            }
          } else if (branchLower.includes('brand')) {
            // Similar mapping for brand-related modules
            // Add other module mappings as needed
          }
        }
        
        if (foundModule) {
          needsUpdate.Focus = [foundModule];
        }
      }
      
      // Update session if needed
      if (Object.keys(needsUpdate).length > 0) {
        console.log(`Updating session ${session.id} with:`, needsUpdate);
        await base('Sessions').update(session.id, needsUpdate);
      } else {
        console.log(`Session ${session.id} doesn't need updates`);
      }
    }
    
    console.log('Session maintenance completed!');
  } catch (error) {
    console.error('Error during session maintenance:', error);
  }
}

// Run the maintenance
maintainSessions();