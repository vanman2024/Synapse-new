/**
 * Setup script for Airtable development tracking
 * This script creates the necessary tables and fields in Airtable
 */
const airtableClient = require('./airtable-client');
const fs = require('fs');
const path = require('path');

// Load development overview for initial data
const overviewPath = path.join(__dirname, '../../docs/project/DEVELOPMENT_OVERVIEW.md');
const overviewContent = fs.readFileSync(overviewPath, 'utf8');

// Parse phases and modules from the overview document
function parseOverview(content) {
  const phases = [];
  const modules = [];
  
  // Extract phases
  const phaseRegex = /## Phase (\d+): ([^(]+) \(([^)]+)\)/g;
  let phaseMatch;
  while ((phaseMatch = phaseRegex.exec(content)) !== null) {
    const phaseNumber = phaseMatch[1];
    const phaseName = phaseMatch[2].trim();
    const status = phaseMatch[3] === 'Current' ? 'Current' : 
                  phaseMatch[3] === 'Complete' ? 'Completed' : 'Planned';
    
    phases.push({
      name: phaseName,
      number: parseInt(phaseNumber, 10),
      status
    });
  }
  
  // Extract modules and their phases
  let currentPhase = null;
  const lines = content.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Check if this is a phase line
    const phaseMatch = line.match(/## Phase (\d+): ([^(]+)/);
    if (phaseMatch) {
      currentPhase = {
        number: parseInt(phaseMatch[1], 10),
        name: phaseMatch[2].trim()
      };
      continue;
    }
    
    // Check if this is a module line
    const moduleMatch = line.match(/- \[([\sx])\] (.+)/);
    if (moduleMatch && currentPhase) {
      const isComplete = moduleMatch[1] === 'x';
      const moduleName = moduleMatch[2].trim();
      
      modules.push({
        name: moduleName,
        phase: currentPhase.name,
        phaseNumber: currentPhase.number,
        status: isComplete ? 'Completed' : 
               currentPhase.name.includes('Current') ? 'In Progress' : 'Planned'
      });
    }
  }
  
  return { phases, modules };
}

// Setup tables in Airtable
async function setupTables() {
  try {
    console.log('Setting up Airtable tables for development tracking...');
    
    // Parse overview
    const { phases, modules } = parseOverview(overviewContent);
    
    // Create Phases table
    console.log('Setting up Phases table...');
    for (const phase of phases) {
      try {
        await airtableClient.createRecord('Phases', {
          'Name': phase.name,
          'Number': phase.number,
          'Status': phase.status
        });
        console.log(`Created phase: ${phase.name}`);
      } catch (error) {
        console.error(`Error creating phase ${phase.name}:`, error.message);
      }
    }
    
    // Create Modules table
    console.log('Setting up Modules table...');
    for (const module of modules) {
      try {
        await airtableClient.createRecord('Modules', {
          'Name': module.name,
          'Phase': module.phase,
          'Phase Number': module.phaseNumber,
          'Status': module.status
        });
        console.log(`Created module: ${module.name}`);
      } catch (error) {
        console.error(`Error creating module ${module.name}:`, error.message);
      }
    }
    
    // Create Sessions table (empty for now)
    console.log('Setting up Sessions table...');
    
    console.log('Airtable setup complete!');
  } catch (error) {
    console.error('Error setting up Airtable tables:', error);
  }
}

// Run setup
setupTables();