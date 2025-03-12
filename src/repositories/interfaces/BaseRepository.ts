/**
 * Generic Repository interface that defines standard CRUD operations
 * T is the entity type (e.g., Brand, Content, Job)
 */
export interface BaseRepository<T> {
  /**
   * Find an entity by its ID
   * @param id The unique identifier of the entity
   * @returns A promise that resolves to the entity or null if not found
   */
  findById(id: string): Promise<T | null>;
  
  /**
   * Find all entities that match the given filter criteria
   * @param filter An object containing filter criteria
   * @returns A promise that resolves to an array of entities
   */
  findAll(filter?: Partial<T>): Promise<T[]>;
  
  /**
   * Create a new entity
   * @param entity The entity data to create
   * @returns A promise that resolves to the created entity
   */
  create(entity: Omit<T, 'id' | 'createdAt' | 'updatedAt'>): Promise<T>;
  
  /**
   * Update an existing entity
   * @param id The unique identifier of the entity
   * @param entity The entity data to update
   * @returns A promise that resolves to the updated entity
   */
  update(id: string, entity: Partial<T>): Promise<T | null>;
  
  /**
   * Delete an entity by its ID
   * @param id The unique identifier of the entity
   * @returns A promise that resolves to true if deleted, false otherwise
   */
  delete(id: string): Promise<boolean>;
}