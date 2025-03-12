import dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

/**
 * Application configuration object
 * Centralizes all environment variables and configuration settings
 */
const config = {
  // Server configuration
  PORT: parseInt(process.env.PORT || '3000', 10),
  NODE_ENV: process.env.NODE_ENV || 'development',
  
  // API keys and credentials
  AIRTABLE: {
    API_KEY: process.env.AIRTABLE_API_KEY || '',
    BASE_ID: process.env.AIRTABLE_BASE_ID || '',
    TABLES: {
      BRANDS: 'Brands',
      JOBS: 'Jobs',
      CONTENT: 'Content',
      THEMES: 'Themes',
      ASSETS: 'Assets',
      DISTRIBUTION: 'Distribution'
    }
  },
  
  OPENAI: {
    API_KEY: process.env.OPENAI_API_KEY || '',
    MODELS: {
      TEXT: 'gpt-4-turbo',
      IMAGE: 'dall-e-3'
    }
  },
  
  CLOUDINARY: {
    CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME || '',
    API_KEY: process.env.CLOUDINARY_API_KEY || '',
    API_SECRET: process.env.CLOUDINARY_API_SECRET || '',
    FOLDERS: {
      BRANDS: 'brands',
      CONTENT: 'content',
      ASSETS: 'assets'
    }
  },
  
  SLACK: {
    BOT_TOKEN: process.env.SLACK_BOT_TOKEN || '',
    SIGNING_SECRET: process.env.SLACK_SIGNING_SECRET || '',
    APPROVAL_CHANNEL: process.env.SLACK_APPROVAL_CHANNEL || 'content-approvals'
  },
  
  // App settings
  APP: {
    DEFAULT_PAGINATION_LIMIT: 50,
    IMAGE_QUALITY: 'auto:best',
    IMAGE_FORMAT: 'auto',
    DEFAULT_IMAGE_WIDTH: 1200,
    MAX_RETRY_ATTEMPTS: 3,
    JOB_QUEUE_CONCURRENCY: 5
  },
  
  // URLs
  URLS: {
    BASE_URL: process.env.BASE_URL || 'http://localhost:3000',
    FRONTEND_URL: process.env.FRONTEND_URL || 'http://localhost:3000'
  },
  
  // Content generation settings
  CONTENT_GENERATION: {
    DEFAULT_STYLE: 'professional',
    IMAGE_STYLES: [
      'professional', 
      'creative', 
      'minimalist', 
      'bold', 
      'elegant'
    ],
    TEXT_POSITIONS: [
      'center', 
      'top', 
      'bottom', 
      'left', 
      'right'
    ]
  }
};

// Validate required configuration
const validateConfig = () => {
  const requiredFields = [
    'AIRTABLE.API_KEY',
    'AIRTABLE.BASE_ID',
    'OPENAI.API_KEY',
    'CLOUDINARY.CLOUD_NAME',
    'CLOUDINARY.API_KEY',
    'CLOUDINARY.API_SECRET'
  ];
  
  const missingFields = requiredFields.filter(field => {
    const value = field.split('.').reduce((obj, key) => obj ? obj[key] : undefined, config as any);
    return !value;
  });
  
  if (missingFields.length > 0) {
    console.warn(`Missing required configuration: ${missingFields.join(', ')}`);
    
    if (process.env.NODE_ENV === 'production') {
      throw new Error(`Missing required configuration: ${missingFields.join(', ')}`);
    }
  }
};

// Only validate in non-test environments
if (process.env.NODE_ENV !== 'test') {
  validateConfig();
}

export default config;