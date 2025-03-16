import { Router } from 'express';
import brandRoutes from './brand.routes';
import jobRoutes from './job.routes';
import contentRoutes from './content.routes';
// Import other routes as they're created

const router = Router();

// Mount routes
router.use('/brands', brandRoutes);
router.use('/jobs', jobRoutes);
router.use('/content', contentRoutes);
// Add other routes as they're created

export default router;