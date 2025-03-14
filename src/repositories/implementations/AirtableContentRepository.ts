import { FieldSet } from 'airtable/lib/field_set';
import { Content, ContentStatus, ContentType, FeedbackEntry } from '../../models';
import { ContentRepository } from '../interfaces/ContentRepository';
import { AirtableClient } from '../../data-sources/airtable/AirtableClient';
import { CloudinaryService } from '../../services/CloudinaryService';
import { OpenAIService } from '../../services/OpenAIService';
import config from '../../config';

/**
 * Airtable implementation of the Content repository
 */
export class AirtableContentRepository implements ContentRepository {
  private readonly airtable: AirtableClient;
  private readonly tableName: string;
  private readonly cloudinary: CloudinaryService;
  private readonly openai: OpenAIService;

  /**
   * Constructor
   */
  constructor() {
    this.airtable = AirtableClient.getInstance();
    this.tableName = config.AIRTABLE.TABLES.JOB_DESCRIPTIONS || 'Content';
    this.cloudinary = new CloudinaryService();
    this.openai = new OpenAIService();
  }

  /**
   * Convert an Airtable record to a Content object
   * @param record The Airtable record
   * @returns A Content object
   */
  private mapRecordToContent(record: Record<string, any>): Content {
    return {
      id: record.id,
      brandId: record.BrandId || record.CompanyId,
      type: record.ContentType || ContentType.GENERAL,
      status: record.Status || ContentStatus.DRAFT,
      title: record.Title,
      description: record.Description,
      rawText: record.RawText,
      formattedText: record.FormattedText,
      imagePrompt: record.ImagePrompt,
      imageUrl: record.ImageUrl,
      feedbackHistory: record.FeedbackHistory ? 
        JSON.parse(record.FeedbackHistory) as FeedbackEntry[] : 
        [],
      metadata: record.Metadata ? JSON.parse(record.Metadata) : {},
      distributionChannels: record.DistributionChannels || [],
      scheduledDate: record.ScheduledDate ? new Date(record.ScheduledDate) : undefined,
      publishedDate: record.PublishedDate ? new Date(record.PublishedDate) : undefined,
      createdAt: new Date(record.CreatedAt || record._createdTime),
      updatedAt: new Date(record.UpdatedAt || record._updatedTime)
    };
  }

  /**
   * Convert a Content object to an Airtable record
   * @param content The Content object
   * @returns An Airtable record
   */
  private mapContentToRecord(content: Partial<Content>): Partial<FieldSet> {
    const record: Partial<FieldSet> = {};

    if (content.brandId) record.BrandId = content.brandId;
    if (content.type) record.ContentType = content.type;
    if (content.status) record.Status = content.status;
    if (content.title) record.Title = content.title;
    if (content.description) record.Description = content.description;
    if (content.rawText) record.RawText = content.rawText;
    if (content.formattedText) record.FormattedText = content.formattedText;
    if (content.imagePrompt) record.ImagePrompt = content.imagePrompt;
    if (content.imageUrl) record.ImageUrl = content.imageUrl;
    
    if (content.feedbackHistory && content.feedbackHistory.length > 0) {
      record.FeedbackHistory = JSON.stringify(content.feedbackHistory);
    }
    
    if (content.metadata && Object.keys(content.metadata).length > 0) {
      record.Metadata = JSON.stringify(content.metadata);
    }
    
    if (content.distributionChannels && content.distributionChannels.length > 0) {
      record.DistributionChannels = content.distributionChannels;
    }
    
    if (content.scheduledDate) {
      record.ScheduledDate = content.scheduledDate.toISOString();
    }
    
    if (content.publishedDate) {
      record.PublishedDate = content.publishedDate.toISOString();
    }

    return record;
  }

  /**
   * Find a content by its ID
   * @param id The unique identifier of the content
   * @returns A promise that resolves to the content or null if not found
   */
  public async findById(id: string): Promise<Content | null> {
    try {
      const record = await this.airtable.findById(this.tableName, id);
      return this.mapRecordToContent(record.fields);
    } catch (error) {
      console.error(`Error finding content with ID ${id}:`, error);
      return null;
    }
  }

  /**
   * Find all content that match the given filter criteria
   * @param filter An object containing filter criteria
   * @returns A promise that resolves to an array of content
   */
  public async findAll(filter?: Partial<Content>): Promise<Content[]> {
    try {
      const filterFormula = this.buildFilterFormula(filter);
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula
      });
      
      return records.map(record => this.mapRecordToContent(record.fields));
    } catch (error) {
      console.error('Error finding all content:', error);
      return [];
    }
  }

  /**
   * Build an Airtable filter formula from a content filter object
   * @param filter The filter object
   * @returns An Airtable filter formula string
   */
  private buildFilterFormula(filter?: Partial<Content>): string {
    if (!filter || Object.keys(filter).length === 0) {
      return '';
    }

    const conditions: string[] = [];

    if (filter.brandId) {
      conditions.push(`{BrandId} = '${filter.brandId}'`);
    }

    if (filter.type) {
      conditions.push(`{ContentType} = '${filter.type}'`);
    }

    if (filter.status) {
      conditions.push(`{Status} = '${filter.status}'`);
    }

    if (filter.scheduledDate) {
      const dateStr = filter.scheduledDate.toISOString().split('T')[0];
      conditions.push(`DATETIME_PARSE({ScheduledDate}) = DATETIME_PARSE('${dateStr}')`);
    }

    if (conditions.length === 0) {
      return '';
    }

    if (conditions.length === 1) {
      return conditions[0];
    }

    return `AND(${conditions.join(', ')})`;
  }

  /**
   * Create a new content
   * @param content The content data to create
   * @returns A promise that resolves to the created content
   */
  public async create(content: Omit<Content, 'id' | 'createdAt' | 'updatedAt'>): Promise<Content> {
    try {
      const record = this.mapContentToRecord(content);
      const createdRecord = await this.airtable.create(this.tableName, record);
      
      return this.mapRecordToContent(createdRecord.fields);
    } catch (error) {
      console.error('Error creating content:', error);
      throw error;
    }
  }

  /**
   * Update an existing content
   * @param id The unique identifier of the content
   * @param content The content data to update
   * @returns A promise that resolves to the updated content
   */
  public async update(id: string, content: Partial<Content>): Promise<Content | null> {
    try {
      const record = this.mapContentToRecord(content);
      const updatedRecord = await this.airtable.update(this.tableName, id, record);
      
      return this.mapRecordToContent(updatedRecord.fields);
    } catch (error) {
      console.error(`Error updating content with ID ${id}:`, error);
      return null;
    }
  }

  /**
   * Delete a content by its ID
   * @param id The unique identifier of the content
   * @returns A promise that resolves to true if deleted, false otherwise
   */
  public async delete(id: string): Promise<boolean> {
    try {
      // Check if content has an image to delete from Cloudinary
      const content = await this.findById(id);
      if (content && content.imageUrl) {
        // Try to extract public ID from the Cloudinary URL
        try {
          const urlParts = content.imageUrl.split('/');
          const filenamePart = urlParts[urlParts.length - 1];
          const publicId = filenamePart.split('.')[0];
          await this.cloudinary.deleteImage(publicId);
        } catch (cloudinaryError) {
          console.error('Error deleting image from Cloudinary:', cloudinaryError);
          // Continue with content deletion even if image deletion fails
        }
      }
      
      await this.airtable.delete(this.tableName, id);
      return true;
    } catch (error) {
      console.error(`Error deleting content with ID ${id}:`, error);
      return false;
    }
  }

  /**
   * Find content by brand ID
   * @param brandId The ID of the brand associated with the content
   * @returns A promise that resolves to an array of content
   */
  public async findByBrandId(brandId: string): Promise<Content[]> {
    try {
      const filterFormula = `{BrandId} = '${brandId}'`;
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula
      });
      
      return records.map(record => this.mapRecordToContent(record.fields));
    } catch (error) {
      console.error(`Error finding content for brand ID ${brandId}:`, error);
      return [];
    }
  }

  /**
   * Find content by status
   * @param status The status to filter by
   * @returns A promise that resolves to an array of content
   */
  public async findByStatus(status: ContentStatus): Promise<Content[]> {
    try {
      const filterFormula = `{Status} = '${status}'`;
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula
      });
      
      return records.map(record => this.mapRecordToContent(record.fields));
    } catch (error) {
      console.error(`Error finding content with status ${status}:`, error);
      return [];
    }
  }

  /**
   * Find content by type
   * @param type The type to filter by
   * @returns A promise that resolves to an array of content
   */
  public async findByType(type: ContentType): Promise<Content[]> {
    try {
      const filterFormula = `{ContentType} = '${type}'`;
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula
      });
      
      return records.map(record => this.mapRecordToContent(record.fields));
    } catch (error) {
      console.error(`Error finding content with type ${type}:`, error);
      return [];
    }
  }

  /**
   * Find content by both brand ID and status
   * @param brandId The ID of the brand
   * @param status The status to filter by
   * @returns A promise that resolves to an array of content
   */
  public async findByBrandIdAndStatus(brandId: string, status: ContentStatus): Promise<Content[]> {
    try {
      const filterFormula = `AND({BrandId} = '${brandId}', {Status} = '${status}')`;
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula
      });
      
      return records.map(record => this.mapRecordToContent(record.fields));
    } catch (error) {
      console.error(`Error finding content for brand ID ${brandId} with status ${status}:`, error);
      return [];
    }
  }

  /**
   * Find content scheduled for a specific date range
   * @param startDate The start of the date range
   * @param endDate The end of the date range
   * @returns A promise that resolves to an array of content
   */
  public async findScheduledBetweenDates(startDate: Date, endDate: Date): Promise<Content[]> {
    try {
      const startDateStr = startDate.toISOString();
      const endDateStr = endDate.toISOString();
      
      const filterFormula = `AND(
        {Status} = '${ContentStatus.SCHEDULED}',
        IS_AFTER({ScheduledDate}, '${startDateStr}'),
        IS_BEFORE({ScheduledDate}, '${endDateStr}')
      )`;
      
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula
      });
      
      return records.map(record => this.mapRecordToContent(record.fields));
    } catch (error) {
      console.error(`Error finding scheduled content between ${startDate} and ${endDate}:`, error);
      return [];
    }
  }

  /**
   * Update content status
   * @param contentId The ID of the content
   * @param status The new status
   * @param feedback Optional feedback message
   * @param userId Optional user ID who made the status change
   * @returns A promise that resolves to the updated content
   */
  public async updateStatus(
    contentId: string,
    status: ContentStatus,
    feedback?: string,
    userId?: string
  ): Promise<Content | null> {
    try {
      // Get current content
      const content = await this.findById(contentId);
      if (!content) {
        return null;
      }
      
      // Prepare update data
      const updateData: Partial<Content> = { 
        status 
      };
      
      // Add feedback to history if provided
      if (feedback) {
        const feedbackEntry: FeedbackEntry = {
          timestamp: new Date(),
          userId: userId || 'system',
          message: feedback,
          action: status === ContentStatus.APPROVED ? 'approve' : 
                  status === ContentStatus.REJECTED ? 'reject' : 'revise'
        };
        
        updateData.feedbackHistory = [
          ...(content.feedbackHistory || []),
          feedbackEntry
        ];
      }
      
      // Add published date if status is changing to PUBLISHED
      if (status === ContentStatus.PUBLISHED && content.status !== ContentStatus.PUBLISHED) {
        updateData.publishedDate = new Date();
      }
      
      // Update the content
      return this.update(contentId, updateData);
    } catch (error) {
      console.error(`Error updating status for content ${contentId}:`, error);
      return null;
    }
  }

  /**
   * Generate and update image for content
   * @param contentId The ID of the content
   * @param prompt Optional custom prompt
   * @returns A promise that resolves to the updated content with image URL
   */
  public async generateImage(contentId: string, prompt?: string): Promise<Content | null> {
    try {
      // Get current content
      const content = await this.findById(contentId);
      if (!content) {
        return null;
      }
      
      // Use provided prompt or content's existing imagePrompt or generate from content
      const imagePrompt = prompt || content.imagePrompt || this.generatePromptFromContent(content);
      
      // Generate image using OpenAI
      const { url } = await this.openai.generateImage(imagePrompt);
      
      // Upload image to Cloudinary for permanent storage
      const uploadResult = await this.cloudinary.uploadImage(
        url,
        `content/${content.brandId}`,
        {
          public_id: `content_${contentId}_${Date.now()}`,
          overwrite: true
        }
      );
      
      // Update content with new image URL and prompt
      return this.update(contentId, {
        imageUrl: uploadResult.secure_url,
        imagePrompt
      });
    } catch (error) {
      console.error(`Error generating image for content ${contentId}:`, error);
      return null;
    }
  }

  /**
   * Generate a prompt from content data
   * @param content The content to generate a prompt from
   * @returns A string prompt for image generation
   */
  private generatePromptFromContent(content: Content): string {
    // Start with the title
    let prompt = content.title || '';
    
    // Add description if available
    if (content.description) {
      prompt += `. ${content.description}`;
    }
    
    // Add generic professional quality markers
    prompt += '. Professional quality, highly detailed, photorealistic';
    
    return prompt;
  }

  /**
   * Get content analytics
   * @param fromDate Optional start date for analytics
   * @param toDate Optional end date for analytics
   * @returns A promise that resolves to an object with analytics data
   */
  public async getAnalytics(fromDate?: Date, toDate?: Date): Promise<{
    totalCount: number;
    byStatus: Record<ContentStatus, number>;
    byType: Record<ContentType, number>;
    averageApprovalTime: number;
  }> {
    try {
      // Initialize results
      const result = {
        totalCount: 0,
        byStatus: {} as Record<ContentStatus, number>,
        byType: {} as Record<ContentType, number>,
        averageApprovalTime: 0
      };
      
      // Initialize counters for each status and type
      Object.values(ContentStatus).forEach(status => {
        result.byStatus[status] = 0;
      });
      
      Object.values(ContentType).forEach(type => {
        result.byType[type] = 0;
      });
      
      // Build filter formula for date range if specified
      let filterFormula = '';
      if (fromDate && toDate) {
        const fromDateStr = fromDate.toISOString();
        const toDateStr = toDate.toISOString();
        filterFormula = `AND(
          IS_AFTER({createdAt}, '${fromDateStr}'),
          IS_BEFORE({createdAt}, '${toDateStr}')
        )`;
      }
      
      // Fetch all relevant content
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula
      });
      
      const contents = records.map(record => this.mapRecordToContent(record.fields));
      
      // Count total
      result.totalCount = contents.length;
      
      // Count by status and type
      contents.forEach(content => {
        if (content.status && result.byStatus[content.status] !== undefined) {
          result.byStatus[content.status]++;
        }
        
        if (content.type && result.byType[content.type] !== undefined) {
          result.byType[content.type]++;
        }
      });
      
      // Calculate average approval time for approved content
      const approvedContents = contents.filter(content => 
        content.status === ContentStatus.APPROVED && 
        content.feedbackHistory && 
        content.feedbackHistory.length > 0
      );
      
      if (approvedContents.length > 0) {
        let totalApprovalTime = 0;
        
        approvedContents.forEach(content => {
          const creationTime = content.createdAt?.getTime() || 0;
          
          // Find the approval feedback entry
          const approvalEntry = content.feedbackHistory?.find(entry => 
            entry.action === 'approve'
          );
          
          if (approvalEntry && approvalEntry.timestamp) {
            const approvalTime = new Date(approvalEntry.timestamp).getTime();
            const timeDiff = approvalTime - creationTime;
            
            // Only count if times are valid (positive difference)
            if (timeDiff > 0) {
              totalApprovalTime += timeDiff;
            }
          }
        });
        
        // Calculate average in milliseconds, then convert to hours
        result.averageApprovalTime = (totalApprovalTime / approvedContents.length) / (1000 * 60 * 60);
      }
      
      return result;
    } catch (error) {
      console.error('Error getting content analytics:', error);
      return {
        totalCount: 0,
        byStatus: {} as Record<ContentStatus, number>,
        byType: {} as Record<ContentType, number>,
        averageApprovalTime: 0
      };
    }
  }
}