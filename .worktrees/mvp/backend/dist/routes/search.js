// backend/src/routes/search.ts
import { Router } from 'express';
import { searchShows, getShowDetails, getTrendingShows } from '../services/tmdb.js';
const router = Router();
/**
 * GET /api/search/tmdb
 * Search for movies and TV shows using TMDB
 * Query params:
 * - q: search query
 * - trending: set to 'week' or 'day' to get trending shows instead of search
 */
router.get('/tmdb', async (req, res) => {
    try {
        const { q, trending } = req.query;
        if (trending === 'day' || trending === 'week') {
            const results = await getTrendingShows(trending);
            return res.json({ results });
        }
        if (!q || typeof q !== 'string') {
            return res.status(400).json({ error: 'Query parameter "q" is required' });
        }
        const results = await searchShows(q);
        res.json({ results });
    }
    catch (error) {
        console.error('Search error:', error);
        res.status(500).json({ error: 'Failed to search shows' });
    }
});
/**
 * GET /api/search/tmdb/:id
 * Get details for a specific show from TMDB
 * Query params:
 * - type: 'movie' or 'series'
 */
router.get('/tmdb/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { type } = req.query;
        if (!type || (type !== 'movie' && type !== 'series')) {
            return res.status(400).json({ error: 'Query parameter "type" must be "movie" or "series"' });
        }
        const tmdbId = parseInt(id, 10);
        if (isNaN(tmdbId)) {
            return res.status(400).json({ error: 'Invalid TMDB ID' });
        }
        const result = await getShowDetails(tmdbId, type);
        if (!result) {
            return res.status(404).json({ error: 'Show not found' });
        }
        res.json({ result });
    }
    catch (error) {
        console.error('Show details error:', error);
        res.status(500).json({ error: 'Failed to fetch show details' });
    }
});
export default router;
