import { Configuration, OpenAIApi } from 'openai';
import config from '../config';

/**
 * Service for interacting with OpenAI API
 * Handles text generation, image generation, and other AI tasks
 */
export class OpenAIService {
  private openai: OpenAIApi;
  
  /**
   * Constructor - initializes OpenAI API client
   */
  constructor() {
    const configuration = new Configuration({
      apiKey: config.OPENAI.API_KEY
    });
    
    this.openai = new OpenAIApi(configuration);
  }
  
  /**
   * Generate text using GPT-4
   * @param prompt The prompt to generate text from
   * @param maxTokens Optional maximum number of tokens to generate
   * @param temperature Optional temperature (randomness) for generation
   * @returns A promise that resolves to the generated text
   */
  public async generateText(
    prompt: string,
    maxTokens = 500,
    temperature = 0.7
  ): Promise<string> {
    try {
      const response = await this.openai.createChatCompletion({
        model: config.OPENAI.MODELS.TEXT,
        messages: [{ role: 'user', content: prompt }],
        max_tokens: maxTokens,
        temperature: temperature,
        n: 1
      });
      
      // Extract and return the generated text
      const generatedText = response.data.choices[0]?.message?.content?.trim() || '';
      return generatedText;
    } catch (error) {
      console.error('Error generating text with OpenAI:', error);
      throw error;
    }
  }
  
  /**
   * Generate an image using DALL-E
   * @param prompt The prompt to generate an image from
   * @param size Optional image size
   * @returns A promise that resolves to the generated image URL
   */
  public async generateImage(
    prompt: string,
    size: '256x256' | '512x512' | '1024x1024' | '1792x1024' | '1024x1792' = '1024x1024'
  ): Promise<{ url: string }> {
    try {
      // Sanitize prompt for better results
      const sanitizedPrompt = this.sanitizeImagePrompt(prompt);
      
      // Generate image with OpenAI
      const response = await this.openai.createImage({
        prompt: sanitizedPrompt,
        n: 1,
        size: size as any, // Cast to any to bypass type checking for size
        response_format: 'url'
      });
      
      // Return the image URL
      return {
        url: response.data.data[0].url || ''
      };
    } catch (error) {
      console.error('Error generating image with OpenAI:', error);
      throw error;
    }
  }
  
  /**
   * Generate job description
   * @param jobTitle The job title
   * @param industry The industry
   * @param location The job location
   * @param keyResponsibilities Optional key responsibilities
   * @returns A promise that resolves to the generated job description
   */
  public async generateJobDescription(
    jobTitle: string,
    industry: string,
    location: string,
    keyResponsibilities?: string[]
  ): Promise<{
    description: string;
    responsibilities: string[];
    requirements: string[];
    benefits: string[];
  }> {
    try {
      // Build prompt
      let prompt = `Create a professional job description for a ${jobTitle} position`;
      prompt += ` in the ${industry} industry`;
      prompt += ` located in ${location}.`;
      
      if (keyResponsibilities && keyResponsibilities.length > 0) {
        prompt += ` The role must include these key responsibilities: ${keyResponsibilities.join(', ')}.`;
      }
      
      prompt += ` Please format the response as JSON with the following keys: description (a paragraph overview), responsibilities (an array of strings), requirements (an array of strings), and benefits (an array of strings).`;
      
      // Generate job description
      const generatedText = await this.generateText(prompt, 1000, 0.7);
      
      // Parse the JSON response
      try {
        // Extract JSON from the response
        const jsonMatch = generatedText.match(/\{[\s\S]*\}/);
        
        if (!jsonMatch) {
          throw new Error('Failed to parse JSON from response');
        }
        
        const jsonResponse = JSON.parse(jsonMatch[0]);
        
        return {
          description: jsonResponse.description || '',
          responsibilities: jsonResponse.responsibilities || [],
          requirements: jsonResponse.requirements || [],
          benefits: jsonResponse.benefits || []
        };
      } catch (parseError) {
        console.error('Error parsing job description JSON:', parseError);
        
        // Fallback to providing the raw text
        return {
          description: generatedText,
          responsibilities: [],
          requirements: [],
          benefits: []
        };
      }
    } catch (error) {
      console.error('Error generating job description:', error);
      throw error;
    }
  }
  
  /**
   * Generate social media post for job
   * @param jobTitle The job title
   * @param company The company name
   * @param location The job location
   * @param keyPoints Optional key points about the job
   * @param tone Optional tone for the post
   * @returns A promise that resolves to the generated post
   */
  public async generateJobPost(
    jobTitle: string,
    company: string,
    location: string,
    keyPoints?: string[],
    tone: 'professional' | 'casual' | 'enthusiastic' | 'informative' = 'professional'
  ): Promise<{
    shortText: string;
    longText: string;
    hashtags: string[];
  }> {
    try {
      // Build prompt
      let prompt = `Create a social media post announcing a ${jobTitle} position at ${company} in ${location}.`;
      
      if (keyPoints && keyPoints.length > 0) {
        prompt += ` Include these key points: ${keyPoints.join(', ')}.`;
      }
      
      prompt += ` The tone should be ${tone}.`;
      prompt += ` Please format the response as JSON with the following keys: shortText (under 150 chars for Twitter), longText (under 500 chars for LinkedIn/Facebook), and hashtags (an array of relevant hashtags).`;
      
      // Generate post
      const generatedText = await this.generateText(prompt, 800, 0.7);
      
      // Parse the JSON response
      try {
        // Extract JSON from the response
        const jsonMatch = generatedText.match(/\{[\s\S]*\}/);
        
        if (!jsonMatch) {
          throw new Error('Failed to parse JSON from response');
        }
        
        const jsonResponse = JSON.parse(jsonMatch[0]);
        
        return {
          shortText: jsonResponse.shortText || '',
          longText: jsonResponse.longText || '',
          hashtags: jsonResponse.hashtags || []
        };
      } catch (parseError) {
        console.error('Error parsing job post JSON:', parseError);
        
        // Fallback to providing the raw text
        return {
          shortText: generatedText.substring(0, 150),
          longText: generatedText,
          hashtags: ['#job', '#career', '#hiring']
        };
      }
    } catch (error) {
      console.error('Error generating job post:', error);
      throw error;
    }
  }
  
  /**
   * Extract color palette from image
   * @param imageUrl The image URL
   * @returns A promise that resolves to the extracted colors
   */
  public async extractColorPalette(imageUrl: string): Promise<string[]> {
    try {
      // Build prompt
      const prompt = `Analyze the image at ${imageUrl} and extract the main color palette. Provide the colors as an array of hex codes. Give me just the JSON array, nothing else.`;
      
      // Generate palette description
      const generatedText = await this.generateText(prompt, 300, 0.3);
      
      // Try to parse JSON array of colors
      try {
        // Extract JSON array from the response
        const jsonMatch = generatedText.match(/\[[\s\S]*\]/);
        
        if (!jsonMatch) {
          throw new Error('Failed to parse JSON from response');
        }
        
        const colorArray = JSON.parse(jsonMatch[0]);
        
        if (Array.isArray(colorArray) && colorArray.length > 0) {
          return colorArray;
        }
        
        throw new Error('Invalid color array');
      } catch (parseError) {
        console.error('Error parsing color palette JSON:', parseError);
        
        // Fallback to extracting hex codes with regex
        const hexCodes = generatedText.match(/#[0-9A-Fa-f]{6}/g) || [];
        return Array.from(new Set(hexCodes)); // Remove duplicates
      }
    } catch (error) {
      console.error('Error extracting color palette:', error);
      return []; // Return empty array on error
    }
  }
  
  /**
   * Sanitize image prompt for better results
   * @param prompt The raw prompt
   * @returns The sanitized prompt
   */
  private sanitizeImagePrompt(prompt: string): string {
    // Add quality boosters
    let sanitizedPrompt = prompt.trim();
    
    // Ensure the prompt isn't too long
    if (sanitizedPrompt.length > 1000) {
      sanitizedPrompt = sanitizedPrompt.substring(0, 1000);
    }
    
    // Add quality modifiers if they don't already exist in the prompt
    const qualityModifiers = [
      'high quality',
      'professional',
      'detailed',
      '4k',
      'realistic'
    ];
    
    let containsQualityModifier = false;
    
    for (const modifier of qualityModifiers) {
      if (sanitizedPrompt.toLowerCase().includes(modifier.toLowerCase())) {
        containsQualityModifier = true;
        break;
      }
    }
    
    if (!containsQualityModifier) {
      sanitizedPrompt += ', high quality, professional';
    }
    
    return sanitizedPrompt;
  }
}