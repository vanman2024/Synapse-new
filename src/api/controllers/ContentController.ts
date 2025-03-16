import { Request, Response } from 'express';
import { ContentRepository } from '../../repositories/interfaces/ContentRepository';
import { injectable, inject } from 'inversify';
import { TYPES } from '../../types';
import { ContentService } from '../../services/ContentService';

@injectable()
export class ContentController {
  private readonly contentRepository: ContentRepository;
  private readonly contentService: ContentService;

  constructor(
    @inject(TYPES.ContentRepository) contentRepository: ContentRepository
  ) {
    this.contentRepository = contentRepository;
    this.contentService = new ContentService();
  }

  /**
   * Get all content items
   */
  public getAll = async (req: Request, res: Response): Promise<void> => {
    try {
      const content = await this.contentRepository.findAll();
      res.status(200).json(content);
    } catch (error) {
      console.error('Error getting content:', error);
      res.status(500).json({ error: 'Failed to retrieve content items' });
    }
  };

  /**
   * Get content by ID
   */
  public getById = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      const content = await this.contentRepository.findById(id);
      
      if (!content) {
        res.status(404).json({ error: 'Content not found' });
        return;
      }
      
      res.status(200).json(content);
    } catch (error) {
      console.error('Error getting content by ID:', error);
      res.status(500).json({ error: 'Failed to retrieve content item' });
    }
  };

  /**
   * Create new content item
   */
  public create = async (req: Request, res: Response): Promise<void> => {
    try {
      const content = await this.contentRepository.create(req.body);
      res.status(201).json(content);
    } catch (error) {
      console.error('Error creating content:', error);
      res.status(500).json({ error: 'Failed to create content item' });
    }
  };

  /**
   * Update content item
   */
  public update = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      const updatedContent = await this.contentRepository.update(id, req.body);
      
      if (!updatedContent) {
        res.status(404).json({ error: 'Content not found' });
        return;
      }
      
      res.status(200).json(updatedContent);
    } catch (error) {
      console.error('Error updating content:', error);
      res.status(500).json({ error: 'Failed to update content item' });
    }
  };

  /**
   * Delete content item
   */
  public delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      const deleted = await this.contentRepository.delete(id);
      
      if (!deleted) {
        res.status(404).json({ error: 'Content not found' });
        return;
      }
      
      res.status(204).send();
    } catch (error) {
      console.error('Error deleting content:', error);
      res.status(500).json({ error: 'Failed to delete content item' });
    }
  };
  
  /**
   * Analyze content and return insights
   */
  public analyzeContent = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      
      // Call content service to analyze
      const result = await this.contentService.analyzeContent(id);
      
      res.status(200).json(result);
    } catch (error) {
      console.error('Error analyzing content:', error);
      res.status(500).json({ 
        error: 'Failed to analyze content',
        message: error instanceof Error ? error.message : 'Unknown error' 
      });
    }
  };
  
  /**
   * Extract keywords from content
   */
  public extractKeywords = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      
      // Call content service to extract keywords
      const keywords = await this.contentService.extractKeywords(id);
      
      res.status(200).json({ keywords });
    } catch (error) {
      console.error('Error extracting keywords:', error);
      res.status(500).json({ 
        error: 'Failed to extract keywords',
        message: error instanceof Error ? error.message : 'Unknown error' 
      });
    }
  };
}