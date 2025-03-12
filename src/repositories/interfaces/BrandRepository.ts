import { Brand } from '../../models';
import { BaseRepository } from './BaseRepository';

/**
 * Repository interface for Brand entities
 * Extends the BaseRepository with Brand-specific methods
 */
export interface BrandRepository extends BaseRepository<Brand> {
  /**
   * Find a brand by its name
   * @param name The name of the brand
   * @returns A promise that resolves to the brand or null if not found
   */
  findByName(name: string): Promise<Brand | null>;
  
  /**
   * Extract and save brand style from website
   * @param brandId The ID of the brand
   * @param websiteUrl The URL of the brand's website
   * @returns A promise that resolves to the updated brand with style information
   */
  extractStyleFromWebsite(brandId: string, websiteUrl: string): Promise<Brand | null>;
  
  /**
   * Upload and process a brand logo
   * @param brandId The ID of the brand
   * @param logoFile The logo file data
   * @returns A promise that resolves to the updated brand with logo information
   */
  uploadLogo(brandId: string, logoFile: Buffer): Promise<Brand | null>;
  
  /**
   * Update brand colors
   * @param brandId The ID of the brand
   * @param colors The colors to update
   * @returns A promise that resolves to the updated brand
   */
  updateColors(brandId: string, colors: Brand['colors']): Promise<Brand | null>;
  
  /**
   * Get all brands with their associated content count
   * @returns A promise that resolves to an array of brands with content count
   */
  getBrandsWithContentCount(): Promise<Array<Brand & { contentCount: number }>>;
}