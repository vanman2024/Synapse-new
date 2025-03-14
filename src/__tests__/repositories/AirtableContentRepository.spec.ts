import { AirtableContentRepository } from '../../repositories/implementations';
import { Content, ContentStatus, ContentType } from '../../models';

// Use a plain class mock with manual implementation rather than mocking dependencies
jest.mock('../../repositories/implementations/AirtableContentRepository');

describe('AirtableContentRepository', () => {
  let repository: jest.Mocked<AirtableContentRepository>;
  
  // Sample content for testing
  const sampleContent: Content = {
    id: 'rec123456',
    brandId: 'recBrand123',
    type: ContentType.JOB_POSTING,
    status: ContentStatus.DRAFT,
    title: 'Sample Job Posting',
    description: 'This is a sample job posting for testing',
    rawText: 'Raw text content',
    formattedText: '<p>Formatted text content</p>',
    imagePrompt: 'A professional office setting',
    imageUrl: 'https://example.com/image.jpg',
    feedbackHistory: [],
    distributionChannels: ['linkedin'],
    createdAt: new Date('2025-03-14T00:00:00Z'),
    updatedAt: new Date('2025-03-14T00:00:00Z')
  };

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    
    // Set up repository mock
    repository = new AirtableContentRepository() as jest.Mocked<AirtableContentRepository>;
  });

  describe('findById', () => {
    it('should find content by ID', async () => {
      // Set up mock implementation
      repository.findById.mockResolvedValue(sampleContent);
      
      // Execute
      const result = await repository.findById('rec123456');
      
      // Verify
      expect(repository.findById).toHaveBeenCalledWith('rec123456');
      expect(result).toEqual(expect.objectContaining({
        id: 'rec123456',
        title: 'Sample Job Posting'
      }));
    });
    
    it('should handle errors and return null', async () => {
      // Set up mock to return null
      repository.findById.mockResolvedValue(null);
      
      // Execute
      const result = await repository.findById('nonexistent');
      
      // Verify
      expect(result).toBeNull();
    });
  });

  describe('findAll', () => {
    it('should find all content', async () => {
      // Set up mock
      repository.findAll.mockResolvedValue([sampleContent]);
      
      // Execute
      const result = await repository.findAll();
      
      // Verify
      expect(repository.findAll).toHaveBeenCalled();
      expect(result).toHaveLength(1);
      expect(result[0]).toEqual(expect.objectContaining({
        id: 'rec123456',
        title: 'Sample Job Posting'
      }));
    });
    
    it('should apply filters when provided', async () => {
      // Set up mock
      repository.findAll.mockResolvedValue([sampleContent]);
      
      // Execute
      await repository.findAll({ status: ContentStatus.DRAFT });
      
      // Verify
      expect(repository.findAll).toHaveBeenCalledWith({ status: ContentStatus.DRAFT });
    });
  });

  describe('create', () => {
    it('should create new content', async () => {
      // Set up mock
      repository.create.mockResolvedValue(sampleContent);
      
      // New content without ID and timestamps
      const newContent: Omit<Content, 'id' | 'createdAt' | 'updatedAt'> = {
        brandId: 'recBrand123',
        type: ContentType.JOB_POSTING,
        status: ContentStatus.DRAFT,
        title: 'New Job Posting',
        description: 'This is a new job posting'
      };
      
      // Execute
      const result = await repository.create(newContent);
      
      // Verify
      expect(repository.create).toHaveBeenCalledWith(newContent);
      expect(result).toBeDefined();
      expect(result.id).toBe('rec123456');
    });
  });

  describe('updateStatus', () => {
    it('should update content status and add feedback', async () => {
      // Setup mock with updated content
      const updatedContent: Content = {
        ...sampleContent,
        status: ContentStatus.APPROVED,
        feedbackHistory: [{
          timestamp: new Date(),
          userId: 'user123',
          message: 'Looks good!',
          action: 'approve'
        }]
      };
      
      repository.updateStatus.mockResolvedValue(updatedContent);
      
      // Execute
      const result = await repository.updateStatus(
        'rec123456',
        ContentStatus.APPROVED,
        'Looks good!',
        'user123'
      );
      
      // Verify
      expect(repository.updateStatus).toHaveBeenCalledWith(
        'rec123456',
        ContentStatus.APPROVED,
        'Looks good!',
        'user123'
      );
      expect(result).toBeDefined();
      expect(result?.status).toBe(ContentStatus.APPROVED);
      expect(result?.feedbackHistory).toHaveLength(1);
    });
  });
  
  // Additional tests for other methods could be added here
});