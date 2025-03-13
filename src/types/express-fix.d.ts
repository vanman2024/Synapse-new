/**
 * This file provides type fixes for express-serve-static-core
 * It addresses the type error in that package's type definitions
 */

// Declare that we're augmenting the @types/express-serve-static-core package
declare module 'express-serve-static-core' {
  // Dummy interface that prevents errors in the original types
  interface IRouter {
    // Empty interface to resolve type issues
  }
}