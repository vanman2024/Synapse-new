import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';
import config from '../config';
import routes from './routes';

// Create Express application
const app: Application = express();

// Security middleware
app.use(helmet());

// CORS middleware
app.use(cors());

// Body parser middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
const morganFormat = config.SERVER.NODE_ENV === 'production' ? 'combined' : 'dev';
app.use(morgan(morganFormat));

// Static files
app.use('/uploads', express.static(path.join(process.cwd(), config.PATHS.UPLOAD_DIR)));

// API health check
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'ok',
    environment: config.SERVER.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api', routes);

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not Found',
    message: `The requested resource at ${req.originalUrl} was not found`
  });
});

// Error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);
  
  res.status(500).json({
    error: 'Internal Server Error',
    message: config.SERVER.NODE_ENV === 'production' 
      ? 'An unexpected error occurred' 
      : err.message
  });
});

export default app;