// backend/src/services/tmdb.ts
import { getCache, setCache } from '../lib/redis.js';
const TMDB_BASE_URL = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE_URL = 'https://image.tmdb.org/t/p';
const API_KEY = process.env.TMDB_API_KEY;
if (!API_KEY) {
    throw new Error('TMDB_API_KEY environment variable is not set');
}
async function fetchFromTMDB(endpoint) {
    const url = `${TMDB_BASE_URL}${endpoint}${endpoint.includes('?') ? '&' : '?'}api_key=${API_KEY}`;
    const response = await fetch(url, {
        headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
        },
    });
    if (!response.ok) {
        throw new Error(`TMDB API error: ${response.status} ${response.statusText}`);
    }
    return response.json();
}
function getImageUrl(path, size = 'w500') {
    if (!path)
        return null;
    return `${TMDB_IMAGE_BASE_URL}/${size}${path}`;
}
function getAverageRuntime(runtimes) {
    if (!runtimes || runtimes.length === 0)
        return 0;
    return Math.round(runtimes.reduce((a, b) => a + b, 0) / runtimes.length);
}
function isMovie(result) {
    return 'title' in result;
}
function isTV(result) {
    return 'name' in result;
}
export async function searchShows(query) {
    if (!query || query.trim().length < 2) {
        return [];
    }
    const cacheKey = `tmdb:search:${query.toLowerCase()}`;
    const cached = await getCache(cacheKey);
    if (cached) {
        return cached;
    }
    try {
        const [movieResults, tvResults] = await Promise.all([
            fetchFromTMDB(`/search/movie?query=${encodeURIComponent(query)}`),
            fetchFromTMDB(`/search/tv?query=${encodeURIComponent(query)}`),
        ]);
        const results = [];
        for (const result of movieResults.results.slice(0, 5)) {
            if (isMovie(result)) {
                results.push({
                    id: result.id,
                    type: 'movie',
                    title: result.title,
                    overview: result.overview,
                    artworkURL: getImageUrl(result.poster_path),
                    backdropURL: getImageUrl(result.backdrop_path, 'w780'),
                    genres: [],
                    runtime: 0,
                    contentRating: result.adult ? 'R' : null,
                    releaseDate: result.release_date,
                    rating: result.vote_average,
                });
            }
        }
        for (const result of tvResults.results.slice(0, 5)) {
            if (isTV(result)) {
                results.push({
                    id: result.id,
                    type: 'series',
                    title: result.name,
                    overview: result.overview,
                    artworkURL: getImageUrl(result.poster_path),
                    backdropURL: getImageUrl(result.backdrop_path, 'w780'),
                    genres: [],
                    runtime: 0,
                    contentRating: null,
                    releaseDate: result.first_air_date,
                    rating: result.vote_average,
                });
            }
        }
        await setCache(cacheKey, results, 1800); // 30 minutes
        return results;
    }
    catch (error) {
        console.error('TMDB search error:', error);
        throw error;
    }
}
export async function getShowDetails(tmdbId, type) {
    const cacheKey = `tmdb:details:${type}:${tmdbId}`;
    const cached = await getCache(cacheKey);
    if (cached) {
        return cached;
    }
    try {
        const endpoint = type === 'movie' ? `/movie/${tmdbId}` : `/tv/${tmdbId}`;
        const details = type === 'movie'
            ? await fetchFromTMDB(endpoint)
            : await fetchFromTMDB(endpoint);
        const result = {
            id: details.id,
            type,
            title: type === 'movie' ? details.title : details.name,
            overview: details.overview,
            artworkURL: getImageUrl(details.poster_path),
            backdropURL: getImageUrl(details.backdrop_path, 'w780'),
            genres: details.genres.map((g) => g.name),
            runtime: type === 'movie'
                ? details.runtime || 0
                : getAverageRuntime(details.episode_run_time),
            contentRating: null,
            releaseDate: type === 'movie'
                ? details.release_date
                : details.first_air_date,
            rating: details.vote_average,
        };
        await setCache(cacheKey, result, 86400); // 24 hours
        return result;
    }
    catch (error) {
        console.error('TMDB details error:', error);
        return null;
    }
}
export async function getTrendingShows(timeWindow = 'week') {
    const cacheKey = `tmdb:trending:${timeWindow}`;
    const cached = await getCache(cacheKey);
    if (cached) {
        return cached;
    }
    try {
        const [trendingMovies, trendingTV] = await Promise.all([
            fetchFromTMDB(`/trending/movie/${timeWindow}`),
            fetchFromTMDB(`/trending/tv/${timeWindow}`),
        ]);
        const results = [];
        for (const result of trendingMovies.results.slice(0, 5)) {
            if (isMovie(result)) {
                results.push({
                    id: result.id,
                    type: 'movie',
                    title: result.title,
                    overview: result.overview,
                    artworkURL: getImageUrl(result.poster_path),
                    backdropURL: getImageUrl(result.backdrop_path, 'w780'),
                    genres: [],
                    runtime: 0,
                    contentRating: null,
                    releaseDate: result.release_date || '',
                    rating: result.vote_average,
                });
            }
        }
        for (const result of trendingTV.results.slice(0, 5)) {
            if (isTV(result)) {
                results.push({
                    id: result.id,
                    type: 'series',
                    title: result.name,
                    overview: result.overview,
                    artworkURL: getImageUrl(result.poster_path),
                    backdropURL: getImageUrl(result.backdrop_path, 'w780'),
                    genres: [],
                    runtime: 0,
                    contentRating: null,
                    releaseDate: result.first_air_date || '',
                    rating: result.vote_average,
                });
            }
        }
        await setCache(cacheKey, results, 3600); // 1 hour
        return results;
    }
    catch (error) {
        console.error('TMDB trending error:', error);
        return [];
    }
}
