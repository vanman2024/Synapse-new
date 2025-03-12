import Airtable from 'airtable';
import { FieldSet } from 'airtable/lib/field_set';
import { Records } from 'airtable/lib/records';
import { QueryParams } from 'airtable/lib/query_params';
import config from '../../config';

/**
 * Airtable client class for connecting to and querying Airtable
 * Provides a reusable wrapper around the Airtable SDK
 */
export class AirtableClient {
  private static instance: AirtableClient;
  private connection: Airtable;
  private base: Airtable.Base;
  
  /**
   * Private constructor for singleton pattern
   */
  private constructor() {
    // Configure Airtable connection with Personal Access Token
    // This is the newer approach recommended by Airtable
    this.connection = new Airtable({
      apiKey: config.AIRTABLE.PERSONAL_ACCESS_TOKEN
    });
    
    // Get the specific Airtable base
    this.base = this.connection.base(config.AIRTABLE.BASE_ID);
  }
  
  /**
   * Get a singleton instance of AirtableClient
   * @returns The AirtableClient instance
   */
  public static getInstance(): AirtableClient {
    if (!AirtableClient.instance) {
      AirtableClient.instance = new AirtableClient();
    }
    return AirtableClient.instance;
  }
  
  /**
   * Get a table from the Airtable base
   * @param tableName The name of the table
   * @returns The Airtable table
   */
  public getTable(tableName: string): Airtable.Table<FieldSet> {
    return this.base(tableName);
  }
  
  /**
   * Select records from a table
   * @param tableName The name of the table
   * @param params The query parameters
   * @returns A promise that resolves to the selected records
   */
  public async select(
    tableName: string, 
    params?: QueryParams<FieldSet>
  ): Promise<Records<FieldSet>> {
    try {
      return await this.getTable(tableName).select(params || {}).all();
    } catch (error) {
      console.error(`Error selecting records from ${tableName}:`, error);
      throw error;
    }
  }
  
  /**
   * Find a record by ID
   * @param tableName The name of the table
   * @param recordId The ID of the record
   * @returns A promise that resolves to the record
   */
  public async findById(
    tableName: string, 
    recordId: string
  ): Promise<Airtable.Record<FieldSet>> {
    try {
      return await this.getTable(tableName).find(recordId);
    } catch (error) {
      console.error(`Error finding record ${recordId} in ${tableName}:`, error);
      throw error;
    }
  }
  
  /**
   * Create a record in a table
   * @param tableName The name of the table
   * @param record The record data
   * @returns A promise that resolves to the created record
   */
  public async create(
    tableName: string, 
    record: Partial<FieldSet>
  ): Promise<Airtable.Record<FieldSet>> {
    try {
      return await this.getTable(tableName).create(record);
    } catch (error) {
      console.error(`Error creating record in ${tableName}:`, error);
      throw error;
    }
  }

  /**
   * Create multiple records in a table
   * @param tableName The name of the table
   * @param records The array of record data
   * @returns A promise that resolves to the created records
   */
  public async createMultiple(
    tableName: string, 
    records: Array<Partial<FieldSet>>
  ): Promise<Array<Airtable.Record<FieldSet>>> {
    try {
      return await this.getTable(tableName).create(records);
    } catch (error) {
      console.error(`Error creating multiple records in ${tableName}:`, error);
      throw error;
    }
  }
  
  /**
   * Update a record in a table
   * @param tableName The name of the table
   * @param recordId The ID of the record
   * @param record The record data to update
   * @returns A promise that resolves to the updated record
   */
  public async update(
    tableName: string, 
    recordId: string, 
    record: Partial<FieldSet>
  ): Promise<Airtable.Record<FieldSet>> {
    try {
      return await this.getTable(tableName).update(recordId, record);
    } catch (error) {
      console.error(`Error updating record ${recordId} in ${tableName}:`, error);
      throw error;
    }
  }
  
  /**
   * Delete a record from a table
   * @param tableName The name of the table
   * @param recordId The ID of the record
   * @returns A promise that resolves to the deleted record ID
   */
  public async delete(
    tableName: string, 
    recordId: string
  ): Promise<string> {
    try {
      await this.getTable(tableName).destroy(recordId);
      return recordId;
    } catch (error) {
      console.error(`Error deleting record ${recordId} from ${tableName}:`, error);
      throw error;
    }
  }

  /**
   * Update multiple records in a table
   * @param tableName The name of the table
   * @param records Array of objects with id and fields
   * @returns A promise that resolves to the updated records
   */
  public async updateMultiple(
    tableName: string,
    records: Array<{id: string, fields: Partial<FieldSet>}>
  ): Promise<Array<Airtable.Record<FieldSet>>> {
    try {
      return await this.getTable(tableName).update(
        records.map(record => ({
          id: record.id,
          fields: record.fields
        }))
      );
    } catch (error) {
      console.error(`Error updating multiple records in ${tableName}:`, error);
      throw error;
    }
  }

  /**
   * Delete multiple records from a table
   * @param tableName The name of the table
   * @param recordIds Array of record IDs to delete
   * @returns A promise that resolves to the deleted record IDs
   */
  public async deleteMultiple(
    tableName: string,
    recordIds: string[]
  ): Promise<string[]> {
    try {
      await this.getTable(tableName).destroy(recordIds);
      return recordIds;
    } catch (error) {
      console.error(`Error deleting multiple records from ${tableName}:`, error);
      throw error;
    }
  }
}