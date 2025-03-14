/**
 * Enum for content status values
 */
export enum ContentStatus {
  DRAFT = 'draft',
  PENDING_APPROVAL = 'pending_approval',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  SCHEDULED = 'scheduled',
  PUBLISHED = 'published',
  ARCHIVED = 'archived'
}

/**
 * Enum for content type values
 */
export enum ContentType {
  JOB_POSTING = 'job_posting',
  PROMOTION = 'promotion',
  ANNOUNCEMENT = 'announcement',
  GENERAL = 'general'
}

/**
 * Interface for feedback history entries
 */
export interface FeedbackEntry {
  timestamp: Date;
  userId: string;
  message: string;
  action: 'approve' | 'reject' | 'revise';
}

/**
 * Interface for Content entity in the system
 */
export interface Content {
  /**
   * Unique identifier for the content
   */
  id?: string;
  
  /**
   * Associated brand ID
   */
  brandId: string;
  
  /**
   * Content type
   */
  type: ContentType;
  
  /**
   * Current status
   */
  status: ContentStatus;
  
  /**
   * Content title
   */
  title: string;
  
  /**
   * Content description
   */
  description?: string;
  
  /**
   * Raw unformatted text
   */
  rawText?: string;
  
  /**
   * Formatted text (may include HTML/markdown)
   */
  formattedText?: string;
  
  /**
   * Prompt used for image generation
   */
  imagePrompt?: string;
  
  /**
   * URL to the generated image
   */
  imageUrl?: string;
  
  /**
   * History of feedback received
   */
  feedbackHistory?: FeedbackEntry[];
  
  /**
   * Additional metadata as key-value pairs
   */
  metadata?: Record<string, any>;
  
  /**
   * List of distribution channels
   */
  distributionChannels?: string[];
  
  /**
   * Scheduled publication date
   */
  scheduledDate?: Date;
  
  /**
   * Actual publication date
   */
  publishedDate?: Date;
  
  /**
   * Creation timestamp
   */
  createdAt?: Date;
  
  /**
   * Last update timestamp
   */
  updatedAt?: Date;
}