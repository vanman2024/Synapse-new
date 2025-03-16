/**
 * ContentAnalysisService Unit Tests
 */
import { ContentAnalysisService } from '../../../services/content-analysis/ContentAnalysisService';

describe('ContentAnalysisService', () => {
  let service: ContentAnalysisService;

  beforeEach(() => {
    service = new ContentAnalysisService();
  });

  describe('analyzeContent', () => {
    it('should analyze content and return insights', async () => {
      // Arrange
      const content = 'This is a test content about technology and innovation.';
      
      // Act
      const result = await service.analyzeContent(content);
      
      // Assert
      expect(result).toBeDefined();
      expect(result.sentiment).toBeDefined();
      expect(result.topics).toBeInstanceOf(Array);
      expect(result.recommendations).toBeInstanceOf(Array);
    });

    it('should return empty results for empty content', async () => {
      // Arrange
      const content = '';
      
      // Act
      const result = await service.analyzeContent(content);
      
      // Assert
      expect(result).toBeDefined();
      expect(result.sentiment).toBe('neutral');
      expect(result.topics).toEqual([]);
      expect(result.recommendations).toEqual(['Add content to analyze']);
    });
  });

  describe('estimateReadingTime', () => {
    it('should calculate reading time based on word count', () => {
      // Arrange
      const content = 'This is a test content with exactly ten words in it.';
      
      // Act
      const result = service.estimateReadingTime(content);
      
      // Assert - 10 words ÷ 200 wpm = 0.05 minutes (rounds to 1)
      expect(result).toBe(1);
    });

    it('should handle long content correctly', () => {
      // Arrange - create content with 500 words
      const words = Array(500).fill('word').join(' ');
      
      // Act
      const result = service.estimateReadingTime(words);
      
      // Assert - 500 words ÷ 200 wpm = 2.5 minutes (rounds to 3)
      expect(result).toBe(3);
    });

    it('should return 0 for empty content', () => {
      // Act
      const result = service.estimateReadingTime('');
      
      // Assert
      expect(result).toBe(0);
    });
  });

  describe('getSentimentScore', () => {
    it('should return a sentiment score between -1 and 1', () => {
      // Act
      const result = service.getSentimentScore('This is great content, I love it!');
      
      // Assert
      expect(result).toBeGreaterThanOrEqual(-1);
      expect(result).toBeLessThanOrEqual(1);
    });

    it('should return positive score for positive content', () => {
      // Act
      const result = service.getSentimentScore('This is excellent, amazing, and wonderful!');
      
      // Assert
      expect(result).toBeGreaterThan(0);
    });

    it('should return negative score for negative content', () => {
      // Act
      const result = service.getSentimentScore('This is terrible, horrible, and awful!');
      
      // Assert
      expect(result).toBeLessThan(0);
    });

    it('should return neutral score for neutral content', () => {
      // Act
      const result = service.getSentimentScore('This is a statement with neutral context about facts.');
      
      // Assert
      expect(result).toBeCloseTo(0, 1); // Within 0.1 of zero
    });
  });

  describe('extractKeywords', () => {
    it('should extract keywords from content', () => {
      // Act
      const result = service.extractKeywords('Artificial intelligence and machine learning are transforming content creation.');
      
      // Assert
      expect(result).toBeInstanceOf(Array);
      expect(result.length).toBeGreaterThan(0);
      expect(result).toContain('artificial intelligence');
      expect(result).toContain('machine learning');
      expect(result).toContain('content creation');
    });

    it('should return empty array for empty content', () => {
      // Act
      const result = service.extractKeywords('');
      
      // Assert
      expect(result).toEqual([]);
    });

    it('should filter out common stop words', () => {
      // Act
      const result = service.extractKeywords('The and of in are common stop words');
      
      // Assert
      expect(result).not.toContain('the');
      expect(result).not.toContain('and');
      expect(result).not.toContain('of');
      expect(result).not.toContain('in');
      expect(result).not.toContain('are');
      expect(result).toContain('common stop words');
    });
  });
});