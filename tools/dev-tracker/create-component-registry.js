/**
 * create-component-registry.js - Creates the ComponentRegistry table in Airtable
 * This table will store information about code components and their purpose
 */

const airtable = require('./airtable-client');

async function createComponentRegistryTable() {
  console.log('Creating ComponentRegistry table...');
  
  try {
    // Check if table already exists
    const tables = await airtable.listTables();
    if (tables.some(table => table.name === 'ComponentRegistry')) {
      console.log('ComponentRegistry table already exists');
      return;
    }
    
    // Create the table
    await airtable.createTable('ComponentRegistry', [
      {
        name: 'Name',
        type: 'singleLineText',
        options: {}
      },
      {
        name: 'FilePath',
        type: 'singleLineText',
        options: {}
      },
      {
        name: 'ComponentType',
        type: 'singleSelect',
        options: {
          choices: [
            { name: 'Controller' },
            { name: 'Service' },
            { name: 'Repository' },
            { name: 'Model' },
            { name: 'Middleware' },
            { name: 'Utility' },
            { name: 'Script' },
            { name: 'Configuration' },
            { name: 'Other' }
          ]
        }
      },
      {
        name: 'Purpose',
        type: 'multilineText',
        options: {}
      },
      {
        name: 'Module',
        type: 'foreignKey',
        options: {
          foreignTableId: 'Modules'
        }
      }
    ]);
    
    console.log('ComponentRegistry table created successfully');
  } catch (error) {
    console.error('Error creating ComponentRegistry table:', error);
  }
}

// Run the function if this script is executed directly
if (require.main === module) {
  createComponentRegistryTable()
    .then(() => {
      console.log('Done');
      process.exit(0);
    })
    .catch(err => {
      console.error('Failed to create ComponentRegistry table:', err);
      process.exit(1);
    });
}

module.exports = { createComponentRegistryTable };