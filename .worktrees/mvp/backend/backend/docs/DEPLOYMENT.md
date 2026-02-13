# Railway Deployment Guide

## Quick Start

1. Go to railway.app
2. Click "New Project"
3. Select "Deploy from GitHub"
4. Search for "channeled-backend" (or your username/channeled-backend)
5. Click "Deploy"

## Environment Variables

After deployment, set these in Railway:
- DATABASE_URL (PostgreSQL connection string)
- REDIS_URL (Redis connection string)
- JWT_SECRET (generate a secure random string)
- TMDB_API_KEY (get from themoviedb.org)
- NODE_ENV=production

## Build Command
Railway runs: npm run build

## Start Command
Railway runs: npm start
