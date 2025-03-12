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
    period?: 'hourly' | 'annually';
  };
  applicationUrl?: string;
  contactEmail?: string;
  isRemote?: boolean;
  isActive?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}