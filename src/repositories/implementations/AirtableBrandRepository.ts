import { FieldSet } from 'airtable/lib/field_set';
import { Brand } from '../../models';
import { BrandRepository } from '../interfaces/BrandRepository';
import { AirtableClient } from '../../data-sources/airtable/AirtableClient';
import config from '../../config';
import axios from 'axios';
import { CloudinaryService } from '../../services/CloudinaryService';

/**
 * Airtable implementation of the Brand repository
 */
export class AirtableBrandRepository implements BrandRepository {
  private readonly airtable: AirtableClient;
  private readonly tableName: string;
  private readonly cloudinary: CloudinaryService;

  /**
   * Constructor
   */
  constructor() {
    this.airtable = AirtableClient.getInstance();
    this.tableName = config.AIRTABLE.TABLES.COMPANY;
    this.cloudinary = new CloudinaryService();
  }

  /**
   * Convert an Airtable record to a Brand object
   * @param record The Airtable record
   * @returns A Brand object
   */
  private mapRecordToBrand(record: Record<string, any>): Brand {
    return {
      id: record.id,
      name: record.Name,
      description: record.Description,
      websiteUrl: record.Website, // Primary field
      website: record.Website, // Legacy field (same as websiteUrl)
      logoUrl: record.LogoUrl,
      colors: {
        primary: record.PrimaryColor,
        secondary: record.SecondaryColors ? record.SecondaryColors.split(',').map((c: string) => c.trim()) : [],
        accent: record.AccentColors ? record.AccentColors.split(',').map((c: string) => c.trim()) : [],
        text: record.TextColor,
        background: record.BackgroundColor
      },
      fonts: record.Fonts ? {
        primary: record.Fonts.primary,
        secondary: record.Fonts.secondary,
        headings: record.Fonts.headings,
        body: record.Fonts.body
      } : undefined,
      typography: {
        headingFont: record.HeadingFont,
        bodyFont: record.BodyFont,
        fontSize: record.FontSizes ? {
          heading: Number(record.FontSizes.heading || 36),
          subheading: Number(record.FontSizes.subheading || 24),
          body: Number(record.FontSizes.body || 16)
        } : undefined
      },
      logos: {
        main: record.MainLogo,
        alternate: record.AlternateLogos || []
      },
      style: {
        imageStyle: record.ImageStyle,
        textStyle: record.TextStyle,
        layoutPreferences: record.LayoutPreferences || []
      },
      socialMedia: record.SocialMedia,
      industry: record.Industry,
      targetAudience: record.TargetAudience,
      toneOfVoice: record.ToneOfVoice,
      keyMessages: record.KeyMessages,
      createdAt: new Date(record.CreatedAt || record._createdTime),
      updatedAt: new Date(record.UpdatedAt || record._updatedTime)
    };
  }

  /**
   * Convert a Brand object to an Airtable record
   * @param brand The Brand object
   * @returns An Airtable record
   */
  private mapBrandToRecord(brand: Partial<Brand>): Partial<FieldSet> {
    const record: Partial<FieldSet> = {};

    if (brand.name) record.Name = brand.name;
    if (brand.description) record.Description = brand.description;
    
    // Handle both website and websiteUrl (preferring websiteUrl if both exist)
    if (brand.websiteUrl) {
      record.Website = brand.websiteUrl;
    } else if (brand.website) {
      record.Website = brand.website;
    }
    
    if (brand.logoUrl) record.LogoUrl = brand.logoUrl;

    if (brand.colors) {
      if (brand.colors.primary) record.PrimaryColor = brand.colors.primary;
      
      if (brand.colors.secondary) {
        if (Array.isArray(brand.colors.secondary)) {
          record.SecondaryColors = brand.colors.secondary.join(', ');
        } else {
          record.SecondaryColors = brand.colors.secondary;
        }
      }
      
      if (brand.colors.accent) {
        if (Array.isArray(brand.colors.accent)) {
          record.AccentColors = brand.colors.accent.join(', ');
        } else {
          record.AccentColors = brand.colors.accent;
        }
      }
      
      if (brand.colors.text) record.TextColor = brand.colors.text;
      if (brand.colors.background) record.BackgroundColor = brand.colors.background;
    }

    if (brand.fonts) {
      record.Fonts = {
        primary: brand.fonts.primary,
        secondary: brand.fonts.secondary,
        headings: brand.fonts.headings,
        body: brand.fonts.body
      } as any; // Cast to any to avoid FieldSet type issues
    }

    if (brand.typography) {
      if (brand.typography.headingFont) record.HeadingFont = brand.typography.headingFont;
      if (brand.typography.bodyFont) record.BodyFont = brand.typography.bodyFont;
      if (brand.typography.fontSize) {
        record.FontSizes = {
          heading: brand.typography.fontSize.heading,
          subheading: brand.typography.fontSize.subheading,
          body: brand.typography.fontSize.body
        } as any; // Cast to any to avoid FieldSet type issues
      }
    }

    if (brand.logos) {
      if (brand.logos.main) record.MainLogo = brand.logos.main;
      if (brand.logos.alternate) {
        if (Array.isArray(brand.logos.alternate)) {
          record.AlternateLogos = brand.logos.alternate;
        } else {
          record.AlternateLogos = [brand.logos.alternate];
        }
      }
    }

    if (brand.style) {
      if (brand.style.imageStyle) record.ImageStyle = brand.style.imageStyle;
      if (brand.style.textStyle) record.TextStyle = brand.style.textStyle;
      if (brand.style.layoutPreferences) {
        if (Array.isArray(brand.style.layoutPreferences)) {
          record.LayoutPreferences = brand.style.layoutPreferences;
        } else {
          record.LayoutPreferences = [brand.style.layoutPreferences];
        }
      }
    }
    
    if (brand.socialMedia) record.SocialMedia = brand.socialMedia as any;
    if (brand.industry) record.Industry = brand.industry;
    if (brand.targetAudience) record.TargetAudience = brand.targetAudience;
    if (brand.toneOfVoice) record.ToneOfVoice = brand.toneOfVoice;
    if (brand.keyMessages) record.KeyMessages = brand.keyMessages;

    record.UpdatedAt = new Date().toISOString();

    return record;
  }

  /**
   * Find a brand by its ID
   * @param id The brand ID
   * @returns A promise that resolves to the brand or null if not found
   */
  public async findById(id: string): Promise<Brand | null> {
    try {
      const record = await this.airtable.findById(this.tableName, id);
      return this.mapRecordToBrand({ id: record.id, ...record.fields });
    } catch (error) {
      console.error('Error finding brand by ID:', error);
      return null;
    }
  }

  /**
   * Find all brands that match the given filter criteria
   * @param filter Optional filter criteria
   * @returns A promise that resolves to an array of brands
   */
  public async findAll(filter?: Partial<Brand>): Promise<Brand[]> {
    try {
      // Build filter formula if filter is provided
      let filterFormula = '';

      if (filter) {
        const conditions = [];

        if (filter.name) {
          conditions.push(`{Name} = "${filter.name}"`);
        }

        if (filter.style?.imageStyle) {
          conditions.push(`{ImageStyle} = "${filter.style.imageStyle}"`);
        }

        if (conditions.length > 0) {
          filterFormula = `AND(${conditions.join(', ')})`;
        }
      }

      // Get records from Airtable
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula || '',
        sort: [{ field: 'Name', direction: 'asc' }]
      });

      // Map records to Brand objects
      return records.map(record => this.mapRecordToBrand({ id: record.id, ...record.fields }));
    } catch (error) {
      console.error('Error finding brands:', error);
      return [];
    }
  }

  /**
   * Create a new brand
   * @param brand The brand data
   * @returns A promise that resolves to the created brand
   */
  public async create(brand: Omit<Brand, 'id' | 'createdAt' | 'updatedAt'>): Promise<Brand> {
    try {
      // Map brand to Airtable record
      const record = this.mapBrandToRecord(brand);

      // Add created date
      record.CreatedAt = new Date().toISOString();
      record.UpdatedAt = record.CreatedAt;

      // Create record in Airtable
      const createdRecord = await this.airtable.create(this.tableName, record);

      // Return created brand
      return this.mapRecordToBrand({ id: createdRecord.id, ...createdRecord.fields });
    } catch (error) {
      console.error('Error creating brand:', error);
      throw error;
    }
  }

  /**
   * Update an existing brand
   * @param id The brand ID
   * @param brand The brand data to update
   * @returns A promise that resolves to the updated brand
   */
  public async update(id: string, brand: Partial<Brand>): Promise<Brand | null> {
    try {
      // Check if brand exists
      const existingBrand = await this.findById(id);

      if (!existingBrand) {
        return null;
      }

      // Map brand to Airtable record
      const record = this.mapBrandToRecord(brand);

      // Update record in Airtable
      const updatedRecord = await this.airtable.update(this.tableName, id, record);

      // Return updated brand
      return this.mapRecordToBrand({ id: updatedRecord.id, ...updatedRecord.fields });
    } catch (error) {
      console.error(`Error updating brand ${id}:`, error);
      return null;
    }
  }

  /**
   * Delete a brand
   * @param id The brand ID
   * @returns A promise that resolves to true if deleted, false otherwise
   */
  public async delete(id: string): Promise<boolean> {
    try {
      await this.airtable.delete(this.tableName, id);
      return true;
    } catch (error) {
      console.error(`Error deleting brand ${id}:`, error);
      return false;
    }
  }

  /**
   * Find a brand by its name
   * @param name The brand name
   * @returns A promise that resolves to the brand or null if not found
   */
  public async findByName(name: string): Promise<Brand | null> {
    try {
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: `{Name} = "${name}"`
      });

      if (records.length === 0) {
        return null;
      }

      const record = records[0];
      return this.mapRecordToBrand({ id: record.id, ...record.fields });
    } catch (error) {
      console.error(`Error finding brand by name ${name}:`, error);
      return null;
    }
  }

  /**
   * Extract and save brand style from website
   * @param brandId The brand ID
   * @param websiteUrl The URL of the brand's website
   * @returns A promise that resolves to the updated brand
   */
  public async extractStyleFromWebsite(brandId: string, websiteUrl: string): Promise<Brand | null> {
    try {
      // Fetch website content
      const response = await axios.get(websiteUrl);
      const html = response.data;

      // Extract colors, fonts, etc. (simplified implementation)
      // In a real implementation, this would use more sophisticated extraction techniques
      // such as using Puppeteer or a web scraping service

      // Example: Extract colors from CSS (simplified)
      const colorRegex = /#[0-9A-Fa-f]{6}/g;
      const colorsFound = html.match(colorRegex) || [];
      const uniqueColors = Array.from(new Set(colorsFound)) as string[];

      // Example: Extract fonts from CSS (simplified)
      const fontRegex = /font-family:\s*(['"])?([-\w\s,]+)\1/g;
      const fontsMatches = html.matchAll(fontRegex);
      const fonts = Array.from(fontsMatches, m => m[2].split(',')[0].trim());
      const uniqueFonts = Array.from(new Set(fonts)) as string[];

      // Update brand with extracted information
      const updateData: Partial<Brand> = {
        websiteUrl: websiteUrl,
        website: websiteUrl, // For backward compatibility
        style: {
          imageStyle: 'professional' // Default style
        }
      };

      if (uniqueColors.length > 0) {
        updateData.colors = {
          primary: uniqueColors[0],
          secondary: uniqueColors.slice(1, 3),
          accent: uniqueColors.slice(3, 5)
        };
      }

      if (uniqueFonts.length > 0) {
        updateData.typography = {
          headingFont: uniqueFonts[0],
          bodyFont: uniqueFonts.length > 1 ? uniqueFonts[1] : uniqueFonts[0]
        };
      }

      // Update brand in database
      return await this.update(brandId, updateData);
    } catch (error) {
      console.error(`Error extracting style from website for brand ${brandId}:`, error);
      return null;
    }
  }

  /**
   * Upload and process a brand logo
   * @param brandId The brand ID
   * @param logoFile The logo file data
   * @returns A promise that resolves to the updated brand
   */
  public async uploadLogo(brandId: string, logoFile: Buffer): Promise<Brand | null> {
    try {
      // Upload logo to Cloudinary
      const uploadResult = await this.cloudinary.uploadImage(
        logoFile,
        `${config.MEDIA.CLOUDINARY.FOLDERS.BRANDS}/${brandId}/logo`,
        { public_id: `main-logo-${Date.now()}` }
      );

      // Update brand with logo URL
      return await this.update(brandId, {
        logos: {
          main: uploadResult.secure_url
        }
      });
    } catch (error) {
      console.error(`Error uploading logo for brand ${brandId}:`, error);
      return null;
    }
  }

  /**
   * Update brand colors
   * @param brandId The brand ID
   * @param colors The colors to update
   * @returns A promise that resolves to the updated brand
   */
  public async updateColors(brandId: string, colors: Brand['colors']): Promise<Brand | null> {
    try {
      return await this.update(brandId, { colors });
    } catch (error) {
      console.error(`Error updating colors for brand ${brandId}:`, error);
      return null;
    }
  }

  /**
   * Get all brands with their associated content count
   * @returns A promise that resolves to an array of brands with content count
   */
  public async getBrandsWithContentCount(): Promise<Array<Brand & { contentCount: number }>> {
    try {
      // Get all brands
      const brands = await this.findAll();

      // Get content counts for each brand
      const contentTable = config.AIRTABLE.TABLES.JOB_POSTS;

      // Create an array of promises to get content count for each brand
      const brandWithCountPromises = brands.map(async (brand) => {
        const records = await this.airtable.select(contentTable, {
          filterByFormula: `{CompanyId} = "${brand.id}"`,
          fields: ['id'] // Only fetch IDs to minimize data transfer
        });

        return {
          ...brand,
          contentCount: records.length
        };
      });

      // Wait for all promises to resolve
      return await Promise.all(brandWithCountPromises);
    } catch (error) {
      console.error('Error getting brands with content count:', error);
      return [];
    }
  }
}