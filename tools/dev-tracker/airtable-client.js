/**
 * Airtable client for development tracking
 * This is separate from the application's Airtable client
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const Airtable = require('airtable');

// Configuration for development tracking
const config = {
  AIRTABLE: {
    PAT: process.env.DEV_AIRTABLE_PAT,
    BASE_ID: process.env.DEV_AIRTABLE_BASE_ID,
    TABLES: {
      MODULES: 'Modules',
      PHASES: 'Phases',
      SESSIONS: 'Sessions',
      COMPONENTS: 'ComponentRegistry'
    }
  }
};

// Create Airtable client
class DevTrackingClient {
  constructor() {
    this.airtable = new Airtable({
      apiKey: config.AIRTABLE.PAT
    });
    this.base = this.airtable.base(config.AIRTABLE.BASE_ID);
  }

  // Get table reference
  getTable(tableName) {
    return this.base(tableName);
  }

  // Get all records from a table
  async getAllRecords(tableName, view = 'Grid view') {
    try {
      return await this.getTable(tableName).select({ view }).all();
    } catch (error) {
      console.error(`Error getting records from ${tableName}:`, error);
      throw error;
    }
  }

  // Find records by formula
  async findRecords(tableName, formula, view = 'Grid view') {
    try {
      return await this.getTable(tableName).select({
        filterByFormula: formula,
        view
      }).all();
    } catch (error) {
      console.error(`Error finding records in ${tableName}:`, error);
      throw error;
    }
  }

  // Create a record
  async createRecord(tableName, fields) {
    try {
      return await this.getTable(tableName).create(fields);
    } catch (error) {
      console.error(`Error creating record in ${tableName}:`, error);
      throw error;
    }
  }

  // Update a record
  async updateRecord(tableName, recordId, fields) {
    try {
      return await this.getTable(tableName).update(recordId, fields);
    } catch (error) {
      console.error(`Error updating record ${recordId} in ${tableName}:`, error);
      throw error;
    }
  }

  // Delete a record
  async deleteRecord(tableName, recordId) {
    try {
      await this.getTable(tableName).destroy(recordId);
      return recordId;
    } catch (error) {
      console.error(`Error deleting record ${recordId} from ${tableName}:`, error);
      throw error;
    }
  }
  
  // List all tables in the base
  async listTables() {
    try {
      const response = await fetch(`https://api.airtable.com/v0/meta/bases/${config.AIRTABLE.BASE_ID}/tables`, {
        headers: {
          'Authorization': `Bearer ${config.AIRTABLE.PAT}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error(`Error fetching tables: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      return data.tables;
    } catch (error) {
      console.error('Error listing tables:', error);
      throw error;
    }
  }
  
  // List fields in a table
  async listFields(tableId) {
    try {
      const response = await fetch(`https://api.airtable.com/v0/meta/bases/${config.AIRTABLE.BASE_ID}/tables/${tableId}/fields`, {
        headers: {
          'Authorization': `Bearer ${config.AIRTABLE.PAT}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error(`Error fetching fields: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      return data.fields;
    } catch (error) {
      console.error('Error listing fields:', error);
      throw error;
    }
  }
  
  // Create a new table
  async createTable(tableName, fields) {
    try {
      const response = await fetch(`https://api.airtable.com/v0/meta/bases/${config.AIRTABLE.BASE_ID}/tables`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${config.AIRTABLE.PAT}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: tableName,
          fields: fields
        })
      });
      
      if (!response.ok) {
        throw new Error(`Error creating table: ${response.status} ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('Error creating table:', error);
      throw error;
    }
  }
  
  // Create a new field in a table
  async createField(tableId, field) {
    try {
      const response = await fetch(`https://api.airtable.com/v0/meta/bases/${config.AIRTABLE.BASE_ID}/tables/${tableId}/fields`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${config.AIRTABLE.PAT}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(field)
      });
      
      if (!response.ok) {
        throw new Error(`Error creating field: ${response.status} ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error('Error creating field:', error);
      throw error;
    }
  }
}

module.exports = new DevTrackingClient();