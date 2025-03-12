export interface Job {
  id?: string;
  brandId: string;
  title: string;
  location: string;
  department?: string;
  description: string;
  responsibilities?: string[];
  requirements?: string[];
  benefits?: string[];
  salary?: {
    min?: number;
    max?: number;
    currency?: string;
    period?: 'hourly' | 'monthly' | 'yearly';
  };
  employmentType?: 'full-time' | 'part-time' | 'contract' | 'temporary' | 'internship';
  skills?: string[];
  status?: 'active' | 'inactive' | 'draft' | 'expired';
  postDate?: Date;
  expiryDate?: Date;
  externalJobId?: string;
  applyUrl?: string;
  contactEmail?: string;
  isRemote?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}