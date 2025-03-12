import { Job } from '../../models';
import { BaseRepository } from './BaseRepository';

/**
 * Repository interface for Job entities
 * Extends the BaseRepository with Job-specific methods
 */
export interface JobRepository extends BaseRepository<Job> {
  /**
   * Find jobs by brand ID
   * @param brandId The ID of the brand associated with the jobs
   * @returns A promise that resolves to an array of jobs
   */
  findByBrandId(brandId: string): Promise<Job[]>;
  
  /**
   * Find active jobs
   * @param limit Optional limit on the number of jobs to return
   * @returns A promise that resolves to an array of active jobs
   */
  findActiveJobs(limit?: number): Promise<Job[]>;
  
  /**
   * Find jobs by department
   * @param department The department to filter by
   * @returns A promise that resolves to an array of jobs
   */
  findByDepartment(department: string): Promise<Job[]>;
  
  /**
   * Find jobs by location
   * @param location The location to filter by
   * @returns A promise that resolves to an array of jobs
   */
  findByLocation(location: string): Promise<Job[]>;
  
  /**
   * Search jobs by keyword
   * @param keyword The keyword to search for in title and description
   * @returns A promise that resolves to an array of matching jobs
   */
  searchByKeyword(keyword: string): Promise<Job[]>;
  
  /**
   * Generate job posting content
   * @param jobId The ID of the job
   * @returns A promise that resolves to the ID of the generated content
   */
  generateJobPostingContent(jobId: string): Promise<string | null>;
  
  /**
   * Update job status
   * @param jobId The ID of the job
   * @param isActive Whether the job is active
   * @returns A promise that resolves to the updated job
   */
  updateJobStatus(jobId: string, isActive: boolean): Promise<Job | null>;
  
  /**
   * Get job posting statistics
   * @returns A promise that resolves to statistics about job postings
   */
  getJobStatistics(): Promise<{
    totalJobs: number;
    activeJobs: number;
    byDepartment: Record<string, number>;
    byLocation: Record<string, number>;
    averageSalary?: number;
  }>;
}