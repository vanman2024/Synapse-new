import { Content, ContentStatus, ContentType, FeedbackEntry } from '../models';
import { ContentRepository } from '../repositories/interfaces/ContentRepository';
import { AirtableContentRepository } from '../repositories/implementations/AirtableContentRepository';
import { OpenAIService } from './OpenAIService';
import { CloudinaryService } from './CloudinaryService';

/**
 * Service for managing content creation, generation, and lifecycle
 */
export class ContentService {
  private contentRepository: ContentRepository;
  private openAIService: OpenAIService;
  private cloudinaryService: CloudinaryService;

  /**
   * Constructor - initializes repositories and services
   */
  constructor() {
    this.contentRepository = new AirtableContentRepository();
    this.openAIService = new OpenAIService();
    this.cloudinaryService = new CloudinaryService();
  }

  /**
   * Create new content
   * @param content Content data to create
   * @returns A promise that resolves to the created content
   */
  public async createContent(content: Omit<Content, 'id' | 'createdAt' | 'updatedAt'>): Promise<Content> {
    try {
      // Set default values if not provided
      const contentToCreate: Omit<Content, 'id' | 'createdAt' | 'updatedAt'> = {
        ...content,
        status: content.status || ContentStatus.DRAFT,
        type: content.type || ContentType.GENERAL,
        feedbackHistory: content.feedbackHistory || [],
        distributionChannels: content.distributionChannels || []
      };

      return await this.contentRepository.create(contentToCreate);
    } catch (error) {
      console.error('Error creating content:', error);
      throw new Error('Failed to create content');
    }
  }

  /**
   * Get content by ID
   * @param id Content ID
   * @returns A promise that resolves to the content or null if not found
   */
  public async getContentById(id: string): Promise<Content | null> {
    try {
      return await this.contentRepository.findById(id);
    } catch (error) {
      console.error(`Error getting content with ID ${id}:`, error);
      return null;
    }
  }

  /**
   * Get all content with optional filtering
   * @param filter Optional filter criteria
   * @returns A promise that resolves to an array of content
   */
  public async getAllContent(filter?: Partial<Content>): Promise<Content[]> {
    try {
      return await this.contentRepository.findAll(filter);
    } catch (error) {
      console.error('Error getting all content:', error);
      return [];
    }
  }

  /**
   * Generate content from a job description
   * @param brandId The brand ID
   * @param jobTitle The job title
   * @param jobDescription The job description
   * @param industry The industry
   * @param location The location
   * @returns A promise that resolves to the generated content
   */
  public async generateJobContent(
    brandId: string,
    jobTitle: string,
    jobDescription: string,
    industry: string,
    location: string
  ): Promise<Content> {
    try {
      // Generate job description using OpenAI
      const jobData = await this.openAIService.generateJobDescription(
        jobTitle,
        industry,
        location,
        jobDescription.split('\n').filter(line => line.trim().length > 0)
      );

      // Generate social media post
      const socialData = await this.openAIService.generateJobPost(
        jobTitle,
        brandId, // Using brandId as company name for now
        location,
        [jobData.description.substring(0, 100) + '...']
      );

      // Create content object
      const content: Omit<Content, 'id' | 'createdAt' | 'updatedAt'> = {
        brandId,
        type: ContentType.JOB_POSTING,
        status: ContentStatus.DRAFT,
        title: `${jobTitle} - ${location}`,
        description: jobData.description,
        rawText: JSON.stringify(jobData),
        formattedText: `# ${jobTitle}\n\n${jobData.description}\n\n## Responsibilities\n${
          jobData.responsibilities.map(r => `- ${r}`).join('\n')
        }\n\n## Requirements\n${
          jobData.requirements.map(r => `- ${r}`).join('\n')
        }\n\n## Benefits\n${
          jobData.benefits.map(b => `- ${b}`).join('\n')
        }`,
        imagePrompt: `Professional image for ${jobTitle} position in ${industry}, ${location}`,
        metadata: {
          jobTitle,
          industry,
          location,
          socialText: socialData.longText,
          socialShortText: socialData.shortText,
          hashtags: socialData.hashtags
        }
      };

      // Create the content in the repository
      const createdContent = await this.contentRepository.create(content);

      // Generate an image for the content
      await this.contentRepository.generateImage(createdContent.id as string);

      // Get the updated content with the image
      const updatedContent = await this.contentRepository.findById(createdContent.id as string);
      
      return updatedContent || createdContent;
    } catch (error) {
      console.error('Error generating job content:', error);
      throw new Error('Failed to generate job content');
    }
  }

  /**
   * Update content status
   * @param contentId Content ID
   * @param status New status
   * @param feedback Optional feedback message
   * @param userId Optional user ID
   * @returns A promise that resolves to the updated content
   */
  public async updateStatus(
    contentId: string,
    status: ContentStatus,
    feedback?: string,
    userId?: string
  ): Promise<Content | null> {
    try {
      return await this.contentRepository.updateStatus(contentId, status, feedback, userId);
    } catch (error) {
      console.error(`Error updating status for content ${contentId}:`, error);
      return null;
    }
  }

  /**
   * Add feedback to content
   * @param contentId Content ID
   * @param feedback Feedback message
   * @param userId User ID
   * @param action Feedback action (approve, reject, revise)
   * @returns A promise that resolves to the updated content
   */
  public async addFeedback(
    contentId: string,
    feedback: string,
    userId: string,
    action: 'approve' | 'reject' | 'revise'
  ): Promise<Content | null> {
    try {
      // Get current content
      const content = await this.contentRepository.findById(contentId);
      if (!content) {
        return null;
      }

      // Create feedback entry
      const feedbackEntry: FeedbackEntry = {
        timestamp: new Date(),
        userId,
        message: feedback,
        action
      };

      // Update content with new feedback
      const updateData: Partial<Content> = {
        feedbackHistory: [
          ...(content.feedbackHistory || []),
          feedbackEntry
        ]
      };

      // Update status based on action if needed
      if (action === 'approve') {
        updateData.status = ContentStatus.APPROVED;
      } else if (action === 'reject') {
        updateData.status = ContentStatus.REJECTED;
      }

      return await this.contentRepository.update(contentId, updateData);
    } catch (error) {
      console.error(`Error adding feedback to content ${contentId}:`, error);
      return null;
    }
  }

  /**
   * Schedule content for publishing
   * @param contentId Content ID
   * @param scheduledDate Date to publish
   * @returns A promise that resolves to the updated content
   */
  public async scheduleContent(
    contentId: string,
    scheduledDate: Date
  ): Promise<Content | null> {
    try {
      // Ensure content is approved
      const content = await this.contentRepository.findById(contentId);
      if (!content) {
        return null;
      }

      if (content.status !== ContentStatus.APPROVED) {
        throw new Error('Only approved content can be scheduled');
      }

      // Update content with scheduled date and status
      return await this.contentRepository.update(contentId, {
        scheduledDate,
        status: ContentStatus.SCHEDULED
      });
    } catch (error) {
      console.error(`Error scheduling content ${contentId}:`, error);
      return null;
    }
  }

  /**
   * Generate new image for content
   * @param contentId Content ID
   * @param customPrompt Optional custom prompt
   * @returns A promise that resolves to the updated content
   */
  public async generateImage(
    contentId: string,
    customPrompt?: string
  ): Promise<Content | null> {
    try {
      return await this.contentRepository.generateImage(contentId, customPrompt);
    } catch (error) {
      console.error(`Error generating image for content ${contentId}:`, error);
      return null;
    }
  }

  /**
   * Get content analytics
   * @param fromDate Optional start date
   * @param toDate Optional end date
   * @returns A promise that resolves to analytics data
   */
  public async getAnalytics(fromDate?: Date, toDate?: Date): Promise<{
    totalCount: number;
    byStatus: Record<ContentStatus, number>;
    byType: Record<ContentType, number>;
    averageApprovalTime: number;
  }> {
    try {
      return await this.contentRepository.getAnalytics(fromDate, toDate);
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

  /**
   * Get content ready for publishing
   * @returns A promise that resolves to an array of scheduled content ready to publish
   */
  public async getContentReadyForPublishing(): Promise<Content[]> {
    try {
      // Get current date
      const now = new Date();
      
      // Get all scheduled content
      const scheduledContent = await this.contentRepository.findByStatus(ContentStatus.SCHEDULED);
      
      // Filter for content scheduled before now
      return scheduledContent.filter(content => 
        content.scheduledDate && content.scheduledDate.getTime() <= now.getTime()
      );
    } catch (error) {
      console.error('Error getting content ready for publishing:', error);
      return [];
    }
  }

  /**
   * Publish content
   * @param contentId Content ID
   * @returns A promise that resolves to the published content
   */
  public async publishContent(contentId: string): Promise<Content | null> {
    try {
      return await this.contentRepository.updateStatus(
        contentId,
        ContentStatus.PUBLISHED,
        'Content auto-published',
        'system'
      );
    } catch (error) {
      console.error(`Error publishing content ${contentId}:`, error);
      return null;
    }
  }

  /**
   * Generate new version of content with AI assistance
   * @param contentId Content ID to revise
   * @param instructions Instructions for the revision
   * @returns A promise that resolves to the new content version
   */
  public async generateContentRevision(
    contentId: string,
    instructions: string
  ): Promise<Content | null> {
    try {
      // Get original content
      const originalContent = await this.contentRepository.findById(contentId);
      if (!originalContent) {
        return null;
      }

      // Create prompt for revision
      let prompt = `Revise the following content based on these instructions: ${instructions}\n\n`;
      prompt += `Original content: ${originalContent.title}\n\n`;
      
      if (originalContent.description) {
        prompt += originalContent.description + '\n\n';
      }
      
      if (originalContent.rawText) {
        prompt += originalContent.rawText + '\n\n';
      } else if (originalContent.formattedText) {
        prompt += originalContent.formattedText;
      }

      // Generate revised text
      const revisedText = await this.openAIService.generateText(prompt, 1000, 0.7);

      // Create new content version with revision
      const newVersion: Omit<Content, 'id' | 'createdAt' | 'updatedAt'> = {
        ...originalContent,
        status: ContentStatus.DRAFT,
        rawText: revisedText,
        formattedText: revisedText,
        metadata: {
          ...originalContent.metadata,
          originalContentId: originalContent.id,
          revisionInstructions: instructions
        },
        feedbackHistory: []
      };

      // Create the new content version
      return await this.contentRepository.create(newVersion);
    } catch (error) {
      console.error(`Error generating content revision for ${contentId}:`, error);
      return null;
    }
  }
}