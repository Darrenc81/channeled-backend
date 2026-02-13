import Redis from 'ioredis';
export declare const redis: Redis;
export declare function getCache<T>(key: string): Promise<T | null>;
export declare function setCache(key: string, value: unknown, ttlSeconds?: number): Promise<void>;
export declare function deleteCache(key: string): Promise<void>;
export declare function deleteCachePattern(pattern: string): Promise<void>;
