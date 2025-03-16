import { Router } from 'express';
import { ContentController } from '../controllers/ContentController';
import { container } from '../../config';
import { TYPES } from '../../types';

const contentRouter = Router();
const contentController = container.get<ContentController>(TYPES.ContentController);

// Get all content items
contentRouter.get('/', contentController.getAll);

// Get content by ID
contentRouter.get('/:id', contentController.getById);

// Analyze content
contentRouter.get('/:id/analyze', contentController.analyzeContent);

// Extract keywords from content
contentRouter.get('/:id/keywords', contentController.extractKeywords);

// Create new content
contentRouter.post('/', contentController.create);

// Update content
contentRouter.put('/:id', contentController.update);

// Delete content
contentRouter.delete('/:id', contentController.delete);

export default contentRouter;