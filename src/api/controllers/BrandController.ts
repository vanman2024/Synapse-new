import { Request, Response } from 'express';
import { AirtableBrandRepository } from '../../repositories/implementations';
import { Brand } from '../../models';
import * as Joi from 'joi';

/**
 * Controller for brand-related API endpoints
 */
export class BrandController {
  private brandRepository: AirtableBrandRepository;

  /**
   * Constructor
   */
  constructor() {
    this.brandRepository = new AirtableBrandRepository();
  }

  /**
   * Get all brands
   * @param req Express request
   * @param res Express response
   */
  public getAllBrands = async (req: Request, res: Response): Promise<void> => {
    try {
      const brands = await this.brandRepository.findAll();
      res.status(200).json({ success: true, data: brands });
    } catch (error) {
      console.error('Error getting all brands:', error);
      res.status(500).json({ success: false, error: 'Failed to get brands' });
    }
  };

  /**
   * Get a brand by ID
   * @param req Express request
   * @param res Express response
   */
  public getBrandById = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      const brand = await this.brandRepository.findById(id);

      if (!brand) {
        res.status(404).json({ success: false, error: 'Brand not found' });
        return;
      }

      res.status(200).json({ success: true, data: brand });
    } catch (error) {
      console.error(`Error getting brand with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to get brand' });
    }
  };

  /**
   * Create a new brand
   * @param req Express request
   * @param res Express response
   */
  public createBrand = async (req: Request, res: Response): Promise<void> => {
    try {
      // Validate request body
      const schema = Joi.object({
        name: Joi.string().required(),
        description: Joi.string(),
        websiteUrl: Joi.string().uri(),
        website: Joi.string().uri(), // Support legacy field
        logoUrl: Joi.string().uri(),
        colors: Joi.object({
          primary: Joi.string(),
          secondary: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          ),
          accent: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          ),
          text: Joi.string(),
          background: Joi.string()
        }),
        fonts: Joi.object({
          primary: Joi.string(),
          secondary: Joi.string(),
          headings: Joi.string(),
          body: Joi.string()
        }),
        typography: Joi.object({
          headingFont: Joi.string(),
          bodyFont: Joi.string(),
          fontSize: Joi.object({
            heading: Joi.number(),
            subheading: Joi.number(),
            body: Joi.number()
          })
        }),
        logos: Joi.object({
          main: Joi.string(),
          alternate: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          )
        }),
        style: Joi.object({
          imageStyle: Joi.string(),
          textStyle: Joi.string(),
          layoutPreferences: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          )
        }),
        socialMedia: Joi.object({
          facebook: Joi.string(),
          instagram: Joi.string(),
          twitter: Joi.string(),
          linkedin: Joi.string(),
          youtube: Joi.string(),
          tiktok: Joi.string()
        }),
        industry: Joi.string(),
        targetAudience: Joi.array().items(Joi.string()),
        toneOfVoice: Joi.string(),
        keyMessages: Joi.array().items(Joi.string())
      });

      const { error, value } = schema.validate(req.body);

      if (error) {
        res.status(400).json({ success: false, error: error.details[0].message });
        return;
      }

      // Check if brand with same name already exists
      const existingBrand = await this.brandRepository.findByName(value.name);

      if (existingBrand) {
        res.status(409).json({ success: false, error: 'Brand with this name already exists' });
        return;
      }

      // Create brand
      const brand = await this.brandRepository.create(value as Omit<Brand, 'id' | 'createdAt' | 'updatedAt'>);

      res.status(201).json({ success: true, data: brand });
    } catch (error) {
      console.error('Error creating brand:', error);
      res.status(500).json({ success: false, error: 'Failed to create brand' });
    }
  };

  /**
   * Update a brand
   * @param req Express request
   * @param res Express response
   */
  public updateBrand = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      // Validate request body
      const schema = Joi.object({
        name: Joi.string(),
        description: Joi.string(),
        websiteUrl: Joi.string().uri(),
        website: Joi.string().uri(), // Support legacy field
        logoUrl: Joi.string().uri(),
        colors: Joi.object({
          primary: Joi.string(),
          secondary: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          ),
          accent: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          ),
          text: Joi.string(),
          background: Joi.string()
        }),
        fonts: Joi.object({
          primary: Joi.string(),
          secondary: Joi.string(),
          headings: Joi.string(),
          body: Joi.string()
        }),
        typography: Joi.object({
          headingFont: Joi.string(),
          bodyFont: Joi.string(),
          fontSize: Joi.object({
            heading: Joi.number(),
            subheading: Joi.number(),
            body: Joi.number()
          })
        }),
        logos: Joi.object({
          main: Joi.string(),
          alternate: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          )
        }),
        style: Joi.object({
          imageStyle: Joi.string(),
          textStyle: Joi.string(),
          layoutPreferences: Joi.alternatives().try(
            Joi.array().items(Joi.string()),
            Joi.string()
          )
        }),
        socialMedia: Joi.object({
          facebook: Joi.string(),
          instagram: Joi.string(),
          twitter: Joi.string(),
          linkedin: Joi.string(),
          youtube: Joi.string(),
          tiktok: Joi.string()
        }),
        industry: Joi.string(),
        targetAudience: Joi.array().items(Joi.string()),
        toneOfVoice: Joi.string(),
        keyMessages: Joi.array().items(Joi.string())
      });

      const { error, value } = schema.validate(req.body);

      if (error) {
        res.status(400).json({ success: false, error: error.details[0].message });
        return;
      }

      // Check if brand exists
      const existingBrand = await this.brandRepository.findById(id);

      if (!existingBrand) {
        res.status(404).json({ success: false, error: 'Brand not found' });
        return;
      }

      // Check if trying to update name to an existing name
      if (value.name && value.name !== existingBrand.name) {
        const brandWithSameName = await this.brandRepository.findByName(value.name);

        if (brandWithSameName && brandWithSameName.id !== id) {
          res.status(409).json({ success: false, error: 'Brand with this name already exists' });
          return;
        }
      }

      // Update brand
      const updatedBrand = await this.brandRepository.update(id, value);

      if (!updatedBrand) {
        res.status(500).json({ success: false, error: 'Failed to update brand' });
        return;
      }

      res.status(200).json({ success: true, data: updatedBrand });
    } catch (error) {
      console.error(`Error updating brand with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to update brand' });
    }
  };

  /**
   * Delete a brand
   * @param req Express request
   * @param res Express response
   */
  public deleteBrand = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      // Check if brand exists
      const existingBrand = await this.brandRepository.findById(id);

      if (!existingBrand) {
        res.status(404).json({ success: false, error: 'Brand not found' });
        return;
      }

      // Delete brand
      const deleted = await this.brandRepository.delete(id);

      if (!deleted) {
        res.status(500).json({ success: false, error: 'Failed to delete brand' });
        return;
      }

      res.status(200).json({ success: true, data: { message: 'Brand deleted successfully' } });
    } catch (error) {
      console.error(`Error deleting brand with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to delete brand' });
    }
  };

  /**
   * Extract brand style from website
   * @param req Express request
   * @param res Express response
   */
  public extractStyleFromWebsite = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      const { websiteUrl } = req.body;

      // Validate request body
      if (!websiteUrl) {
        res.status(400).json({ success: false, error: 'Website URL is required' });
        return;
      }

      // Check if brand exists
      const existingBrand = await this.brandRepository.findById(id);

      if (!existingBrand) {
        res.status(404).json({ success: false, error: 'Brand not found' });
        return;
      }

      // Extract style from website
      const updatedBrand = await this.brandRepository.extractStyleFromWebsite(id, websiteUrl);

      if (!updatedBrand) {
        res.status(500).json({ success: false, error: 'Failed to extract style from website' });
        return;
      }

      res.status(200).json({ success: true, data: updatedBrand });
    } catch (error) {
      console.error(`Error extracting style for brand with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to extract style from website' });
    }
  };

  /**
   * Get brands with content count
   * @param req Express request
   * @param res Express response
   */
  public getBrandsWithContentCount = async (req: Request, res: Response): Promise<void> => {
    try {
      const brands = await this.brandRepository.getBrandsWithContentCount();
      res.status(200).json({ success: true, data: brands });
    } catch (error) {
      console.error('Error getting brands with content count:', error);
      res.status(500).json({ success: false, error: 'Failed to get brands with content count' });
    }
  };

  /**
   * Upload a brand logo
   * @param req Express request
   * @param res Express response
   */
  public uploadLogo = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      
      // Check if logo file exists in request
      if (!req.file) {
        res.status(400).json({ success: false, error: 'Logo file is required' });
        return;
      }
      
      // Check if brand exists
      const existingBrand = await this.brandRepository.findById(id);
      
      if (!existingBrand) {
        res.status(404).json({ success: false, error: 'Brand not found' });
        return;
      }
      
      // Upload logo
      const logoBuffer = req.file.buffer;
      const updatedBrand = await this.brandRepository.uploadLogo(id, logoBuffer);
      
      if (!updatedBrand) {
        res.status(500).json({ success: false, error: 'Failed to upload logo' });
        return;
      }
      
      res.status(200).json({ success: true, data: updatedBrand });
    } catch (error) {
      console.error(`Error uploading logo for brand with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to upload logo' });
    }
  };
}