import { Router } from 'express';
import { BrandController } from '../controllers/BrandController';
import multer from 'multer';

// Configure multer for memory storage (we'll process and send to Cloudinary)
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5 MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept only image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!') as any, false);
    }
  }
});

// Create router
const router = Router();
const brandController = new BrandController();

// GET /api/brands - Get all brands
router.get('/', brandController.getAllBrands);

// GET /api/brands/content-count - Get all brands with content count
router.get('/content-count', brandController.getBrandsWithContentCount);

// GET /api/brands/:id - Get a brand by ID
router.get('/:id', brandController.getBrandById);

// POST /api/brands - Create a new brand
router.post('/', brandController.createBrand);

// PUT /api/brands/:id - Update a brand
router.put('/:id', brandController.updateBrand);

// DELETE /api/brands/:id - Delete a brand
router.delete('/:id', brandController.deleteBrand);

// POST /api/brands/:id/extract-style - Extract style from website
router.post('/:id/extract-style', brandController.extractStyleFromWebsite);

// POST /api/brands/:id/logo - Upload a logo
router.post('/:id/logo', upload.single('logo'), brandController.uploadLogo);

export default router;