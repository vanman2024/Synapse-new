/**
 * Interface for Brand entity in the system
 */
export interface Brand {
  /**
   * Unique identifier for the brand
   */
  id?: string;
  
  /**
   * Name of the brand
   */
  name: string;
  
  /**
   * Description of the brand
   */
  description?: string;
  
  /**
   * Primary website URL
   */
  websiteUrl?: string;
  
  /**
   * Website URL (legacy field)
   * @deprecated Use websiteUrl instead
   */
  website?: string;
  
  /**
   * Brand logo URL
   */
  logoUrl?: string;
  
  /**
   * Brand color scheme
   */
  colors?: {
    primary?: string;
    secondary?: string[] | string;
    accent?: string[] | string;
    text?: string;
    background?: string;
  };
  
  /**
   * Font family preferences
   */
  fonts?: {
    primary?: string;
    secondary?: string;
    headings?: string;
    body?: string;
  };
  
  /**
   * Typography settings
   */
  typography?: {
    headingFont?: string;
    bodyFont?: string;
    fontSize?: {
      heading?: number;
      subheading?: number;
      body?: number;
    };
  };
  
  /**
   * Logo information
   */
  logos?: {
    main?: string;
    alternate?: string[] | string;
  };
  
  /**
   * Style information
   */
  style?: {
    imageStyle?: string;
    textStyle?: string;
    layoutPreferences?: string[] | string;
  };
  
  /**
   * Social media accounts
   */
  socialMedia?: {
    facebook?: string;
    instagram?: string;
    twitter?: string;
    linkedin?: string;
    youtube?: string;
    tiktok?: string;
  };
  
  /**
   * Industry or business category
   */
  industry?: string;
  
  /**
   * Target audience demographics
   */
  targetAudience?: string[];
  
  /**
   * Brand tone and voice description
   */
  toneOfVoice?: string;
  
  /**
   * Key brand messaging points
   */
  keyMessages?: string[];
  
  /**
   * Creation timestamp
   */
  createdAt?: Date;
  
  /**
   * Last update timestamp
   */
  updatedAt?: Date;
}