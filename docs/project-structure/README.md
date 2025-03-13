# Synapse: Advanced Content Automation System

## Project Overview

Synapse is a comprehensive content automation system designed to streamline creation, approval, and distribution of branded social media content. Unlike traditional content tools that rely heavily on templates, Synapse employs AI-driven image generation and smart content creation to produce dynamically generated, on-brand content with minimal manual intervention.

## Directory Structure

```
synapse/
├── src/
│   ├── api/                           # API-related code
│   │   ├── controllers/               # Handle API requests and responses
│   │   ├── middleware/                # Request processing, validation, and authentication
│   │   │   ├── auth/                  # Authentication and authorization middleware
│   │   │   └── validators/            # Request validation middleware
│   │   └── routes/                    # API route definitions
│   │
│   ├── config/                        # Application configuration files
│   │
│   ├── data-sources/                  # Data source implementations
│   │   ├── airtable/                  # Airtable-specific implementation
│   │   └── future/                    # Stub implementations for future data sources
│   │
│   ├── models/                        # Data models and interfaces
│   │
│   ├── repositories/                  # Repository pattern for data access
│   │   ├── implementations/           # Concrete repository implementations
│   │   └── interfaces/                # Repository interfaces
│   │
│   ├── services/                      # Business logic services
│   │   ├── image-generation/          # AI image generation services
│   │   ├── text-overlay/              # Text overlay services
│   │   ├── approval-workflow/         # Content approval workflow services
│   │   └── distribution/              # Content distribution services
│   │
│   ├── themes/                        # Theming and styling components
│   │   ├── templates/                 # Content templates
│   │   ├── components/                # Reusable UI components
│   │   └── styles/                    # Style definitions
│   │
│   ├── utils/                         # Utility functions and helpers
│   │   ├── logging/                   # Logging utilities
│   │   └── helpers/                   # Helper functions
│   │
│   ├── workers/                       # Background workers and jobs
│   │   ├── content-scheduling/        # Content scheduling workers
│   │   ├── image-generation/          # Image generation workers
│   │   └── distribution/              # Content distribution workers
│   │
│   └── prompts/                       # AI prompt templates
│       ├── job-posts/                 # Job posting specific prompts
│       └── marketing/                 # Marketing specific prompts
│
├── logs/                             # Application logs
├── uploads/                          # Uploaded files
├── temp/                             # Temporary files
├── docs/                             # Documentation
├── public/                           # Public assets
└── scripts/                          # Utility scripts
```

## Core Capabilities

### 1. Multi-Source Asset Ingestion
- Extracts brand elements from websites, uploaded assets, and existing designs
- Uses AI analysis to identify color palettes, typography, and visual style
- Creates brand guidelines automatically from existing assets

### 2. Dynamic Content Generation
- Generates AI images using sophisticated, context-aware prompts
- Applies intelligent text overlays following brand guidelines
- Supports both fully automated and hybrid (human-assisted) workflows

### 3. Smart Approval System
- Integrates with Slack for streamlined content review
- Provides interactive approval/revision workflows
- Captures feedback for continuous improvement

### 4. Intelligent Distribution
- Implements algorithmic content scheduling
- Connects with Make.com for cross-platform posting
- Manages distribution across multiple client accounts

## System Architecture

### Data Flow

#### Automated Path
1. System detects new job record in Airtable marked for processing
2. Retrieves job details and brand configuration
3. Generates optimized prompt based on job context
4. Requests image from AI generation service
5. Applies text overlay with proper branding
6. Sends to Slack for review
7. Processes approval/feedback
8. Updates Airtable with final assets and status

#### Manual Path
1. User uploads design from Canva to Airtable
2. System detects manual upload in the job record
3. Processes the uploaded design (format conversion if needed)
4. Applies text overlay with proper branding
5. Sends to Slack for review
6. Processes approval/feedback
7. Updates Airtable with final assets and status

## Key Components

### 1. Asset Ingestion System
- **Purpose**: Analyze and process brand assets to extract design elements and style
- **Core Modules**:
  - File Upload Handler - Processes direct asset uploads
  - Website Scraper - Extracts brand elements from client websites
  - Canva Integration - Imports designs from Canva
  - AI Analysis Engine - Identifies colors, typography, and visual elements
  - Airtable Connector - Stores extracted brand data

### 2. Brand Style System
- **Purpose**: Maintain consistent brand representation across all content
- **Core Modules**:
  - Theme Manager - Handles brand themes and styles
  - Style Extractor - Generates style guidelines from assets
  - Theme Adapter - Adjusts themes for different content types
  - Typography Engine - Manages font choices and text styling

### 3. Content Generation System
- **Purpose**: Create AI-generated images with proper branding
- **Core Modules**:
  - Context Analyzer - Extracts relevant job/content context
  - Prompt Generator - Creates optimized AI image prompts
  - Image Generation Connector - Interfaces with AI services
  - Image Processing - Handles and optimizes generated images

### 4. Text Overlay System
- **Purpose**: Apply branded text to images in optimal positions
- **Core Modules**:
  - Content Formatter - Prepares text for display
  - Layout Engine - Determines optimal text positioning
  - Style Applicator - Applies brand styling to text
  - Cloudinary Integration - Handles image processing and text overlay

### 5. Approval Workflow System
- **Purpose**: Facilitate content review and feedback
- **Core Modules**:
  - Slack Integration - Sends content for review
  - Interactive Controls - Provides approval/edit/decline options
  - Feedback Collector - Captures and processes input
  - Revision Handler - Manages content updates based on feedback

### 6. Distribution System
- **Purpose**: Schedule and distribute content across platforms
- **Core Modules**:
  - Scheduling Algorithm - Determines optimal posting times
  - Content Queue - Manages pending posts
  - Make.com Connector - Triggers post distribution
  - Status Tracker - Monitors posting status and results

### 7. Monitoring and Reporting
- **Purpose**: Track system performance and content effectiveness
- **Core Modules**:
  - Error Handler - Manages and logs system errors
  - Performance Monitor - Tracks processing metrics
  - Content Analytics - Reports on content performance
  - Improvement Analyzer - Identifies patterns for system enhancement

## Technical Stack

### Backend
- **Language**: JavaScript/Node.js
- **Framework**: Express.js
- **Job Processing**: Bull or similar queue system
- **Scheduling**: node-cron

### Services & Storage
- **Database**: Airtable (primary), with optional Redis for caching
- **File Storage**: Cloudinary or S3 for processed images
- **Authentication**: JWT for API security

### Integrations
- **Image Generation API**: OpenAI DALL-E, Midjourney, or similar
- **Image Processing**: Cloudinary for text overlay and image manipulation
- **Notification System**: Slack for approvals and notifications
- **Distribution**: Make.com for cross-platform posting

## Database Schema

### Table: Company
Contains information about companies, their branding, and associated job posts.

### Table: Platforms
Stores details about social media platforms, including character limits, posting restrictions, and media format requirements.

### Table: Job Posts
Manages job posting data, content generation status, and distribution settings.

### Table: Position Types
Categorizes different types of job positions.

### Table: Job Descriptions
Stores detailed job information used for content generation.

### Table: Hashtags
Manages hashtag organization, categories, and usage rules.

## Implementation Timeline

The 8-week development timeline is structured as follows:

**Weeks 1-2: Foundation**
- Infrastructure setup and Airtable connector
- Brand theme system implementation
- Basic prompt generation logic

**Weeks 3-4: Image Generation**
- Integration with image generation API
- Error handling and retry logic
- Basic text overlay functionality

**Weeks 5-6: Approval System**
- Slack integration for approval workflow
- Approval/decline handlers
- Feedback processing and regeneration logic

**Weeks 7-8: Integration & Testing**
- End-to-end process connection
- Bug fixing and improvements
- Final testing and deployment

## Unique Value Proposition

Synapse addresses key limitations in existing tools by:
- Eliminating the need for pre-built templates
- Providing consistent branded output without manual design
- Supporting multiple content types beyond just job postings
- Offering a complete end-to-end workflow from content creation to distribution

## Target Applications

While initially focused on recruitment marketing for StaffHive, the architecture is designed to support multiple content types:
- Job postings and recruitment content
- Marketing announcements and promotions
- Product updates and launches
- General brand communications

This system represents a novel approach to content automation by combining AI image generation, intelligent brand analysis, and streamlined approval workflows into a cohesive, end-to-end solution.