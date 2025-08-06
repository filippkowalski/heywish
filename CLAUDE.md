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
- **Styling**: Tailwind CSS
- **Infrastructure**: Cloudflare Pages for deployment
- **CDN/Storage**: Cloudflare R2
- **Caching**: Redis on Render or Upstash

## Architecture Principles

- **Modular Monolith**: Use Next.js API routes organized by domain (auth, wishlists, wishes, users, social)
- **Authentication Flow**: Firebase handles auth, sync users to PostgreSQL on first login
- **Database**: Single PostgreSQL instance on Render.com
- **No Microservices**: Avoid splitting into separate services for MVP
- **No Complex Price Tracking**: Simple cron jobs, not separate infrastructure
- **No Real-time Features**: Skip WebSocket/real-time for MVP

## Key Documentation Files

Review these files for context:
- `docs/PRODUCT_REQUIREMENTS.md` - User stories, personas, feature requirements
- `docs/TECHNICAL_SPEC.md` - Database schema, architecture patterns
- `docs/API_SPECIFICATION.md` - API endpoints and data structures
- `docs/DESIGN_SYSTEM.md` - UI components and styling guidelines

## Initial Setup Commands (When Implemented)

Since the project hasn't been initialized yet, when starting implementation:

```bash
# For Next.js web app
npx create-next-app@14 . --typescript --tailwind --app --src-dir
npm install firebase firebase-admin pg @types/pg

# For Flutter mobile app (in separate directory)
flutter create mobile --org com.heywish
flutter pub add firebase_core firebase_auth
```

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

Avoid implementing these for MVP:
- Complex price tracking infrastructure
- Real-time WebSocket features
- Analytics dashboards
- Multiple payment providers

## API Structure

Follow the REST API patterns in `docs/API_SPECIFICATION.md`:
- Base path: `/api/v1`
- Authentication: Firebase ID tokens verified on backend
- Standard HTTP methods and status codes
- JSON request/response format
- Key auth endpoints: `/api/auth/sync`, `/api/auth/verify`

## Key Business Metrics

The project targets:
- 25,000 registered users in Year 1
- 10% premium conversion rate
- Revenue from affiliate commissions (80%) and premium subscriptions (20%)
- Focus on retention over acquisition