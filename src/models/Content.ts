export enum ContentStatus {
  DRAFT = 'draft',
  PENDING_APPROVAL = 'pending_approval',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  SCHEDULED = 'scheduled',
  PUBLISHED = 'published',
  ARCHIVED = 'archived'
}

export enum ContentType {
  JOB_POSTING = 'job_posting',
  PROMOTION = 'promotion',
  ANNOUNCEMENT = 'announcement',
  GENERAL = 'general'
}

export interface Content {
  id?: string;
  brandId: string;
  type: ContentType;
  status: ContentStatus;
  title: string;
  description?: string;
  rawText?: string;
  formattedText?: string;
  imagePrompt?: string;
  imageUrl?: string;
  feedbackHistory?: {
    timestamp: Date;
    userId: string;
    message: string;
    action: 'approve' | 'reject' | 'revise';
  }[];
  metadata?: Record<string, any>;
  distributionChannels?: string[];
  scheduledDate?: Date;
  publishedDate?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}