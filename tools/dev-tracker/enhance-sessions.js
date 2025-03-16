/**
 * enhance-sessions.js - Enhances the Sessions table with Git context fields
 * Adds fields for tracking Git commit hashes and branch context
 */

const airtable = require('./airtable-client');

async function enhanceSessionsTable() {
  console.log('Enhancing Sessions table with Git context fields...');
  
  try {
    // New fields to add
    const newFields = [
      {
        name: 'BranchContext',
        type: 'multilineText',
        options: {
          description: 'Description of what the branch is implementing'
        }
      },
      {
        name: 'StartCommit',
        type: 'singleLineText',
        options: {
          description: 'Git commit hash at session start'
        }
      },
      {
        name: 'EndCommit',
        type: 'singleLineText',
        options: {
          description: 'Git commit hash at session end'
        }
      },
      {
        name: 'Components',
        type: 'multipleRecordLinks',
        options: {
          linkedTableId: 'ComponentRegistry',
          description: 'Components modified during this session'
        }
      }
    ];
    
    // Get current fields in Sessions table
    const tables = await airtable.listTables();
    const sessionsTable = tables.find(table => table.name === 'Sessions');
    
    if (!sessionsTable) {
      console.error('Sessions table not found');
      return;
    }
    
    // Get existing fields
    const fields = await airtable.listFields(sessionsTable.id);
    const existingFieldNames = fields.map(field => field.name);
    
    // Add each new field if it doesn't already exist
    for (const newField of newFields) {
      if (!existingFieldNames.includes(newField.name)) {
        console.log(`Adding ${newField.name} field to Sessions table...`);
        await airtable.createField(sessionsTable.id, newField);
      } else {
        console.log(`Field ${newField.name} already exists in Sessions table`);
      }
    }
    
    console.log('Sessions table enhanced successfully');
  } catch (error) {
    console.error('Error enhancing Sessions table:', error);
  }
}

// Run the function if this script is executed directly
if (require.main === module) {
  enhanceSessionsTable()
    .then(() => {
      console.log('Done');
      process.exit(0);
    })
    .catch(err => {
      console.error('Failed to enhance Sessions table:', err);
      process.exit(1);
    });
}

module.exports = { enhanceSessionsTable };