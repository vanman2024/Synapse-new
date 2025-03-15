/**
 * Airtable client for development tracking
 * This is separate from the application's Airtable client
 */
require('dotenv').config({ path: '../../.env' });
const Airtable = require('airtable');

// Configuration for development tracking
const config = {
  AIRTABLE: {
    PAT: process.env.DEV_AIRTABLE_PAT,
    BASE_ID: process.env.DEV_AIRTABLE_BASE_ID,
    TABLES: {
      MODULES: process.env.DEV_AIRTABLE_MODULES_TABLE || 'Modules',
      PHASES: process.env.DEV_AIRTABLE_PHASES_TABLE || 'Phases',
      SESSIONS: process.env.DEV_AIRTABLE_SESSIONS_TABLE || 'Sessions'
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
}

module.exports = new DevTrackingClient();