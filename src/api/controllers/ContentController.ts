import { Request, Response } from 'express';
import { ContentRepository } from '../../repositories/interfaces/ContentRepository';
import { injectable, inject } from 'inversify';
import { TYPES } from '../../types';

@injectable()
export class ContentController {
  private readonly contentRepository: ContentRepository;

  constructor(
    @inject(TYPES.ContentRepository) contentRepository: ContentRepository
  ) {
    this.contentRepository = contentRepository;
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
}