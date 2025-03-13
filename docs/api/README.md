# Synapse API Documentation

This documentation outlines the API connections for the Synapse Advanced Content Automation System, detailing endpoints, request/response formats, and integration points.

## Table of Contents
1. [Core API Overview](#core-api-overview)
2. [Asset Ingestion API](#asset-ingestion-api)
3. [Content Generation API](#content-generation-api)
4. [Approval Workflow API](#approval-workflow-api)
5. [Distribution API](#distribution-api)
6. [External Integrations](#external-integrations)
7. [Authentication](#authentication)
8. [Error Handling](#error-handling)

## Core API Overview

The Synapse API is built on RESTful principles using Express.js, with JWT authentication for securing endpoints.

**Base URL:** `https://api.synapse.example.com/v1`

### Response Format

All API responses follow a standard format:

```json
{
  "success": true,
  "data": {},
  "meta": {
    "requestId": "req_123456",
    "timestamp": "2025-03-12T14:30:00Z"
  }
}
```

For errors:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  },
  "meta": {
    "requestId": "req_123456",
    "timestamp": "2025-03-12T14:30:00Z"
  }
}
```

## Asset Ingestion API

Handles the ingestion of brand assets and creation of brand themes.

### Upload Brand Assets

**Endpoint:** `POST /ingestion/assets`

**Description:** Uploads brand assets for analysis and theme extraction

**Request:**
```json
{
  "companyId": "rec123456",
  "assetType": "logo|website|design",
  "source": "upload|url|canva",
  "sourceData": "https://example.com or base64data"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "assetId": "ast_123456",
    "status": "processing",
    "estimatedCompletionTime": "2025-03-12T15:00:00Z"
  }
}
```

### Website Scraping

**Endpoint:** `POST /ingestion/website`

**Description:** Extracts brand elements from a website

**Request:**
```json
{
  "companyId": "rec123456",
  "websiteUrl": "https://example.com",
  "pagesToScrape": ["home", "about", "careers"],
  "extractionOptions": {
    "extractColors": true,
    "extractTypography": true,
    "extractImages": true
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "scrapeId": "scr_123456",
    "status": "processing",
    "estimatedCompletionTime": "2025-03-12T15:15:00Z"
  }
}
```

### Get Brand Theme

**Endpoint:** `GET /ingestion/theme/:companyId`

**Description:** Retrieves the extracted brand theme for a company

**Response:**
```json
{
  "success": true,
  "data": {
    "themeId": "thm_123456",
    "companyId": "rec123456",
    "colors": {
      "primary": "#0078d4",
      "secondary": "#50e6ff",
      "accent": "#d2f2ff"
    },
    "typography": {
      "heading": "Montserrat",
      "body": "Open Sans"
    },
    "visualStyle": "modern, minimalist, clean lines, technology-focused",
    "imageStyle": "bright offices, modern tech environments",
    "lastUpdated": "2025-03-10T09:23:15Z"
  }
}
```

## Content Generation API

Handles the creation of content, including AI image generation and text overlay.

### Generate Content

**Endpoint:** `POST /generation/content`

**Description:** Creates content based on job post and brand theme

**Request:**
```json
{
  "jobPostId": "rec789012",
  "contentType": "social_post",
  "platform": "linkedin",
  "generationOptions": {
    "useAiGeneration": true,
    "textOverlayOptions": {
      "includeJobTitle": true,
      "includeLocation": true,
      "includeWage": false
    }
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "contentId": "cnt_123456",
    "status": "processing",
    "estimatedCompletionTime": "2025-03-12T15:30:00Z"
  }
}
```

### Get Content Status

**Endpoint:** `GET /generation/content/:contentId`

**Description:** Retrieves the status and results of content generation

**Response:**
```json
{
  "success": true,
  "data": {
    "contentId": "cnt_123456",
    "jobPostId": "rec789012",
    "status": "completed",
    "results": {
      "imageUrl": "https://storage.synapse.example.com/images/img_123456.jpg",
      "textOverlay": {
        "title": "Software Engineer",
        "location": "San Francisco, CA",
        "applicationInfo": "Apply now via link in comments"
      },
      "promptUsed": "Modern tech office with bright environment, team collaboration...",
      "generatedCaption": "We're hiring! Join our team as a Software Engineer in San Francisco..."
    },
    "completedAt": "2025-03-12T15:28:43Z"
  }
}
```

### Generate Image from Prompt

**Endpoint:** `POST /generation/image`

**Description:** Generates an AI image from a specific prompt

**Request:**
```json
{
  "companyId": "rec123456",
  "prompt": "Modern office environment with team collaborating on software project",
  "style": "photorealistic",
  "aspectRatio": "1:1"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "imageId": "img_123456",
    "status": "processing",
    "estimatedCompletionTime": "2025-03-12T15:10:00Z"
  }
}
```

### Apply Text Overlay

**Endpoint:** `POST /generation/overlay`

**Description:** Applies branded text overlay to an existing image

**Request:**
```json
{
  "imageId": "img_123456",
  "companyId": "rec123456",
  "textElements": [
    {
      "text": "Software Engineer",
      "type": "title",
      "position": "center"
    },
    {
      "text": "San Francisco, CA",
      "type": "location",
      "position": "bottom"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "overlayId": "ovr_123456",
    "status": "processing",
    "estimatedCompletionTime": "2025-03-12T15:05:00Z"
  }
}
```

## Approval Workflow API

Handles the approval process and feedback collection.

### Create Approval Request

**Endpoint:** `POST /approval/request`

**Description:** Creates a new approval request in Slack

**Request:**
```json
{
  "contentId": "cnt_123456",
  "approvers": ["U123456", "U234567"],
  "approvalDeadline": "2025-03-13T17:00:00Z",
  "notificationOptions": {
    "sendReminders": true,
    "reminderInterval": 4 // hours
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "approvalId": "apr_123456",
    "slackMessageId": "1615982348.009700",
    "slackChannelId": "C0123456789",
    "status": "pending",
    "created": "2025-03-12T15:35:00Z"
  }
}
```

### Get Approval Status

**Endpoint:** `GET /approval/status/:approvalId`

**Description:** Retrieves the current status of an approval request

**Response:**
```json
{
  "success": true,
  "data": {
    "approvalId": "apr_123456",
    "contentId": "cnt_123456",
    "status": "approved",
    "approvals": [
      {
        "approverId": "U123456",
        "status": "approved",
        "timestamp": "2025-03-12T16:15:23Z",
        "comments": "Looks great!"
      },
      {
        "approverId": "U234567",
        "status": "approved",
        "timestamp": "2025-03-12T16:30:45Z",
        "comments": null
      }
    ],
    "completedAt": "2025-03-12T16:30:45Z"
  }
}
```

### Process Feedback

**Endpoint:** `POST /approval/feedback`

**Description:** Processes feedback and initiates content revisions

**Request:**
```json
{
  "approvalId": "apr_123456",
  "approverId": "U123456",
  "status": "revision_requested",
  "feedback": {
    "textChanges": [
      {
        "element": "title",
        "newText": "Senior Software Engineer"
      }
    ],
    "designFeedback": "Make the background lighter and use more contrast for text",
    "regenerateImage": false
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "revisionId": "rev_123456",
    "status": "processing",
    "estimatedCompletionTime": "2025-03-12T17:00:00Z"
  }
}
```

## Distribution API

Handles content scheduling and distribution across platforms.

### Schedule Content

**Endpoint:** `POST /distribution/schedule`

**Description:** Schedules content for distribution

**Request:**
```json
{
  "contentId": "cnt_123456",
  "platformIds": ["rec_linkedin", "rec_instagram"],
  "scheduledTime": "2025-03-15T09:00:00Z",
  "schedulingOptions": {
    "useOptimalTiming": true,
    "timeZone": "America/Los_Angeles",
    "postCaption": "We're hiring! Join our team as a Software Engineer..."
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "scheduleId": "sch_123456",
    "scheduledPosts": [
      {
        "platformId": "rec_linkedin",
        "scheduledTime": "2025-03-15T09:00:00Z",
        "status": "scheduled"
      },
      {
        "platformId": "rec_instagram",
        "scheduledTime": "2025-03-15T10:30:00Z", // optimal time selected by algorithm
        "status": "scheduled"
      }
    ]
  }
}
```

### Get Distribution Status

**Endpoint:** `GET /distribution/status/:scheduleId`

**Description:** Retrieves the status of scheduled content

**Response:**
```json
{
  "success": true,
  "data": {
    "scheduleId": "sch_123456",
    "contentId": "cnt_123456",
    "posts": [
      {
        "platformId": "rec_linkedin",
        "scheduledTime": "2025-03-15T09:00:00Z",
        "status": "posted",
        "postUrl": "https://linkedin.com/post/123456",
        "postedAt": "2025-03-15T09:00:23Z",
        "analytics": {
          "impressions": 1250,
          "engagements": 48,
          "clicks": 15
        }
      },
      {
        "platformId": "rec_instagram",
        "scheduledTime": "2025-03-15T10:30:00Z",
        "status": "scheduled"
      }
    ]
  }
}
```

### Cancel Scheduled Post

**Endpoint:** `DELETE /distribution/schedule/:scheduleId/post/:platformId`

**Description:** Cancels a scheduled post for a specific platform

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "cancelled",
    "scheduleId": "sch_123456",
    "platformId": "rec_instagram",
    "cancelledAt": "2025-03-14T15:45:23Z"
  }
}
```

## External Integrations

### Airtable Webhook Handler

**Endpoint:** `POST /webhooks/airtable`

**Description:** Handles webhook notifications from Airtable for record changes

**Request:** (from Airtable)
```json
{
  "webhook_id": "wbk_12345",
  "trigger": "record.created",
  "table": "Job Posts",
  "record_id": "rec789012"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "received",
    "processingId": "proc_123456"
  }
}
```

### Slack Interactive Events

**Endpoint:** `POST /webhooks/slack/interactive`

**Description:** Handles interactive events from Slack (approval buttons, etc.)

**Request:** (from Slack)
```json
{
  "type": "interactive_message",
  "actions": [
    {
      "name": "approve",
      "value": "apr_123456"
    }
  ],
  "user": {
    "id": "U123456",
    "name": "johndoe"
  },
  "channel": {
    "id": "C0123456789",
    "name": "approvals"
  }
}
```

**Response:**
```json
{
  "response_type": "ephemeral",
  "text": "Thank you! Your approval has been recorded."
}
```

### Make.com Webhook

**Endpoint:** `POST /webhooks/make`

**Description:** Receives distribution status updates from Make.com

**Request:** (from Make.com)
```json
{
  "scheduleId": "sch_123456",
  "platformId": "rec_linkedin",
  "status": "posted",
  "postUrl": "https://linkedin.com/post/123456",
  "timestamp": "2025-03-15T09:00:23Z"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "received": true
  }
}
```

## Authentication

### Get Authentication Token

**Endpoint:** `POST /auth/token`

**Description:** Authenticates and provides a JWT token for API access

**Request:**
```json
{
  "apiKey": "sk_12345678901234567890",
  "clientId": "cl_123456"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2025-03-13T14:30:00Z"
  }
}
```

## Error Handling

Common error codes returned by the API:

| Code | Description |
|------|-------------|
| `INVALID_REQUEST` | Request is malformed or missing required fields |
| `AUTHENTICATION_FAILED` | Authentication credentials are invalid |
| `AUTHORIZATION_FAILED` | User does not have permission for the requested action |
| `RESOURCE_NOT_FOUND` | The requested resource does not exist |
| `GENERATION_FAILED` | Content generation process failed |
| `EXTERNAL_SERVICE_ERROR` | Error from an external service (AI, Slack, etc.) |
| `VALIDATION_ERROR` | Input validation failed |
| `RATE_LIMIT_EXCEEDED` | API rate limit has been exceeded |

For extended debugging, detailed error information is available in the `details` field of error responses when appropriate debugging headers are included in the request.

You're right - the documentation could be more comprehensive. Let me add more detailed sections that would be valuable for developers working with the Synapse API:

## Configuration API

Manages brand themes, content types, and system settings.

### Get Brand Theme Configuration

**Endpoint:** `GET /config/themes/:companyId`

**Description:** Retrieves detailed theme configuration for a company

**Response:**
```json
{
  "success": true,
  "data": {
    "brandTheme": {
      "colors": {
        "primary": "#0078d4",
        "secondary": "#50e6ff",
        "accent": "#d2f2ff",
        "text": "#333333",
        "background": "#ffffff"
      },
      "typography": {
        "headingFont": "Montserrat",
        "bodyFont": "Open Sans",
        "fontSizes": {
          "h1": "32px",
          "h2": "24px",
          "body": "16px",
          "small": "14px"
        },
        "fontWeights": {
          "heading": 600,
          "body": 400
        }
      },
      "spacing": {
        "textMargin": "20px",
        "contentPadding": "15px" 
      },
      "visualStyle": "modern, minimalist, clean lines",
      "imageStyle": "bright offices, modern tech environments"
    }
  }
}
```

### Update Brand Theme

**Endpoint:** `PUT /config/themes/:companyId`

**Description:** Updates a company's brand theme configuration

**Request:**
```json
{
  "colors": {
    "primary": "#004e8c",
    "secondary": "#40c4ff"
  },
  "visualStyle": "modern, professional, tech-focused"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "updated": true,
    "themeId": "thm_123456",
    "updatedAt": "2025-03-12T16:45:23Z"
  }
}
```

### Get Content Type Templates

**Endpoint:** `GET /config/contenttypes`

**Description:** Retrieves available content type templates

**Response:**
```json
{
  "success": true,
  "data": {
    "contentTypes": [
      {
        "id": "job_posting",
        "name": "Job Posting",
        "description": "Social media post for job openings",
        "requiredFields": ["jobTitle", "location", "applyLink"],
        "optionalFields": ["salary", "benefits", "requirements"],
        "platformCompatibility": ["linkedin", "facebook", "instagram"],
        "imagePromptTemplate": "Professional {industry} workplace with {visualStyle} aesthetic..."
      },
      {
        "id": "company_announcement",
        "name": "Company Announcement",
        "description": "Announcements about company news and updates",
        "requiredFields": ["title", "description"],
        "optionalFields": ["eventDate", "location"],
        "platformCompatibility": ["linkedin", "twitter", "facebook"],
        "imagePromptTemplate": "Corporate announcement setting with {visualStyle}..."
      }
    ]
  }
}
```

## Analytics API

Tracks content performance and system metrics.

### Get Content Performance

**Endpoint:** `GET /analytics/content/:contentId`

**Description:** Retrieves performance metrics for a specific content piece

**Response:**
```json
{
  "success": true,
  "data": {
    "contentId": "cnt_123456",
    "aggregateMetrics": {
      "totalImpressions": 3450,
      "totalEngagements": 127,
      "totalClicks": 43,
      "conversionRate": 0.0124
    },
    "platformMetrics": {
      "linkedin": {
        "impressions": 2200,
        "likes": 75,
        "comments": 12,
        "shares": 8,
        "clicks": 35,
        "applicationStarts": 12
      },
      "instagram": {
        "impressions": 1250,
        "likes": 32,
        "comments": 0,
        "shares": 0,
        "clicks": 8,
        "applicationStarts": 2
      }
    },
    "timeSeriesData": [
      {
        "date": "2025-03-15",
        "metrics": {
          "impressions": 2800,
          "engagements": 95,
          "clicks": 30
        }
      },
      {
        "date": "2025-03-16",
        "metrics": {
          "impressions": 650,
          "engagements": 32,
          "clicks": 13
        }
      }
    ]
  }
}
```

### Get System Performance

**Endpoint:** `GET /analytics/system`

**Description:** Retrieves system performance metrics

**Response:**
```json
{
  "success": true,
  "data": {
    "processingMetrics": {
      "averageImageGenerationTime": 18.5, // seconds
      "averageApprovalTime": 3.2, // hours
      "contentProcessedLast24h": 32,
      "successRate": 0.965
    },
    "apiMetrics": {
      "totalRequests": 12450,
      "averageResponseTime": 235, // ms
      "errorRate": 0.021,
      "topEndpoints": [
        {
          "endpoint": "/generation/content",
          "requests": 4250,
          "averageResponseTime": 310
        },
        {
          "endpoint": "/approval/status",
          "requests": 3120,
          "averageResponseTime": 120
        }
      ]
    },
    "timeRange": {
      "from": "2025-03-05T00:00:00Z",
      "to": "2025-03-12T00:00:00Z"
    }
  }
}
```

## Batch Operations API

Handles bulk operations for efficiency.

### Batch Content Generation

**Endpoint:** `POST /batch/generate`

**Description:** Creates multiple content pieces in a single request

**Request:**
```json
{
  "companyId": "rec123456",
  "contentItems": [
    {
      "jobPostId": "rec789012",
      "contentType": "social_post",
      "platform": "linkedin"
    },
    {
      "jobPostId": "rec789012",
      "contentType": "social_post",
      "platform": "instagram"
    },
    {
      "jobPostId": "rec789013",
      "contentType": "social_post",
      "platform": "linkedin"
    }
  ],
  "generationOptions": {
    "useAiGeneration": true,
    "consistentImageStyle": true
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "batchId": "bat_123456",
    "itemCount": 3,
    "status": "processing",
    "contentIds": [
      "cnt_123456",
      "cnt_123457",
      "cnt_123458"
    ],
    "estimatedCompletionTime": "2025-03-12T16:30:00Z"
  }
}
```

### Batch Approval Status

**Endpoint:** `GET /batch/approval-status`

**Description:** Retrieves status of multiple approval requests

**Request:**
```json
{
  "approvalIds": [
    "apr_123456",
    "apr_123457",
    "apr_123458"
  ]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "statuses": [
      {
        "approvalId": "apr_123456",
        "status": "approved",
        "completedAt": "2025-03-12T15:30:45Z"
      },
      {
        "approvalId": "apr_123457",
        "status": "pending",
        "waitingForApprovers": ["U234567"]
      },
      {
        "approvalId": "apr_123458",
        "status": "revision_requested",
        "feedback": "Text needs to be more visible"
      }
    ]
  }
}
```

## Webhook Configuration API

Manages external service webhook configurations.

### Register Webhook

**Endpoint:** `POST /webhooks/config`

**Description:** Registers a new webhook endpoint for notification events

**Request:**
```json
{
  "name": "Content Completion Notifier",
  "targetUrl": "https://example.com/synapse-webhook",
  "events": [
    "content.generated",
    "approval.completed",
    "distribution.posted"
  ],
  "secretKey": "whsk_1234567890abcdef",
  "active": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "webhookId": "wh_123456",
    "status": "active",
    "created": "2025-03-12T17:00:23Z"
  }
}
```

### List Registered Webhooks

**Endpoint:** `GET /webhooks/config`

**Description:** Lists all registered webhooks

**Response:**
```json
{
  "success": true,
  "data": {
    "webhooks": [
      {
        "webhookId": "wh_123456",
        "name": "Content Completion Notifier",
        "targetUrl": "https://example.com/synapse-webhook",
        "events": [
          "content.generated",
          "approval.completed",
          "distribution.posted"
        ],
        "status": "active",
        "lastTriggered": "2025-03-12T17:10:45Z",
        "created": "2025-03-12T17:00:23Z"
      },
      {
        "webhookId": "wh_123457",
        "name": "Error Monitor",
        "targetUrl": "https://monitor.example.com/errors",
        "events": [
          "system.error"
        ],
        "status": "active",
        "lastTriggered": null,
        "created": "2025-03-10T09:32:15Z"
      }
    ]
  }
}
```

## Health and Monitoring API

Provides system health monitoring endpoints.

### System Health Check

**Endpoint:** `GET /health`

**Description:** Returns the current health status of the system and its dependencies

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "uptime": 324567, // seconds
    "version": "1.0.2",
    "dependencies": {
      "airtable": {
        "status": "healthy",
        "latency": 145 // ms
      },
      "imageGeneration": {
        "status": "healthy",
        "latency": 320 // ms
      },
      "slack": {
        "status": "healthy",
        "latency": 89 // ms
      },
      "cloudinary": {
        "status": "healthy",
        "latency": 112 // ms
      },
      "make": {
        "status": "healthy",
        "latency": 203 // ms
      }
    },
    "resources": {
      "cpuUsage": 0.32, // 32%
      "memoryUsage": 0.45, // 45%
      "diskSpace": 0.23 // 23% used
    }
  }
}
```

### Service Status History

**Endpoint:** `GET /health/history`

**Description:** Returns historical service status information

**Response:**
```json
{
  "success": true,
  "data": {
    "history": [
      {
        "timestamp": "2025-03-12T12:00:00Z",
        "status": "healthy",
        "incidents": []
      },
      {
        "timestamp": "2025-03-12T06:00:00Z",
        "status": "degraded",
        "incidents": [
          {
            "service": "imageGeneration",
            "status": "degraded",
            "message": "Increased latency in image generation service"
          }
        ]
      },
      {
        "timestamp": "2025-03-12T00:00:00Z",
        "status": "healthy",
        "incidents": []
      }
    ],
    "uptime24h": 0.994, // 99.4%
    "uptime7d": 0.998, // 99.8%
    "uptime30d": 0.997 // 99.7%
  }
}
```

## Rate Limiting Information

All API endpoints are subject to rate limiting to ensure system stability.

- **Standard Tier:**
  - 100 requests per minute
  - 10,000 requests per day
  - 5 concurrent requests

- **Premium Tier:**
  - 500 requests per minute
  - 50,000 requests per day
  - 20 concurrent requests

Rate limit information is included in response headers:
- `X-RateLimit-Limit`: Maximum requests per period
- `X-RateLimit-Remaining`: Remaining requests in current period
- `X-RateLimit-Reset`: Time in seconds until rate limit resets

When rate limits are exceeded, the API returns a `429 Too Many Requests` status code with a response body containing the estimated time to wait before retrying.

## Versioning Strategy

The API uses URI versioning (e.g., `/v1/resource`). When significant changes are made, a new version will be released and the old version will be supported for at least 6 months after deprecation notice.

Changes that don't break existing integrations may be added to the current version. All changes are documented in the changelog available at `/changelog`.

---

This expanded documentation provides comprehensive coverage of the Synapse API's capabilities, offering developers the information they need to integrate with and utilize the system effectively.