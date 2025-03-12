import { Router } from 'express';
import { JobController } from '../controllers/JobController';

// Create router
const router = Router();
const jobController = new JobController();

// GET /api/jobs - Get all jobs
router.get('/', jobController.getAllJobs);

// GET /api/jobs/active - Get active jobs
router.get('/active', jobController.getActiveJobs);

// GET /api/jobs/statistics - Get job statistics
router.get('/statistics', jobController.getJobStatistics);

// GET /api/jobs/:id - Get a job by ID
router.get('/:id', jobController.getJobById);

// POST /api/jobs - Create a new job
router.post('/', jobController.createJob);

// PUT /api/jobs/:id - Update a job
router.put('/:id', jobController.updateJob);

// DELETE /api/jobs/:id - Delete a job
router.delete('/:id', jobController.deleteJob);

// PATCH /api/jobs/:id/status - Update job status
router.patch('/:id/status', jobController.updateJobStatus);

// POST /api/jobs/:id/generate-content - Generate job posting content
router.post('/:id/generate-content', jobController.generateContent);

export default router;