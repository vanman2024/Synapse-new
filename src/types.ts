// Dependency injection tokens for inversify
export const TYPES = {
  // Repositories
  BrandRepository: Symbol.for('BrandRepository'),
  JobRepository: Symbol.for('JobRepository'),
  ContentRepository: Symbol.for('ContentRepository'),
  
  // Controllers
  BrandController: Symbol.for('BrandController'),
  JobController: Symbol.for('JobController'),
  ContentController: Symbol.for('ContentController'),
  
  // Services
  CloudinaryService: Symbol.for('CloudinaryService'),
  OpenAIService: Symbol.for('OpenAIService'),
};