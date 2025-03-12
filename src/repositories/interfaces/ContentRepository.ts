import { Content, ContentStatus, ContentType } from '../../models';
import { BaseRepository } from './BaseRepository';

/**
 * Repository interface for Content entities
 * Extends the BaseRepository with Content-specific methods
 */
export interface ContentRepository extends BaseRepository<Content> {
  /**
   * Find content by brand ID
   * @param brandId The ID of the brand associated with the content
   * @returns A promise that resolves to an array of content
   */
  findByBrandId(brandId: string): Promise<Content[]>;
  
  /**
   * Find content by status
   * @param status The status to filter by
   * @returns A promise that resolves to an array of content
   */
  findByStatus(status: ContentStatus): Promise<Content[]>;
  
  /**
   * Find content by type
   * @param type The type to filter by
   * @returns A promise that resolves to an array of content
   */
  findByType(type: ContentType): Promise<Content[]>;
  
  /**
   * Find content by both brand ID and status
   * @param brandId The ID of the brand
   * @param status The status to filter by
   * @returns A promise that resolves to an array of content
   */
  findByBrandIdAndStatus(brandId: string, status: ContentStatus): Promise<Content[]>;
  
  /**
   * Find content scheduled for a specific date range
   * @param startDate The start of the date range
   * @param endDate The end of the date range
   * @returns A promise that resolves to an array of content
   */
  findScheduledBetweenDates(startDate: Date, endDate: Date): Promise<Content[]>;
  
  /**
   * Update content status
   * @param contentId The ID of the content
   * @param status The new status
   * @param feedback Optional feedback message
   * @param userId Optional user ID who made the status change
   * @returns A promise that resolves to the updated content
   */
  updateStatus(
    contentId: string, 
    status: ContentStatus, 
    feedback?: string, 
    userId?: string
  ): Promise<Content | null>;
  
  /**
   * Generate and update image for content
   * @param contentId The ID of the content
   * @param prompt Optional custom prompt
   * @returns A promise that resolves to the updated content with image URL
   */
  generateImage(contentId: string, prompt?: string): Promise<Content | null>;
  
  /**
   * Get content analytics
   * @param fromDate Optional start date for analytics
   * @param toDate Optional end date for analytics
   * @returns A promise that resolves to an object with analytics data
   */
  getAnalytics(fromDate?: Date, toDate?: Date): Promise<{
    totalCount: number;
    byStatus: Record<ContentStatus, number>;
    byType: Record<ContentType, number>;
    averageApprovalTime: number;
  }>;
}