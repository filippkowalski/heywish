# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HeyWish is a next-generation wishlist platform currently in the documentation/planning phase. The project aims to compete with GoWish by offering a modern, fast, and social-first experience targeting younger demographics.

## Current Project State

**IMPORTANT**: This project is in the planning phase with comprehensive documentation but no implementation yet. When asked to work on features, you'll need to create the initial project structure and implementation from scratch.

## Technology Stack

When implementing features, use these technologies:
- **Backend/Web**: Next.js 14 with App Router (modular monolith approach)
- **Authentication**: Firebase Auth (free tier, no Identity Platform)
- **Database**: PostgreSQL hosted on Render.com
- **Mobile**: Flutter
- **Styling**: Tailwind CSS (for web)
- **Infrastructure**: Cloudflare Pages for deployment
- **CDN/Storage**: Cloudflare R2 (images storage)

## Architecture Principles

- **Modular Monolith**: Use Next.js API routes organized by domain (auth, wishlists, wishes, users, social)
- **Authentication Flow**: Firebase handles auth, sync users to PostgreSQL on first login
- **Database**: Single PostgreSQL instance on Render.com

## Key Documentation Files

Review these files for context:
- `docs/DESIGN_SYSTEM.md` - UI components and styling guidelines

## Database Schema

Use the PostgreSQL schema defined in `docs/TECHNICAL_SPEC.md`:
- `users` - User accounts synced from Firebase (includes firebase_uid)
- `wishlists` - User wishlists with visibility settings
- `wishes` - Individual wish items with reservation status
- Social features tables (friends, activity feed)

## Authentication Integration

1. Create anonymous Firebase user on first visit (no signup required)
2. Anonymous users can create wishlists and use all features
3. Firebase handles authentication (anonymous, email/password, Google, Apple)
4. When anonymous user signs up, link their account to preserve data
5. On any Firebase auth, call `/api/auth/sync` to create/update user in PostgreSQL
6. All API calls require valid Firebase ID token in Authorization header
7. Backend verifies token with Firebase Admin SDK before processing requests

## MVP Focus Areas

1. Core wishlist CRUD operations
2. Basic user authentication (Firebase Auth)
3. Simple sharing via links
4. Item reservation system
5. Manual product entry and URL scraping


## API Structure

Follow the REST API patterns in `docs/API_SPECIFICATION.md`:
- Base path: `/api/v1`
- Authentication: Firebase ID tokens verified on backend
- Standard HTTP methods and status codes
- JSON request/response format
- Key auth endpoints: `/api/auth/sync`, `/api/auth/verify`

## WEB Guideliness
- Shadcn design, black and white, elegant, sleek
- Tailwind.css, React
- Please use the playwright MCP server when making visual changes to the front-end website to check your work

## Backend API

The HeyWish API is implemented as a separate Express.js service with the following features:

### API Structure
- **Base URL**: `http://localhost:8080/v1` (development)
- **Authentication**: Firebase ID token verification
- **Database**: PostgreSQL with Row Level Security (RLS)
- **File Storage**: Cloudflare R2 for images

### Key Endpoints
- `POST /auth/sync` - Sync Firebase user with PostgreSQL
- `GET /wishlists` - Get user's wishlists
- `POST /wishlists` - Create new wishlist
- `POST /wishes` - Add item to wishlist
- `GET /public/wishlists/:token` - Public wishlist sharing

### Database Schema
- `users` - User accounts synced from Firebase
- `wishlists` - User wishlists with visibility settings
- `wishes` - Individual wish items with reservation system
- `friendships` - Social connections
- `activities` - Activity feed

### Services
- `HeyWishAPIService` - Main API logic and database operations
- `CloudflareR2Service` - Image upload and storage management

### Security
- Firebase Admin SDK for token verification
- Row Level Security policies for data isolation
- Rate limiting and CORS protection
- Secure image upload with validation

## TODO Before Release

### Backend Setup
- **Database Migration**: Run initial schema migration on production database
- **Environment Variables**: Configure all production environment variables
- **Firebase Service Account**: Set up production Firebase service account key
- **Cloudflare R2**: Configure production R2 bucket and access keys
- **SSL/HTTPS**: Ensure all API connections use HTTPS in production

### Firebase Configuration for Production
- **Android Google Sign-in**: Generate SHA-1 fingerprint for production release key and update Firebase configuration
  - Generate release keystore: `keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000`
  - Get SHA-1 fingerprint: `keytool -list -v -keystore release-key.keystore -alias release`
  - Add SHA-1 to Firebase Project Settings > Your apps > Android app
  - Download and replace `google-services.json` file
  - Required for Google Sign-in to work in production builds