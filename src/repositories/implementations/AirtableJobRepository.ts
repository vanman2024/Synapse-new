import { FieldSet } from 'airtable/lib/field_set';
import { Job } from '../../models';
import { JobRepository } from '../interfaces/JobRepository';
import { AirtableClient } from '../../data-sources/airtable/AirtableClient';
import config from '../../config';
import { OpenAIService } from '../../services/OpenAIService';

/**
 * Airtable implementation of the Job repository
 */
export class AirtableJobRepository implements JobRepository {
  private readonly airtable: AirtableClient;
  private readonly tableName: string;
  private readonly openai: OpenAIService;

  /**
   * Constructor
   */
  constructor() {
    this.airtable = AirtableClient.getInstance();
    this.tableName = config.AIRTABLE.TABLES.JOB_POSTS;
    this.openai = new OpenAIService();
  }

  /**
   * Convert an Airtable record to a Job object
   * @param record The Airtable record
   * @returns A Job object
   */
  private mapRecordToJob(record: Record<string, any>): Job {
    return {
      id: record.id,
      brandId: record.CompanyId ? record.CompanyId[0] : '',
      title: record.Title,
      location: record.Location,
      department: record.Department,
      description: record.Description,
      responsibilities: record.Responsibilities ? 
        (Array.isArray(record.Responsibilities) ? record.Responsibilities : [record.Responsibilities]) : 
        [],
      requirements: record.Requirements ? 
        (Array.isArray(record.Requirements) ? record.Requirements : [record.Requirements]) : 
        [],
      benefits: record.Benefits ? 
        (Array.isArray(record.Benefits) ? record.Benefits : [record.Benefits]) : 
        [],
      salary: {
        min: record.SalaryMin ? Number(record.SalaryMin) : undefined,
        max: record.SalaryMax ? Number(record.SalaryMax) : undefined,
        currency: record.SalaryCurrency || 'USD',
        period: record.SalaryPeriod || 'yearly'
      },
      employmentType: record.EmploymentType || 'full-time',
      skills: record.Skills ? 
        (Array.isArray(record.Skills) ? record.Skills : [record.Skills]) : 
        [],
      status: record.Status || 'active',
      postDate: record.PostDate ? new Date(record.PostDate) : new Date(),
      expiryDate: record.ExpiryDate ? new Date(record.ExpiryDate) : undefined,
      externalJobId: record.ExternalJobId,
      applyUrl: record.ApplyUrl,
      contactEmail: record.ContactEmail,
      isRemote: record.IsRemote === true || record.IsRemote === 'true',
      createdAt: new Date(record.CreatedAt || record._createdTime),
      updatedAt: new Date(record.UpdatedAt || record._updatedTime)
    };
  }

  /**
   * Convert a Job object to an Airtable record
   * @param job The Job object
   * @returns An Airtable record
   */
  private mapJobToRecord(job: Partial<Job>): Partial<FieldSet> {
    const record: Partial<FieldSet> = {};

    if (job.brandId) record.CompanyId = [job.brandId];
    if (job.title) record.Title = job.title;
    if (job.location) record.Location = job.location;
    if (job.department) record.Department = job.department;
    if (job.description) record.Description = job.description;
    if (job.responsibilities) record.Responsibilities = job.responsibilities;
    if (job.requirements) record.Requirements = job.requirements;
    if (job.benefits) record.Benefits = job.benefits;

    if (job.salary) {
      if (job.salary.min !== undefined) record.SalaryMin = job.salary.min;
      if (job.salary.max !== undefined) record.SalaryMax = job.salary.max;
      if (job.salary.currency) record.SalaryCurrency = job.salary.currency;
      if (job.salary.period) record.SalaryPeriod = job.salary.period;
    }

    if (job.employmentType) record.EmploymentType = job.employmentType;
    if (job.skills) record.Skills = job.skills;
    if (job.status) record.Status = job.status;
    if (job.postDate) record.PostDate = job.postDate.toISOString().split('T')[0];
    if (job.expiryDate) record.ExpiryDate = job.expiryDate.toISOString().split('T')[0];
    if (job.externalJobId) record.ExternalJobId = job.externalJobId;
    if (job.applyUrl) record.ApplyUrl = job.applyUrl;
    if (job.contactEmail) record.ContactEmail = job.contactEmail;
    if (job.isRemote !== undefined) record.IsRemote = job.isRemote;
    
    record.UpdatedAt = new Date().toISOString();

    return record;
  }

  /**
   * Find a job by its ID
   * @param id The job ID
   * @returns A promise that resolves to the job or null if not found
   */
  public async findById(id: string): Promise<Job | null> {
    try {
      const record = await this.airtable.findById(this.tableName, id);
      return this.mapRecordToJob({ id: record.id, ...record.fields });
    } catch (error) {
      console.error('Error finding job by ID:', error);
      return null;
    }
  }

  /**
   * Find all jobs that match the given filter criteria
   * @param filter Optional filter criteria
   * @returns A promise that resolves to an array of jobs
   */
  public async findAll(filter?: Partial<Job>): Promise<Job[]> {
    try {
      // Build filter formula if filter is provided
      let filterFormula = '';

      if (filter) {
        const conditions = [];

        if (filter.brandId) {
          conditions.push(`SEARCH("${filter.brandId}", {CompanyId})`);
        }

        if (filter.title) {
          conditions.push(`{Title} = "${filter.title}"`);
        }

        if (filter.location) {
          conditions.push(`{Location} = "${filter.location}"`);
        }

        if (filter.department) {
          conditions.push(`{Department} = "${filter.department}"`);
        }

        if (filter.status) {
          conditions.push(`{Status} = "${filter.status}"`);
        }

        if (conditions.length > 0) {
          filterFormula = `AND(${conditions.join(', ')})`;
        }
      }

      // Get records from Airtable
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula || '',
        sort: [{ field: 'PostDate', direction: 'desc' }]
      });

      // Map records to Job objects
      return records.map(record => this.mapRecordToJob({ id: record.id, ...record.fields }));
    } catch (error) {
      console.error('Error finding jobs:', error);
      return [];
    }
  }

  /**
   * Create a new job
   * @param job The job data
   * @returns A promise that resolves to the created job
   */
  public async create(job: Omit<Job, 'id' | 'createdAt' | 'updatedAt'>): Promise<Job> {
    try {
      // Map job to Airtable record
      const record = this.mapJobToRecord(job);

      // Add created date
      record.CreatedAt = new Date().toISOString();
      record.UpdatedAt = record.CreatedAt;

      if (!record.PostDate) {
        record.PostDate = new Date().toISOString().split('T')[0];
      }

      if (!record.Status) {
        record.Status = 'active';
      }

      // Create record in Airtable
      const createdRecord = await this.airtable.create(this.tableName, record);

      // Return created job
      return this.mapRecordToJob({ id: createdRecord.id, ...createdRecord.fields });
    } catch (error) {
      console.error('Error creating job:', error);
      throw error;
    }
  }

  /**
   * Update an existing job
   * @param id The job ID
   * @param job The job data to update
   * @returns A promise that resolves to the updated job
   */
  public async update(id: string, job: Partial<Job>): Promise<Job | null> {
    try {
      // Check if job exists
      const existingJob = await this.findById(id);

      if (!existingJob) {
        return null;
      }

      // Map job to Airtable record
      const record = this.mapJobToRecord(job);

      // Update record in Airtable
      const updatedRecord = await this.airtable.update(this.tableName, id, record);

      // Return updated job
      return this.mapRecordToJob({ id: updatedRecord.id, ...updatedRecord.fields });
    } catch (error) {
      console.error(`Error updating job ${id}:`, error);
      return null;
    }
  }

  /**
   * Delete a job
   * @param id The job ID
   * @returns A promise that resolves to true if deleted, false otherwise
   */
  public async delete(id: string): Promise<boolean> {
    try {
      await this.airtable.delete(this.tableName, id);
      return true;
    } catch (error) {
      console.error(`Error deleting job ${id}:`, error);
      return false;
    }
  }

  /**
   * Find jobs by brand ID
   * @param brandId The brand ID
   * @returns A promise that resolves to an array of jobs
   */
  public async findByBrandId(brandId: string): Promise<Job[]> {
    try {
      // Get records from Airtable
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: `SEARCH("${brandId}", {CompanyId})`,
        sort: [{ field: 'PostDate', direction: 'desc' }]
      });

      // Map records to Job objects
      return records.map(record => this.mapRecordToJob({ id: record.id, ...record.fields }));
    } catch (error) {
      console.error(`Error finding jobs for brand ${brandId}:`, error);
      return [];
    }
  }

  /**
   * Find active jobs
   * @param limit Optional limit on the number of jobs to return
   * @returns A promise that resolves to an array of active jobs
   */
  public async findActiveJobs(limit?: number): Promise<Job[]> {
    try {
      // Get records from Airtable
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: `{Status} = "active"`,
        sort: [{ field: 'PostDate', direction: 'desc' }],
        maxRecords: limit
      });

      // Map records to Job objects
      return records.map(record => this.mapRecordToJob({ id: record.id, ...record.fields }));
    } catch (error) {
      console.error('Error finding active jobs:', error);
      return [];
    }
  }

  /**
   * Find jobs by department
   * @param department The department to filter by
   * @returns A promise that resolves to an array of jobs
   */
  public async findByDepartment(department: string): Promise<Job[]> {
    try {
      // Get records from Airtable
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: `{Department} = "${department}"`,
        sort: [{ field: 'PostDate', direction: 'desc' }]
      });

      // Map records to Job objects
      return records.map(record => this.mapRecordToJob({ id: record.id, ...record.fields }));
    } catch (error) {
      console.error(`Error finding jobs for department ${department}:`, error);
      return [];
    }
  }

  /**
   * Find jobs by location
   * @param location The location to filter by
   * @returns A promise that resolves to an array of jobs
   */
  public async findByLocation(location: string): Promise<Job[]> {
    try {
      // Get records from Airtable
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: `{Location} = "${location}"`,
        sort: [{ field: 'PostDate', direction: 'desc' }]
      });

      // Map records to Job objects
      return records.map(record => this.mapRecordToJob({ id: record.id, ...record.fields }));
    } catch (error) {
      console.error(`Error finding jobs for location ${location}:`, error);
      return [];
    }
  }

  /**
   * Search jobs by keyword
   * @param keyword The keyword to search for
   * @returns A promise that resolves to an array of matching jobs
   */
  public async searchByKeyword(keyword: string): Promise<Job[]> {
    try {
      // Search in title, description, and responsibilities
      const filterFormula = `OR(
        SEARCH("${keyword}", {Title}),
        SEARCH("${keyword}", {Description}),
        SEARCH("${keyword}", {Responsibilities}),
        SEARCH("${keyword}", {Requirements})
      )`;

      // Get records from Airtable
      const records = await this.airtable.select(this.tableName, {
        filterByFormula: filterFormula,
        sort: [{ field: 'PostDate', direction: 'desc' }]
      });

      // Map records to Job objects
      return records.map(record => this.mapRecordToJob({ id: record.id, ...record.fields }));
    } catch (error) {
      console.error(`Error searching jobs with keyword ${keyword}:`, error);
      return [];
    }
  }

  /**
   * Generate job posting content
   * @param jobId The ID of the job
   * @returns A promise that resolves to the ID of the generated content
   */
  public async generateJobPostingContent(jobId: string): Promise<string | null> {
    try {
      // Get job details
      const job = await this.findById(jobId);
      
      if (!job) {
        throw new Error(`Job with ID ${jobId} not found`);
      }

      // Generate social media post
      const jobPost = await this.openai.generateJobPost(
        job.title,
        job.brandId, // We would ideally get the company name here
        job.location,
        job.responsibilities
      );

      // In a real implementation, we would create a Content record here
      // For now, we'll just return a mock ID
      return `content_${Date.now()}`;
    } catch (error) {
      console.error(`Error generating job posting content for job ${jobId}:`, error);
      return null;
    }
  }

  /**
   * Update job status
   * @param jobId The ID of the job
   * @param isActive Whether the job is active
   * @returns A promise that resolves to the updated job
   */
  public async updateJobStatus(jobId: string, isActive: boolean): Promise<Job | null> {
    try {
      return await this.update(jobId, { 
        status: isActive ? 'active' : 'inactive' 
      });
    } catch (error) {
      console.error(`Error updating job status for job ${jobId}:`, error);
      return null;
    }
  }

  /**
   * Get job posting statistics
   * @returns A promise that resolves to statistics about job postings
   */
  public async getJobStatistics(): Promise<{
    totalJobs: number;
    activeJobs: number;
    byDepartment: Record<string, number>;
    byLocation: Record<string, number>;
    averageSalary?: number;
  }> {
    try {
      // Get all jobs
      const allJobs = await this.findAll();
      const activeJobs = allJobs.filter(job => job.status === 'active');

      // Compute statistics
      const departmentCounts: Record<string, number> = {};
      const locationCounts: Record<string, number> = {};
      let salarySum = 0;
      let salaryCount = 0;

      allJobs.forEach(job => {
        // Count by department
        if (job.department) {
          departmentCounts[job.department] = (departmentCounts[job.department] || 0) + 1;
        }

        // Count by location
        if (job.location) {
          locationCounts[job.location] = (locationCounts[job.location] || 0) + 1;
        }

        // Sum salaries for average calculation
        if (job.salary?.min && job.salary?.max) {
          salarySum += (job.salary.min + job.salary.max) / 2;
          salaryCount++;
        } else if (job.salary?.min) {
          salarySum += job.salary.min;
          salaryCount++;
        } else if (job.salary?.max) {
          salarySum += job.salary.max;
          salaryCount++;
        }
      });

      return {
        totalJobs: allJobs.length,
        activeJobs: activeJobs.length,
        byDepartment: departmentCounts,
        byLocation: locationCounts,
        averageSalary: salaryCount > 0 ? salarySum / salaryCount : undefined
      };
    } catch (error) {
      console.error('Error getting job statistics:', error);
      return {
        totalJobs: 0,
        activeJobs: 0,
        byDepartment: {},
        byLocation: {}
      };
    }
  }
}