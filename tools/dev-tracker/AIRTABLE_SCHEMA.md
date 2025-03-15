# Airtable Schema for Development Tracking

This document provides the exact schema needed for the Development Tracking Airtable base.

## Table: Phases

Primary Field: Name (Single line text)

| Field Name    | Field Type         | Options                                  |
|---------------|--------------------|-----------------------------------------|
| Name          | Single line text   |                                         |
| Number        | Number             | Integer                                 |
| Status        | Single select      | Options: Current, Completed, Planned    |
| Description   | Long text          |                                         |

## Table: Modules

Primary Field: Name (Single line text)

| Field Name    | Field Type         | Options                                  |
|---------------|--------------------|-----------------------------------------|
| Name          | Single line text   |                                         |
| Phase         | Single line text   |                                         |
| PhaseNumber   | Number             | Integer                                 |
| Status        | Single select      | Options: Completed, In Progress, Planned|
| Description   | Long text          |                                         |
| LastUpdated   | Date               | Format: YYYY-MM-DD                      |

## Table: Sessions

Primary Field: Date (Date)

| Field Name    | Field Type         | Options                                  |
|---------------|--------------------|-----------------------------------------|
| Date          | Date               | Format: YYYY-MM-DD                      |
| Branch        | Single line text   |                                         |
| Focus         | Single line text   |                                         |
| Status        | Single select      | Options: Completed, Active              |
| StartTime     | Single line text   | Format: HH:MM                           |
| EndTime       | Single line text   | Format: HH:MM                           |
| Summary       | Long text          |                                         |
| Commits       | Long text          |                                         |
| Notes         | Long text          |                                         |

## Manual Setup Instructions

1. Create a new base in Airtable called "Development Tracking (Synapse)"
2. Create 3 tables: "Phases", "Modules", and "Sessions"
3. For each table, add fields with the exact names and types listed above
4. For Single select fields, add the specified options
5. Set the primary field for each table as indicated above

## Data Import

After creating the tables with the proper structure, you can create example records or import data from CSV files.

Here are example records for each table:

### Phases

| Name                           | Number | Status    | Description                                    |
|--------------------------------|--------|-----------|------------------------------------------------|
| Foundation & Verification      | 1      | Completed | Setting up the core foundation of the app      |
| Content Generation Enhancement | 2      | Current   | Enhancing content generation capabilities      |
| User Management & Security     | 3      | Planned   | Implementing user management and security      |
| Front-End Development          | 4      | Planned   | Building user interfaces and frontend elements |
| Integration & Expansion        | 5      | Planned   | Expanding integrations with external services  |
| AI Enhancements & Optimization | 6      | Planned   | Advanced AI capabilities and optimizations     |

### Modules (Partial List)

| Name                                     | Phase                      | PhaseNumber | Status     | Description                                    | LastUpdated |
|------------------------------------------|----------------------------|-------------|------------|------------------------------------------------|-------------|
| Set up Express server with basic routes  | Foundation & Verification  | 1           | Completed  | Configure Express server and routing structure | 2025-03-15  |
| Implement Content Repository             | Foundation & Verification  | 1           | Completed  | Create content repository layer                | 2025-03-15  |
| Implement Content Controller             | Foundation & Verification  | 1           | Completed  | Create API endpoints for content               | 2025-03-15  |
| Implement Content Service with AI        | Content Generation Enhancement | 2      | Completed  | Create service for AI content generation       | 2025-03-15  |
| Improve OpenAI prompt templates          | Content Generation Enhancement | 2      | In Progress| Standardize and improve prompt templates      | 2025-03-15  |