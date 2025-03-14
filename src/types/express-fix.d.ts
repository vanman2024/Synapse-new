import { Express, Request, Response, NextFunction } from 'express';

// Extending Express Request and Response types to ensure type safety
declare global {
  namespace Express {
    // Add any custom properties to Request type
    interface Request {
      userId?: string;
      userRole?: string;
      // Add other custom properties as needed
    }

    // Add any custom properties to Response type
    interface Response {
      // Add custom response methods as needed
      customMethod?: () => void;
    }
  }
}

// No explicit export needed as this is a declaration file
export {};