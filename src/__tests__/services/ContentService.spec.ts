import { ContentService } from '../../services/ContentService';
import { AirtableContentRepository } from '../../repositories/implementations/AirtableContentRepository';
import { OpenAIService } from '../../services/OpenAIService';
import { CloudinaryService } from '../../services/CloudinaryService';
import { Content, ContentStatus, ContentType } from '../../models';

// Mock the dependencies
jest.mock('../../repositories/implementations/AirtableContentRepository');
jest.mock('../../services/OpenAIService');
jest.mock('../../services/CloudinaryService');

describe('ContentService', () => {
  let contentService: ContentService;
  let mockContentRepository: jest.Mocked<AirtableContentRepository>;
  let mockOpenAIService: jest.Mocked<OpenAIService>;
  let mockCloudinaryService: jest.Mocked<CloudinaryService>;

  // Sample content for testing
  const sampleContent: Content = {
    id: '123',
    brandId: 'brand123',
    type: ContentType.JOB_POSTING,
    status: ContentStatus.DRAFT,
    title: 'Test Job',
    description: 'This is a test job description',
    createdAt: new Date(),
    updatedAt: new Date()
  };

  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();

    // Setup mocks
    mockContentRepository = new AirtableContentRepository() as jest.Mocked<AirtableContentRepository>;
    mockOpenAIService = new OpenAIService() as jest.Mocked<OpenAIService>;
    mockCloudinaryService = new CloudinaryService() as jest.Mocked<CloudinaryService>;

    // Set up mock implementations
    (AirtableContentRepository as jest.Mock).mockImplementation(() => mockContentRepository);
    (OpenAIService as jest.Mock).mockImplementation(() => mockOpenAIService);
    (CloudinaryService as jest.Mock).mockImplementation(() => mockCloudinaryService);

    // Create service instance
    contentService = new ContentService();
  });

  describe('createContent', () => {
    it('should create content with default values', async () => {
      // Setup mock
      mockContentRepository.create = jest.fn().mockResolvedValue(sampleContent);

      // Call the method
      const result = await contentService.createContent({
        brandId: 'brand123',
        title: 'Test Job',
        type: ContentType.JOB_POSTING,
        status: ContentStatus.DRAFT
      });

      // Assertions
      expect(mockContentRepository.create).toHaveBeenCalledTimes(1);
      expect(result).toEqual(sampleContent);
    });

    it('should handle errors when creating content', async () => {
      // Setup mock to throw an error
      mockContentRepository.create = jest.fn().mockRejectedValue(new Error('Test error'));

      // Assertions
      await expect(contentService.createContent({
        brandId: 'brand123',
        title: 'Test Job',
        type: ContentType.JOB_POSTING,
        status: ContentStatus.DRAFT
      })).rejects.toThrow('Failed to create content');
    });
  });

  describe('getContentById', () => {
    it('should return content by id', async () => {
      // Setup mock
      mockContentRepository.findById = jest.fn().mockResolvedValue(sampleContent);

      // Call the method
      const result = await contentService.getContentById('123');

      // Assertions
      expect(mockContentRepository.findById).toHaveBeenCalledWith('123');
      expect(result).toEqual(sampleContent);
    });

    it('should return null if content not found', async () => {
      // Setup mock
      mockContentRepository.findById = jest.fn().mockResolvedValue(null);

      // Call the method
      const result = await contentService.getContentById('123');

      // Assertions
      expect(result).toBeNull();
    });

    it('should handle errors when getting content by id', async () => {
      // Setup mock to throw an error
      mockContentRepository.findById = jest.fn().mockRejectedValue(new Error('Test error'));

      // Call the method
      const result = await contentService.getContentById('123');

      // Assertions
      expect(result).toBeNull();
    });
  });

  describe('generateJobContent', () => {
    it('should generate job content', async () => {
      // Setup mocks
      const jobData = {
        description: 'Job description',
        responsibilities: ['Responsibility 1'],
        requirements: ['Requirement 1'],
        benefits: ['Benefit 1']
      };

      const socialData = {
        shortText: 'Short text',
        longText: 'Long text',
        hashtags: ['job', 'hiring']
      };

      mockOpenAIService.generateJobDescription = jest.fn().mockResolvedValue(jobData);
      mockOpenAIService.generateJobPost = jest.fn().mockResolvedValue(socialData);
      mockContentRepository.create = jest.fn().mockResolvedValue({
        ...sampleContent,
        id: '123'
      });
      mockContentRepository.generateImage = jest.fn().mockResolvedValue(sampleContent);
      mockContentRepository.findById = jest.fn().mockResolvedValue({
        ...sampleContent,
        imageUrl: 'https://example.com/image.jpg'
      });

      // Call the method
      const result = await contentService.generateJobContent(
        'brand123',
        'Test Job',
        'Job description',
        'Technology',
        'Remote'
      );

      // Assertions
      expect(mockOpenAIService.generateJobDescription).toHaveBeenCalledTimes(1);
      expect(mockOpenAIService.generateJobPost).toHaveBeenCalledTimes(1);
      expect(mockContentRepository.create).toHaveBeenCalledTimes(1);
      expect(mockContentRepository.generateImage).toHaveBeenCalledTimes(1);
      expect(mockContentRepository.findById).toHaveBeenCalledTimes(1);
      expect(result).toHaveProperty('imageUrl', 'https://example.com/image.jpg');
    });
  });

  describe('updateStatus', () => {
    it('should update content status', async () => {
      // Setup mock
      mockContentRepository.updateStatus = jest.fn().mockResolvedValue({
        ...sampleContent,
        status: ContentStatus.APPROVED
      });

      // Call the method
      const result = await contentService.updateStatus(
        '123',
        ContentStatus.APPROVED,
        'Looks good',
        'user123'
      );

      // Assertions
      expect(mockContentRepository.updateStatus).toHaveBeenCalledWith(
        '123',
        ContentStatus.APPROVED,
        'Looks good',
        'user123'
      );
      expect(result).toHaveProperty('status', ContentStatus.APPROVED);
    });
  });

  describe('getContentReadyForPublishing', () => {
    it('should return content ready for publishing', async () => {
      const now = new Date();
      const pastDate = new Date(now.getTime() - 1000 * 60 * 60); // 1 hour ago
      
      const scheduledContent = [
        {
          ...sampleContent,
          status: ContentStatus.SCHEDULED,
          scheduledDate: pastDate
        },
        {
          ...sampleContent,
          id: '456',
          status: ContentStatus.SCHEDULED,
          scheduledDate: new Date(now.getTime() + 1000 * 60 * 60) // 1 hour in future
        }
      ];

      // Setup mock
      mockContentRepository.findByStatus = jest.fn().mockResolvedValue(scheduledContent);

      // Call the method
      const result = await contentService.getContentReadyForPublishing();

      // Assertions
      expect(mockContentRepository.findByStatus).toHaveBeenCalledWith(ContentStatus.SCHEDULED);
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('123');
    });
  });
});