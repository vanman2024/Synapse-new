import { Request, Response } from 'express';
import { AirtableJobRepository } from '../../repositories/implementations';
import { Job } from '../../models';
import Joi from 'joi';

/**
 * Controller for job-related API endpoints
 */
export class JobController {
  private jobRepository: AirtableJobRepository;

  /**
   * Constructor
   */
  constructor() {
    this.jobRepository = new AirtableJobRepository();
  }

  /**
   * Get all jobs
   * @param req Express request
   * @param res Express response
   */
  public getAllJobs = async (req: Request, res: Response): Promise<void> => {
    try {
      const { keyword, department, location, brand } = req.query;
      
      // If search parameters are provided, use appropriate search methods
      if (keyword && typeof keyword === 'string') {
        const jobs = await this.jobRepository.searchByKeyword(keyword);
        res.status(200).json({ success: true, data: jobs });
        return;
      }
      
      if (department && typeof department === 'string') {
        const jobs = await this.jobRepository.findByDepartment(department);
        res.status(200).json({ success: true, data: jobs });
        return;
      }
      
      if (location && typeof location === 'string') {
        const jobs = await this.jobRepository.findByLocation(location);
        res.status(200).json({ success: true, data: jobs });
        return;
      }
      
      if (brand && typeof brand === 'string') {
        const jobs = await this.jobRepository.findByBrandId(brand);
        res.status(200).json({ success: true, data: jobs });
        return;
      }
      
      // Default: get all jobs
      const jobs = await this.jobRepository.findAll();
      res.status(200).json({ success: true, data: jobs });
    } catch (error) {
      console.error('Error getting jobs:', error);
      res.status(500).json({ success: false, error: 'Failed to get jobs' });
    }
  };

  /**
   * Get active jobs
   * @param req Express request
   * @param res Express response
   */
  public getActiveJobs = async (req: Request, res: Response): Promise<void> => {
    try {
      const limitParam = req.query.limit;
      const limit = limitParam ? parseInt(limitParam as string, 10) : undefined;
      
      const jobs = await this.jobRepository.findActiveJobs(limit);
      res.status(200).json({ success: true, data: jobs });
    } catch (error) {
      console.error('Error getting active jobs:', error);
      res.status(500).json({ success: false, error: 'Failed to get active jobs' });
    }
  };

  /**
   * Get a job by ID
   * @param req Express request
   * @param res Express response
   */
  public getJobById = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      const job = await this.jobRepository.findById(id);

      if (!job) {
        res.status(404).json({ success: false, error: 'Job not found' });
        return;
      }

      res.status(200).json({ success: true, data: job });
    } catch (error) {
      console.error(`Error getting job with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to get job' });
    }
  };

  /**
   * Create a new job
   * @param req Express request
   * @param res Express response
   */
  public createJob = async (req: Request, res: Response): Promise<void> => {
    try {
      // Validate request body
      const schema = Joi.object({
        brandId: Joi.string().required(),
        title: Joi.string().required(),
        location: Joi.string().required(),
        department: Joi.string(),
        description: Joi.string().required(),
        responsibilities: Joi.array().items(Joi.string()),
        requirements: Joi.array().items(Joi.string()),
        benefits: Joi.array().items(Joi.string()),
        salary: Joi.object({
          min: Joi.number(),
          max: Joi.number(),
          currency: Joi.string(),
          period: Joi.string().valid('hourly', 'monthly', 'yearly')
        }),
        employmentType: Joi.string().valid(
          'full-time', 'part-time', 'contract', 'temporary', 'internship'
        ),
        skills: Joi.array().items(Joi.string()),
        status: Joi.string().valid('active', 'inactive', 'draft', 'expired'),
        postDate: Joi.date(),
        expiryDate: Joi.date(),
        externalJobId: Joi.string(),
        applyUrl: Joi.string().uri(),
        contactEmail: Joi.string().email(),
        isRemote: Joi.boolean()
      });

      const { error, value } = schema.validate(req.body);

      if (error) {
        res.status(400).json({ success: false, error: error.details[0].message });
        return;
      }

      // Create job
      const job = await this.jobRepository.create(value as Omit<Job, 'id' | 'createdAt' | 'updatedAt'>);

      res.status(201).json({ success: true, data: job });
    } catch (error) {
      console.error('Error creating job:', error);
      res.status(500).json({ success: false, error: 'Failed to create job' });
    }
  };

  /**
   * Update a job
   * @param req Express request
   * @param res Express response
   */
  public updateJob = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      // Validate request body
      const schema = Joi.object({
        brandId: Joi.string(),
        title: Joi.string(),
        location: Joi.string(),
        department: Joi.string(),
        description: Joi.string(),
        responsibilities: Joi.array().items(Joi.string()),
        requirements: Joi.array().items(Joi.string()),
        benefits: Joi.array().items(Joi.string()),
        salary: Joi.object({
          min: Joi.number(),
          max: Joi.number(),
          currency: Joi.string(),
          period: Joi.string().valid('hourly', 'monthly', 'yearly')
        }),
        employmentType: Joi.string().valid(
          'full-time', 'part-time', 'contract', 'temporary', 'internship'
        ),
        skills: Joi.array().items(Joi.string()),
        status: Joi.string().valid('active', 'inactive', 'draft', 'expired'),
        postDate: Joi.date(),
        expiryDate: Joi.date(),
        externalJobId: Joi.string(),
        applyUrl: Joi.string().uri(),
        contactEmail: Joi.string().email(),
        isRemote: Joi.boolean()
      });

      const { error, value } = schema.validate(req.body);

      if (error) {
        res.status(400).json({ success: false, error: error.details[0].message });
        return;
      }

      // Check if job exists
      const existingJob = await this.jobRepository.findById(id);

      if (!existingJob) {
        res.status(404).json({ success: false, error: 'Job not found' });
        return;
      }

      // Update job
      const updatedJob = await this.jobRepository.update(id, value);

      if (!updatedJob) {
        res.status(500).json({ success: false, error: 'Failed to update job' });
        return;
      }

      res.status(200).json({ success: true, data: updatedJob });
    } catch (error) {
      console.error(`Error updating job with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to update job' });
    }
  };

  /**
   * Delete a job
   * @param req Express request
   * @param res Express response
   */
  public deleteJob = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      // Check if job exists
      const existingJob = await this.jobRepository.findById(id);

      if (!existingJob) {
        res.status(404).json({ success: false, error: 'Job not found' });
        return;
      }

      // Delete job
      const deleted = await this.jobRepository.delete(id);

      if (!deleted) {
        res.status(500).json({ success: false, error: 'Failed to delete job' });
        return;
      }

      res.status(200).json({ success: true, data: { message: 'Job deleted successfully' } });
    } catch (error) {
      console.error(`Error deleting job with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to delete job' });
    }
  };

  /**
   * Update job status
   * @param req Express request
   * @param res Express response
   */
  public updateJobStatus = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;
      const { isActive } = req.body;

      // Validate request body
      if (isActive === undefined) {
        res.status(400).json({ success: false, error: 'isActive field is required' });
        return;
      }

      // Update job status
      const updatedJob = await this.jobRepository.updateJobStatus(id, isActive);

      if (!updatedJob) {
        res.status(404).json({ success: false, error: 'Job not found or could not be updated' });
        return;
      }

      res.status(200).json({ success: true, data: updatedJob });
    } catch (error) {
      console.error(`Error updating status for job with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to update job status' });
    }
  };

  /**
   * Generate job posting content
   * @param req Express request
   * @param res Express response
   */
  public generateContent = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      // Generate content
      const contentId = await this.jobRepository.generateJobPostingContent(id);

      if (!contentId) {
        res.status(500).json({ success: false, error: 'Failed to generate content' });
        return;
      }

      res.status(200).json({ 
        success: true, 
        data: { 
          contentId,
          message: 'Content generated successfully'
        } 
      });
    } catch (error) {
      console.error(`Error generating content for job with ID ${req.params.id}:`, error);
      res.status(500).json({ success: false, error: 'Failed to generate content' });
    }
  };

  /**
   * Get job statistics
   * @param req Express request
   * @param res Express response
   */
  public getJobStatistics = async (req: Request, res: Response): Promise<void> => {
    try {
      const statistics = await this.jobRepository.getJobStatistics();
      res.status(200).json({ success: true, data: statistics });
    } catch (error) {
      console.error('Error getting job statistics:', error);
      res.status(500).json({ success: false, error: 'Failed to get job statistics' });
    }
  };
}