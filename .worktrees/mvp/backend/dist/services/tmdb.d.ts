export interface TMDBShow {
    id: number;
    type: 'movie' | 'series';
    title: string;
    overview: string;
    artworkURL: string | null;
    backdropURL: string | null;
    genres: string[];
    runtime: number;
    contentRating: string | null;
    releaseDate: string;
    rating: number;
}
export declare function searchShows(query: string): Promise<TMDBShow[]>;
export declare function getShowDetails(tmdbId: number, type: 'movie' | 'series'): Promise<TMDBShow | null>;
export declare function getTrendingShows(timeWindow?: 'day' | 'week'): Promise<TMDBShow[]>;
