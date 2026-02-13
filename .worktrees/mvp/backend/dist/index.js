// backend/src/index.ts
import express from 'express';
import dotenv from 'dotenv';
import searchRoutes from './routes/search.js';
dotenv.config();
const app = express();
const PORT = process.env.PORT || 3000;
app.use(express.json());
// Health check
app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
// API routes
app.use('/api/search', searchRoutes);
// 404 handler
app.use((_req, res) => {
    res.status(404).json({ error: 'Not found' });
});
// Error handler
app.use((err, _req, res, _next) => {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
});
app.listen(PORT, () => {
    console.log(`Channeled backend running on port ${PORT}`);
});
