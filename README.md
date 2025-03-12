# Synapse

Synapse is a comprehensive content automation system designed to streamline creation, approval, and distribution of branded social media content. Unlike traditional content tools that rely heavily on templates, Synapse employs AI-driven image generation and smart content creation to produce dynamically generated, on-brand content with minimal manual intervention.

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

## Getting Started

### Prerequisites
- Node.js (v14 or higher)
- npm or yarn
- Airtable account
- OpenAI API key
- Cloudinary account
- Slack workspace (for approval workflow)

### Installation
1. Clone the repository
```bash
git clone https://github.com/your-username/synapse.git
cd synapse
```

2. Install dependencies
```bash
npm install
```

3. Configure environment variables
```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

4. Run the setup script
```bash
npm run setup
```

5. Start the development server
```bash
npm run dev
```

## Project Structure

The project uses a data access layer pattern to make future database migrations easier:

```
/
├── src/
│   ├── api/                  # API endpoints
│   │   ├── controllers/      # Request handlers
│   │   ├── middleware/       # Express middleware
│   │   └── routes/           # Route definitions
│   ├── config/               # Configuration files
│   ├── data-sources/         # Data source implementations
│   │   └── airtable/         # Airtable-specific code
│   ├── models/               # Data models/interfaces
│   ├── prompts/              # AI prompt templates
│   ├── repositories/         # Repository pattern
│   │   ├── interfaces/       # Repository interfaces
│   │   └── implementations/  # Concrete implementations
│   ├── services/             # Business logic
│   ├── themes/               # Theme management
│   ├── utils/                # Utility functions
│   └── workers/              # Background workers
├── scripts/                  # Setup and utility scripts
└── tests/                    # Test files
```