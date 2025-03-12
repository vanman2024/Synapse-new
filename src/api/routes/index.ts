import { Router } from 'express';
import brandRoutes from './brand.routes';
// Import other routes as they're created

const router = Router();

// Mount routes
router.use('/brands', brandRoutes);
// Add other routes as they're created

export default router;