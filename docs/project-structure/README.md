# Synapse Project Structure



## Directory Descriptions

### src/
- **api/**: API-related code (controllers, routes, middleware)
  - **controllers/**: Handle API requests and responses
  - **middleware/**: Request processing, validation, and authentication
    - **auth/**: Authentication and authorization middleware
    - **validators/**: Request validation middleware
  - **routes/**: API route definitions
- **config/**: Application configuration files
- **data-sources/**: Data source implementations
  - **airtable/**: Airtable-specific implementation
  - **future/**: Stub implementations for future data sources
- **models/**: Data models and interfaces
- **repositories/**: Repository pattern for data access
  - **implementations/**: Concrete repository implementations
  - **interfaces/**: Repository interfaces
- **services/**: Business logic services
  - **image-generation/**: AI image generation services
  - **text-overlay/**: Text overlay services
  - **approval-workflow/**: Content approval workflow services
  - **distribution/**: Content distribution services
- **themes/**: Theming and styling components
  - **templates/**: Content templates
  - **components/**: Reusable UI components
  - **styles/**: Style definitions
- **utils/**: Utility functions and helpers
  - **logging/**: Logging utilities
  - **helpers/**: Helper functions
- **workers/**: Background workers and jobs
  - **content-scheduling/**: Content scheduling workers
  - **image-generation/**: Image generation workers
  - **distribution/**: Content distribution workers
- **prompts/**: AI prompt templates
  - **job-posts/**: Job posting specific prompts
  - **marketing/**: Marketing specific prompts

### Other Directories
- **logs/**: Application logs
- **uploads/**: Uploaded files
- **temp/**: Temporary files
- **docs/**: Documentation
- **public/**: Public assets
- **scripts/**: Utility scripts
