import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

// Load environment variables from .env file
dotenv.config();

// Check if required directories exist, create if they don't
const requiredDirs = [
  process.env.UPLOAD_DIR || 'uploads',
  process.env.TEMP_DIR || 'temp',
  path.dirname(process.env.LOG_FILE_PATH || 'logs/app.log')
];

requiredDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    console.log(`Created directory: ${dir}`);
  }
});

/**
 * Application configuration object
 * Centralizes all environment variables and configuration settings
 */
const config = {
  // Server configuration
  SERVER: {
    PORT: parseInt(process.env.PORT || '3000', 10),
    NODE_ENV: process.env.NODE_ENV || 'development',
    API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:3000/api'
  },
  
  // Airtable configuration
  AIRTABLE: {
    PERSONAL_ACCESS_TOKEN: process.env.AIRTABLE_PERSONAL_ACCESS_TOKEN || '',
    BASE_ID: process.env.AIRTABLE_BASE_ID || '',
    TABLES: {
      COMPANY: process.env.AIRTABLE_COMPANY_TABLE || 'Company',
      JOB_POSTS: process.env.AIRTABLE_JOB_POSTS_TABLE || 'Job Posts',
      PLATFORMS: process.env.AIRTABLE_PLATFORMS_TABLE || 'Platforms',
      POSITION_TYPES: process.env.AIRTABLE_POSITION_TYPES_TABLE || 'Position Types',
      HASHTAGS: process.env.AIRTABLE_HASHTAGS_TABLE || 'Hashtags',
      JOB_DESCRIPTIONS: process.env.AIRTABLE_JOB_DESCRIPTIONS_TABLE || 'Job Descriptions'
    }
  },
  
  // OpenAI configuration
  OPENAI: {
    API_KEY: process.env.OPENAI_API_KEY || '',
    ORG_ID: process.env.OPENAI_ORG_ID || '',
    DALLE_API_VERSION: process.env.DALLE_API_VERSION || 'v3',
    MODELS: {
      TEXT: 'gpt-4-turbo',
      IMAGE: process.env.IMAGE_GEN_MODEL || 'dall-e-3'
    }
  },
  
  // Alternative image generation services
  ALTERNATE_IMAGE_SERVICES: {
    MIDJOURNEY: {
      API_KEY: process.env.MIDJOURNEY_API_KEY || '',
      ENABLED: !!process.env.MIDJOURNEY_API_KEY
    },
    STABILITY: {
      API_KEY: process.env.STABILITY_API_KEY || '',
      ENABLED: !!process.env.STABILITY_API_KEY
    }
  },
  
  // Media storage options
  MEDIA: {
    // Option 1: Cloudinary
    CLOUDINARY: {
      CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME || '',
      API_KEY: process.env.CLOUDINARY_API_KEY || '',
      API_SECRET: process.env.CLOUDINARY_API_SECRET || '',
      FETCH_URL_PREFIX: process.env.CLOUDINARY_FETCH_URL_PREFIX || '',
      FOLDERS: {
        BRANDS: 'brands',
        CONTENT: 'content',
        ASSETS: 'assets',
        JOBS: 'jobs'
      }
    },
    
    // Option 2: Digital Ocean Spaces
    DO_SPACES: {
      KEY: process.env.DO_SPACES_KEY || '',
      SECRET: process.env.DO_SPACES_SECRET || '',
      ENDPOINT: process.env.DO_SPACES_ENDPOINT || 'nyc3.digitaloceanspaces.com',
      BUCKET: process.env.DO_SPACES_BUCKET || '',
      REGION: process.env.DO_SPACES_REGION || 'nyc3',
      CDN_ENDPOINT: process.env.DO_CDN_ENDPOINT || '',
      ENABLED: !!(process.env.DO_SPACES_KEY && process.env.DO_SPACES_SECRET && process.env.DO_SPACES_BUCKET)
    },
    
    // Option 3: AWS S3
    AWS: {
      ACCESS_KEY_ID: process.env.AWS_ACCESS_KEY_ID || '',
      SECRET_ACCESS_KEY: process.env.AWS_SECRET_ACCESS_KEY || '',
      REGION: process.env.AWS_REGION || 'us-east-1',
      S3_BUCKET: process.env.AWS_S3_BUCKET || '',
      LAMBDA_FUNCTION: process.env.AWS_LAMBDA_FUNCTION || '',
      S3_URL_EXPIRY: parseInt(process.env.AWS_S3_URL_EXPIRY || '3600', 10),
      ENABLED: !!(process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY && process.env.AWS_S3_BUCKET)
    },
    
    // Option 4: Hybrid Approach
    USE_HYBRID_APPROACH: process.env.USE_HYBRID_APPROACH === 'true',
    
    // Text overlay settings
    TEXT_OVERLAY: {
      FONT: process.env.TEXT_OVERLAY_FONT || 'Arial',
      COLOR: process.env.TEXT_OVERLAY_COLOR || '#FFFFFF',
      SHADOW: process.env.TEXT_OVERLAY_SHADOW === 'true',
      POSITION: process.env.TEXT_OVERLAY_POSITION || 'bottom'
    }
  },
  
  // Slack integration
  SLACK: {
    BOT_TOKEN: process.env.SLACK_BOT_TOKEN || '',
    SIGNING_SECRET: process.env.SLACK_SIGNING_SECRET || '',
    APP_TOKEN: process.env.SLACK_APP_TOKEN || '',
    APPROVAL_CHANNEL: process.env.SLACK_APPROVAL_CHANNEL || 'content-approvals',
    ENABLED: !!(process.env.SLACK_BOT_TOKEN && process.env.SLACK_SIGNING_SECRET)
  },
  
  // Make.com integration
  MAKE: {
    API_KEY: process.env.MAKE_API_KEY || '',
    WEBHOOK_BASE_URL: process.env.MAKE_WEBHOOK_BASE_URL || '',
    ENABLED: !!(process.env.MAKE_API_KEY && process.env.MAKE_WEBHOOK_BASE_URL)
  },
  
  // Web scraping configuration
  SCRAPING: {
    PUPPETEER_TIMEOUT: parseInt(process.env.PUPPETEER_TIMEOUT || '30000', 10),
    MAX_SCRAPE_DEPTH: parseInt(process.env.MAX_SCRAPE_DEPTH || '3', 10)
  },
  
  // Logging
  LOGGING: {
    LEVEL: process.env.LOG_LEVEL || 'info',
    FILE_PATH: process.env.LOG_FILE_PATH || 'logs/app.log'
  },
  
  // Security
  SECURITY: {
    JWT_SECRET: process.env.JWT_SECRET || 'development_secret_key',
    JWT_EXPIRY: process.env.JWT_EXPIRY || '24h',
    API_RATE_LIMIT: parseInt(process.env.API_RATE_LIMIT || '100', 10)
  },
  
  // Caching
  CACHE: {
    REDIS_URL: process.env.REDIS_URL || '',
    TTL: parseInt(process.env.CACHE_TTL || '3600', 10),
    ENABLED: !!process.env.REDIS_URL
  },
  
  // Storage paths
  PATHS: {
    UPLOAD_DIR: process.env.UPLOAD_DIR || 'uploads',
    TEMP_DIR: process.env.TEMP_DIR || 'temp'
  },
  
  // Queue configuration
  QUEUE: {
    CONCURRENCY: parseInt(process.env.QUEUE_CONCURRENCY || '3', 10),
    RETRY_ATTEMPTS: parseInt(process.env.RETRY_ATTEMPTS || '3', 10),
    RETRY_DELAY: parseInt(process.env.RETRY_DELAY || '5000', 10)
  },
  
  // Feature flags
  FEATURES: {
    ENABLE_MANUAL_UPLOAD: process.env.ENABLE_MANUAL_UPLOAD !== 'false',
    ENABLE_AI_GENERATION: process.env.ENABLE_AI_GENERATION !== 'false',
    ENABLE_AUTO_DISTRIBUTION: process.env.ENABLE_AUTO_DISTRIBUTION !== 'false',
    ENABLE_PERFORMANCE_TRACKING: process.env.ENABLE_PERFORMANCE_TRACKING !== 'false'
  }
};

// Validate required configuration
const validateConfig = () => {
  const criticalSettings = [
    {
      check: !config.AIRTABLE.PERSONAL_ACCESS_TOKEN || !config.AIRTABLE.BASE_ID,
      message: 'Missing required Airtable configuration'
    },
    {
      check: !config.OPENAI.API_KEY,
      message: 'Missing OpenAI API key'
    },
    {
      check: !config.MEDIA.CLOUDINARY.CLOUD_NAME && 
             !config.MEDIA.DO_SPACES.ENABLED && 
             !config.MEDIA.AWS.ENABLED,
      message: 'At least one media storage option must be configured'
    }
  ];
  
  const missingSettings = criticalSettings
    .filter(setting => setting.check)
    .map(setting => setting.message);
  
  if (missingSettings.length > 0) {
    console.warn('⚠️  Configuration warnings:');
    missingSettings.forEach(msg => console.warn(`  - ${msg}`));
    
    if (process.env.NODE_ENV === 'production') {
      throw new Error(`Critical configuration missing: ${missingSettings.join(', ')}`);
    }
  }
};

// Only validate in non-test environments
if (process.env.NODE_ENV !== 'test') {
  validateConfig();
}

export default config;