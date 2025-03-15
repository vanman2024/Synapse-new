import { ContentController } from '../../api/controllers/ContentController';
import { Request, Response } from 'express';
import { ContentRepository } from '../../repositories/interfaces/ContentRepository';

describe('ContentController', () => {
  let contentController: ContentController;
  let mockContentRepository: jest.Mocked<ContentRepository>;
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let jsonSpy: jest.Mock;
  let statusSpy: jest.Mock;

  beforeEach(() => {
    jsonSpy = jest.fn();
    statusSpy = jest.fn().mockReturnValue({ json: jsonSpy, send: jest.fn() });
    
    mockRequest = {};
    mockResponse = {
      status: statusSpy,
      json: jsonSpy,
    };

    mockContentRepository = {
      findAll: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    } as jest.Mocked<ContentRepository>;

    contentController = new ContentController(mockContentRepository);
  });

  describe('getAll', () => {
    it('should return all content items with 200 status', async () => {
      const mockContent = [{ id: '1', title: 'Content 1' }, { id: '2', title: 'Content 2' }];
      mockContentRepository.findAll.mockResolvedValue(mockContent);

      await contentController.getAll(mockRequest as Request, mockResponse as Response);

      expect(mockContentRepository.findAll).toHaveBeenCalled();
      expect(statusSpy).toHaveBeenCalledWith(200);
      expect(jsonSpy).toHaveBeenCalledWith(mockContent);
    });

    it('should handle errors and return 500 status', async () => {
      mockContentRepository.findAll.mockRejectedValue(new Error('Database error'));

      await contentController.getAll(mockRequest as Request, mockResponse as Response);

      expect(statusSpy).toHaveBeenCalledWith(500);
      expect(jsonSpy).toHaveBeenCalledWith({ error: 'Failed to retrieve content items' });
    });
  });

  describe('getById', () => {
    beforeEach(() => {
      mockRequest = {
        params: { id: '1' }
      };
    });

    it('should return a content item with 200 status when found', async () => {
      const mockContent = { id: '1', title: 'Content 1' };
      mockContentRepository.findById.mockResolvedValue(mockContent);

      await contentController.getById(mockRequest as Request, mockResponse as Response);

      expect(mockContentRepository.findById).toHaveBeenCalledWith('1');
      expect(statusSpy).toHaveBeenCalledWith(200);
      expect(jsonSpy).toHaveBeenCalledWith(mockContent);
    });

    it('should return 404 when content item not found', async () => {
      mockContentRepository.findById.mockResolvedValue(null);

      await contentController.getById(mockRequest as Request, mockResponse as Response);

      expect(statusSpy).toHaveBeenCalledWith(404);
      expect(jsonSpy).toHaveBeenCalledWith({ error: 'Content not found' });
    });
  });

  describe('create', () => {
    beforeEach(() => {
      mockRequest = {
        body: { title: 'New Content' }
      };
    });

    it('should create a content item and return 201 status', async () => {
      const mockCreatedContent = { id: '1', title: 'New Content' };
      mockContentRepository.create.mockResolvedValue(mockCreatedContent);

      await contentController.create(mockRequest as Request, mockResponse as Response);

      expect(mockContentRepository.create).toHaveBeenCalledWith(mockRequest.body);
      expect(statusSpy).toHaveBeenCalledWith(201);
      expect(jsonSpy).toHaveBeenCalledWith(mockCreatedContent);
    });
  });

  describe('update', () => {
    beforeEach(() => {
      mockRequest = {
        params: { id: '1' },
        body: { title: 'Updated Content' }
      };
    });

    it('should update a content item and return 200 status', async () => {
      const mockUpdatedContent = { id: '1', title: 'Updated Content' };
      mockContentRepository.update.mockResolvedValue(mockUpdatedContent);

      await contentController.update(mockRequest as Request, mockResponse as Response);

      expect(mockContentRepository.update).toHaveBeenCalledWith('1', mockRequest.body);
      expect(statusSpy).toHaveBeenCalledWith(200);
      expect(jsonSpy).toHaveBeenCalledWith(mockUpdatedContent);
    });

    it('should return 404 when content item to update not found', async () => {
      mockContentRepository.update.mockResolvedValue(null);

      await contentController.update(mockRequest as Request, mockResponse as Response);

      expect(statusSpy).toHaveBeenCalledWith(404);
      expect(jsonSpy).toHaveBeenCalledWith({ error: 'Content not found' });
    });
  });

  describe('delete', () => {
    beforeEach(() => {
      mockRequest = {
        params: { id: '1' }
      };
    });

    it('should delete a content item and return 204 status', async () => {
      mockContentRepository.delete.mockResolvedValue(true);
      const sendSpy = jest.fn();
      mockResponse.send = sendSpy;

      await contentController.delete(mockRequest as Request, mockResponse as Response);

      expect(mockContentRepository.delete).toHaveBeenCalledWith('1');
      expect(statusSpy).toHaveBeenCalledWith(204);
      expect(sendSpy).toHaveBeenCalled();
    });

    it('should return 404 when content item to delete not found', async () => {
      mockContentRepository.delete.mockResolvedValue(false);

      await contentController.delete(mockRequest as Request, mockResponse as Response);

      expect(statusSpy).toHaveBeenCalledWith(404);
      expect(jsonSpy).toHaveBeenCalledWith({ error: 'Content not found' });
    });
  });
});