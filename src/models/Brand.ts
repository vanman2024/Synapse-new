export interface Brand {
  id?: string;
  name: string;
  website?: string;
  colors: {
    primary: string;
    secondary: string[];
    accent: string[];
  };
  typography: {
    headingFont: string;
    bodyFont: string;
    fontSize?: {
      heading: number;
      subheading: number;
      body: number;
    };
  };
  logos: {
    main: string;
    alternate?: string[];
  };
  style: {
    imageStyle?: string;
    textStyle?: string;
    layoutPreferences?: string[];
  };
  createdAt?: Date;
  updatedAt?: Date;
}