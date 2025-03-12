import { v2 as cloudinary } from 'cloudinary';
import { UploadApiOptions, UploadApiResponse } from 'cloudinary';
import config from '../config';

/**
 * Service for interacting with Cloudinary for image storage and processing
 */
export class CloudinaryService {
  /**
   * Constructor - configures Cloudinary SDK
   */
  constructor() {
    // Initialize Cloudinary configuration
    cloudinary.config({
      cloud_name: config.MEDIA.CLOUDINARY.CLOUD_NAME,
      api_key: config.MEDIA.CLOUDINARY.API_KEY,
      api_secret: config.MEDIA.CLOUDINARY.API_SECRET,
      secure: true
    });
  }

  /**
   * Upload an image to Cloudinary
   * @param imageData The image data (buffer or path)
   * @param folder The folder to upload to
   * @param options Additional Cloudinary upload options
   * @returns A promise that resolves to the upload response
   */
  public async uploadImage(
    imageData: Buffer | string,
    folder: string,
    options: UploadApiOptions = {}
  ): Promise<UploadApiResponse> {
    try {
      // Combine default options with provided options
      const uploadOptions: UploadApiOptions = {
        folder,
        resource_type: 'image',
        quality: 'auto:best',
        fetch_format: 'auto',
        ...options
      };

      // Handle different types of image data
      if (Buffer.isBuffer(imageData)) {
        // For Buffer, we need to create a Promise wrapper around the upload stream
        return new Promise((resolve, reject) => {
          const uploadStream = cloudinary.uploader.upload_stream(
            uploadOptions,
            (error, result) => {
              if (error) return reject(error);
              if (!result) return reject(new Error('Upload failed with no result'));
              resolve(result);
            }
          );
          
          // Convert Buffer to Stream and pipe to uploadStream
          const Readable = require('stream').Readable;
          const readableStream = new Readable();
          readableStream.push(imageData);
          readableStream.push(null);
          readableStream.pipe(uploadStream);
        });
      } else {
        // For URLs or file paths, we can use the simpler upload method
        return await cloudinary.uploader.upload(imageData, uploadOptions);
      }
    } catch (error) {
      console.error('Error uploading image to Cloudinary:', error);
      throw error;
    }
  }

  /**
   * Generate a URL with text overlay on an image
   * @param imageUrl The base image URL
   * @param text The text to overlay
   * @param options Optional styling parameters
   * @returns The URL with text overlay transformation
   */
  public generateTextOverlayUrl(
    imageUrl: string,
    text: string,
    options: {
      position?: 'center' | 'north' | 'south' | 'east' | 'west' | 'northeast' | 'northwest' | 'southeast' | 'southwest';
      fontFamily?: string;
      fontSize?: number;
      fontWeight?: 'normal' | 'bold';
      fontStyle?: 'normal' | 'italic';
      textColor?: string;
      backgroundColor?: string;
      opacity?: number;
      padding?: number;
      width?: number;
    } = {}
  ): string {
    try {
      // Set default options
      const {
        position = 'center',
        fontFamily = 'Arial',
        fontSize = 48,
        fontWeight = 'bold',
        fontStyle = 'normal',
        textColor = 'white',
        backgroundColor = '000000',
        opacity = 0.7,
        padding = 20,
        width = 1200 // Default image width
      } = options;

      // Escape text for URL
      const escapedText = encodeURIComponent(text.replace(/,/g, '\\,'));

      // Map position to Cloudinary gravity
      const gravityMap: Record<string, string> = {
        'center': 'center',
        'north': 'north',
        'south': 'south',
        'east': 'east',
        'west': 'west',
        'northeast': 'north_east',
        'northwest': 'north_west',
        'southeast': 'south_east',
        'southwest': 'south_west'
      };
      const gravity = gravityMap[position] || 'center';

      // Build the transformation string
      const transformation = [
        'w_' + width,
        'c_fill',
        'g_auto',
        'q_auto:best',
        'l_text:' + fontFamily + '_' + fontSize + '_' + fontWeight + ':' + escapedText,
        'co_' + textColor.replace('#', ''),
        'bg_' + backgroundColor.replace('#', ''),
        'bo_' + padding + 'px_solid_' + backgroundColor.replace('#', '') + opacity * 100,
        'g_' + gravity,
        'fl_relative',
        'w_0.8'
      ].join(',');

      // Check if the URL is already a Cloudinary URL
      if (imageUrl.includes('cloudinary.com')) {
        // Extract components of the existing Cloudinary URL
        const urlParts = imageUrl.split('/upload/');
        if (urlParts.length === 2) {
          // Insert our transformation into the existing URL
          return urlParts[0] + '/upload/' + transformation + '/' + urlParts[1];
        }
      }

      // For non-Cloudinary URLs, we would need to first upload the image
      // This is a fallback that assumes the image is in Cloudinary
      return imageUrl;
    } catch (error) {
      console.error('Error generating text overlay URL:', error);
      return imageUrl; // Return original URL on error
    }
  }

  /**
   * Delete an image from Cloudinary
   * @param publicId The public ID of the image to delete
   * @returns A promise that resolves to true if successful
   */
  public async deleteImage(publicId: string): Promise<boolean> {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result.result === 'ok';
    } catch (error) {
      console.error('Error deleting image from Cloudinary:', error);
      return false;
    }
  }

  /**
   * Generate an image URL with responsive settings
   * @param imageUrl The base image URL
   * @param width Optional width
   * @param height Optional height
   * @returns The responsive image URL
   */
  public getResponsiveImageUrl(
    imageUrl: string,
    width?: number,
    height?: number
  ): string {
    try {
      // Check if the URL is already a Cloudinary URL
      if (!imageUrl.includes('cloudinary.com')) {
        return imageUrl; // Return original URL if not a Cloudinary URL
      }

      // Build transformation string
      const transformations: string[] = [];
      if (width) transformations.push(`w_${width}`);
      if (height) transformations.push(`h_${height}`);
      transformations.push('c_fill');
      transformations.push('q_auto:best');
      transformations.push('f_auto');
      
      const transformation = transformations.join(',');

      // Extract components of the existing Cloudinary URL
      const urlParts = imageUrl.split('/upload/');
      if (urlParts.length === 2) {
        // Insert our transformation into the existing URL
        return urlParts[0] + '/upload/' + transformation + '/' + urlParts[1];
      }

      return imageUrl;
    } catch (error) {
      console.error('Error generating responsive image URL:', error);
      return imageUrl; // Return original URL on error
    }
  }
}