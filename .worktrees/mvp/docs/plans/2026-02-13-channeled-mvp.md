# Channeled MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a personalized TV programming app with manual scheduling, household sync, and TMDB integration.

**Architecture:** iOS SwiftUI app with SwiftData for local cache, Railway-hosted Node.js/TypeScript backend, PostgreSQL for persistence, Redis for TMDB caching. Household-based multi-user with Sign in with Apple auth.

**Tech Stack:**
- iOS: SwiftUI, SwiftData, AuthenticationServices, BackgroundTasks
- Backend: Node.js, Express, TypeScript, Prisma ORM
- Infrastructure: Railway, PostgreSQL, Redis
- External: TMDB API, Sign in with Apple

---

## Phase 1: iOS Foundation & Data Models

### Task 1: Core Data Models

**Files:**
- Create: `Channeled/Models/Household.swift`
- Create: `Channeled/Models/User.swift`
- Create: `Channeled/Models/Show.swift`
- Create: `Channeled/Models/ScheduledSlot.swift`
- Create: `Channeled/Models/ViewingWindow.swift`

**Step 1: Add SwiftData models**

```swift
// Channeled/Models/Household.swift
import Foundation
import SwiftData

@Model
final class Household {
    var id: String
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var members: [User]
    @Relationship(deleteRule: .cascade) var scheduledSlots: [ScheduledSlot]

    init(id: String = UUID().uuidString, name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
```

```swift
// Channeled/Models/User.swift
import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var name: String
    var householdId: String
    @Relationship(deleteRule: .nullify) var watchlist: [Show]?
    @Relationship(deleteRule: .cascade) var viewingWindows: [ViewingWindow]?

    init(id: String = UUID().uuidString, name: String, householdId: String) {
        self.id = id
        self.name = name
        self.householdId = householdId
    }
}
```

```swift
// Channeled/Models/Show.swift
import Foundation
import SwiftData

@Model
final class Show {
    var id: String
    var tmdbId: Int
    var type: ShowType
    var title: String
    var overview: String?
    var artworkURL: String?
    var genres: [String]
    var runtime: Int
    var contentRating: String?
    var isBingeable: Bool
    var partnerApproved: Bool
    var moodTags: [String]

    @Relationship(inverse: \Show.watchlist) var user: User?

    init(id: String = UUID().uuidString, tmdbId: Int, type: ShowType, title: String,
         overview: String? = nil, artworkURL: String? = nil, genres: [String] = [],
         runtime: Int = 0, contentRating: String? = nil, isBingeable: Bool = false,
         partnerApproved: Bool = false, moodTags: [String] = []) {
        self.id = id
        self.tmdbId = tmdbId
        self.type = type
        self.title = title
        self.overview = overview
        self.artworkURL = artworkURL
        self.genres = genres
        self.runtime = runtime
        self.contentRating = contentRating
        self.isBingeable = isBingeable
        self.partnerApproved = partnerApproved
        self.moodTags = moodTags
    }
}

enum ShowType: String, Codable {
    case movie, series
}
```

```swift
// Channeled/Models/ScheduledSlot.swift
import Foundation
import SwiftData

@Model
final class ScheduledSlot {
    var id: String
    var householdId: String
    var startTime: Date
    var duration: Int // minutes
    var type: SlotType
    var showId: String?
    var episodeCount: Int
    var familyFriendly: Bool
    var partnerMustLike: Bool

    init(id: String = UUID().uuidString, householdId: String, startTime: Date,
         duration: Int, type: SlotType, showId: String? = nil,
         episodeCount: Int = 1, familyFriendly: Bool = false, partnerMustLike: Bool = false) {
        self.id = id
        self.householdId = householdId
        self.startTime = startTime
        self.duration = duration
        self.type = type
        self.showId = showId
        self.episodeCount = episodeCount
        self.familyFriendly = familyFriendly
        self.partnerMustLike = partnerMustLike
    }
}

enum SlotType: String, Codable {
    case booked, recurring, generated, placeholder
}
```

```swift
// Channeled/Models/ViewingWindow.swift
import Foundation
import SwiftData

@Model
final class ViewingWindow {
    var id: String
    var userId: String
    var dayOfWeek: Int
    var startTime: String // HH:mm format
    var endTime: String
    var type: WindowType
    var label: String

    init(id: String = UUID().uuidString, userId: String, dayOfWeek: Int,
         startTime: String, endTime: String, type: WindowType, label: String) {
        self.id = id
        self.userId = userId
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.label = label
    }
}

enum WindowType: String, Codable {
    case shared, solo
}
```

**Step 2: Update SwiftData schema**

Modify: `Channeled/ChanneledApp.swift`

```swift
import SwiftUI
import SwiftData

@main
struct ChanneledApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Household.self,
            User.self,
            Show.self,
            ScheduledSlot.self,
            ViewingWindow.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Step 3: Build to verify models compile**

Run: `xcodebuild -project Channeled.xcodeproj -scheme Channeled -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Channeled/Models/ Channeled/ChanneledApp.swift
git commit -m "feat: add core SwiftData models"
```

---

### Task 2: App Shell & Tab Navigation

**Files:**
- Modify: `Channeled/ContentView.swift`
- Create: `Channeled/Views/ScheduleView.swift`
- Create: `Channeled/Views/DiscoverView.swift`
- Create: `Channeled/Views/WatchlistView.swift`

**Step 1: Replace ContentView with TabView**

```swift
// Channeled/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
}
```

**Step 2: Create placeholder views**

```swift
// Channeled/Views/ScheduleView.swift
import SwiftUI

struct ScheduleView: View {
    var body: some View {
        NavigationStack {
            Text("Weekly EPG Grid - Coming Soon")
                .navigationTitle("Schedule")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
    }
}

#Preview {
    ScheduleView()
}
```

```swift
// Channeled/Views/DiscoverView.swift
import SwiftUI

struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            Text("TMDB Search - Coming Soon")
                .navigationTitle("Discover")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
    }
}

#Preview {
    DiscoverView()
}
```

```swift
// Channeled/Views/WatchlistView.swift
import SwiftUI

struct WatchlistView: View {
    var body: some View {
        NavigationStack {
            Text("My Watchlist - Coming Soon")
                .navigationTitle("Watchlist")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
    }
}

#Preview {
    WatchlistView()
}
```

**Step 3: Build and run in simulator**

Run: `xcodebuild -project Channeled.xcodeproj -scheme Channeled -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Channeled/Views/ Channeled/ContentView.swift
git commit -m "feat: add tab navigation shell"
```

---

## Phase 2: Backend Foundation

### Task 3: Initialize Railway Backend Project

**Files:**
- Create: `backend/package.json`
- Create: `backend/tsconfig.json`
- Create: `backend/src/index.ts`
- Create: `backend/.env.example`

**Step 1: Create package.json**

```json
{
  "name": "channeled-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "@prisma/client": "^5.8.0",
    "ioredis": "^5.3.2",
    "jsonwebtoken": "^9.0.2",
    "apple-signin-auth": "^2.1.0",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.6",
    "@types/jsonwebtoken": "^9.0.5",
    "tsx": "^4.7.0",
    "typescript": "^5.3.3",
    "vitest": "^1.1.3"
  }
}
```

**Step 2: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

**Step 3: Create basic Express server**

```typescript
// backend/src/index.ts
import express from 'express';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Channeled backend running on port ${PORT}`);
});
```

**Step 4: Create .env.example**

```env
PORT=3000
DATABASE_URL=
REDIS_URL=
JWT_SECRET=
TMDB_API_KEY=
APPLE_SIGN_IN_KEY_ID=
APPLE_SIGN_IN_TEAM_ID=
APPLE_SIGN_IN_CLIENT_ID=
```

**Step 5: Initialize git and commit**

```bash
cd backend
git init
git add .
git commit -m "feat: initialize backend project"
```

---

### Task 4: Database Schema with Prisma

**Files:**
- Create: `backend/prisma/schema.prisma`
- Modify: `backend/package.json` (add prisma scripts)

**Step 1: Install Prisma**

```bash
cd backend
npm install prisma @prisma/client --save-dev
npx prisma init
```

**Step 2: Define Prisma schema**

```prisma
// backend/prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Household {
  id        String   @id @default(cuid())
  name      String
  createdAt DateTime @default(now())
  members   User[]
  slots     ScheduledSlot[]
}

model User {
  id             String         @id @default(cuid())
  name           String
  householdId    String
  household      Household      @relation(fields: [householdId], references: [id])
  appleUserId    String         @unique
  watchlist      Show[]
  viewingWindows ViewingWindow[]
  viewingEvents ViewingEvent[]

  @@index([householdId])
}

model Show {
  id              String   @id @default(cuid())
  tmdbId          Int      @unique
  type            ShowType
  title           String
  overview        String?
  artworkURL      String?
  genres          String[]
  runtime         Int
  contentRating   String?
  isBingeable    Boolean  @default(false)
  partnerApproved  Boolean  @default(false)
  moodTags        String[]

  watchlistUsers User[]
}

model ScheduledSlot {
  id             String      @id @default(cuid())
  householdId     String
  household       Household   @relation(fields: [householdId], references: [id])
  startTime       DateTime
  duration        Int
  type            SlotType
  showId          String?
  episodeCount    Int         @default(1)
  familyFriendly  Boolean     @default(false)
  partnerMustLike Boolean     @default(false)

  @@index([householdId, startTime])
}

model ViewingWindow {
  id        String      @id @default(cuid())
  userId    String
  user      User        @relation(fields: [userId], references: [id])
  dayOfWeek Int
  startTime String
  endTime   String
  type      WindowType
  label     String

  @@index([userId])
}

model ViewingEvent {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id])
  showId    String
  timestamp DateTime @default(now())
  action    Action
  mood      String?
  wasPartnerPresent Boolean?

  @@index([userId, timestamp])
}

enum ShowType {
  MOVIE
  SERIES
}

enum SlotType {
  BOOKED
  RECURRING
  GENERATED
  PLACEHOLDER
}

enum WindowType {
  SHARED
  SOLO
}

enum Action {
  WATCHED
  FINISHED
  VETOED
  FELL_ASLEEP
}
```

**Step 3: Add Prisma scripts to package.json**

Add to scripts section:
```json
"prisma:generate": "prisma generate",
"prisma:push": "prisma db push",
"prisma:studio": "prisma studio"
```

**Step 4: Commit**

```bash
git add backend/prisma/ backend/package.json
git commit -m "feat: add Prisma schema"
```

---

## Phase 3: TMDB Integration

### Task 5: TMDB Service on Backend

**Files:**
- Create: `backend/src/services/tmdb.ts`
- Create: `backend/src/routes/search.ts`

**Step 1: Create TMDB service**

```typescript
// backend/src/services/tmdb.ts
const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p';

export interface TMDBShow {
  id: number;
  title?: string;
  name?: string;
  overview?: string;
  poster_path?: string;
  backdrop_path?: string;
  genre_ids?: number[];
  vote_average?: number;
  first_air_date?: string;
  release_date?: string;
  runtime?: number;
  content_ratings?: { rating: string }[];
}

export interface TMDBSearchResponse {
  page: number;
  results: TMDBShow[];
  total_pages: number;
  total_results: number;
}

export class TMDBService {
  private apiKey: string;
  private redis: any; // Redis client

  constructor(apiKey: string, redisClient: any) {
    this.apiKey = apiKey;
    this.redis = redisClient;
  }

  async search(query: string): Promise<TMDBShow[]> {
    const cacheKey = `tmdb:search:${query}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const response = await fetch(
      `${TMDB_BASE}/search/multi?query=${encodeURIComponent(query)}&api_key=${this.apiKey}`
    );
    const data: TMDBSearchResponse = await response.json();

    await this.redis.setex(cacheKey, 3600, JSON.stringify(data.results));
    return data.results;
  }

  async getDetails(tmdbId: number, type: 'movie' | 'tv'): Promise<TMDBShow> {
    const cacheKey = `tmdb:details:${type}:${tmdbId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const endpoint = type === 'movie' ? 'movie' : 'tv';
    const response = await fetch(
      `${TMDB_BASE}/${endpoint}/${tmdbId}?api_key=${this.apiKey}&append_to_response=credits,similar`
    );
    const data = await response.json();

    await this.redis.setex(cacheKey, 86400, JSON.stringify(data));
    return data;
  }

  getPosterURL(path: string | null, size: string = 'w500'): string | null {
    if (!path) return null;
    return `${TMDB_IMAGE_BASE}/${size}${path}`;
  }

  getBackdropURL(path: string | null, size: string = 'w780'): string | null {
    if (!path) return null;
    return `${TMDB_IMAGE_BASE}/${size}${path}`;
  }
}
```

**Step 2: Create search route**

```typescript
// backend/src/routes/search.ts
import express from 'express';
import { TMDBService } from '../services/tmdb.js';

export function createSearchRoutes(tmdb: TMDBService): express.Router {
  const router = express.Router();

  router.get('/q', async (req, res) => {
    const { q } = req.query;
    if (!q || typeof q !== 'string') {
      return res.status(400).json({ error: 'Query parameter q required' });
    }

    try {
      const results = await tmdb.search(q);
      res.json({ results });
    } catch (error) {
      res.status(500).json({ error: 'Search failed' });
    }
  });

  router.get('/:type/:id', async (req, res) => {
    const { type, id } = req.params;
    if (type !== 'movie' && type !== 'tv') {
      return res.status(400).json({ error: 'Type must be movie or tv' });
    }

    try {
      const details = await tmdb.getDetails(parseInt(id), type);
      res.json(details);
    } catch (error) {
      res.status(500).json({ error: 'Failed to fetch details' });
    }
  });

  return router;
}
```

**Step 3: Update main server**

```typescript
// backend/src/index.ts (updated)
import express from 'express';
import dotenv from 'dotenv';
import { Redis } from 'ioredis';
import { TMDBService } from './services/tmdb.js';
import { createSearchRoutes } from './routes/search.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Initialize services
const redis = new Redis(process.env.REDIS_URL);
const tmdb = new TMDBService(process.env.TMDB_API_KEY!, redis);

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
app.use('/api/search', createSearchRoutes(tmdb));

app.listen(PORT, () => {
  console.log(`Channeled backend running on port ${PORT}`);
});
```

**Step 4: Commit**

```bash
git add backend/src/
git commit -m "feat: add TMDB search service"
```

---

## Phase 4: iOS TMDB Integration

### Task 6: TMDB Service & Models on iOS

**Files:**
- Create: `Channeled/Services/TMDBService.swift`
- Create: `Channeled/Models/TMDBShow.swift`

**Step 1: Create TMDB models**

```swift
// Channeled/Models/TMDBShow.swift
import Foundation

struct TMDBSearchResponse: Codable {
    let page: Int
    let results: [TMDBShow]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBShow: Codable, Identifiable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let genreIds: [Int]?
    let voteAverage: Double?
    let firstAirDate: String?
    let releaseDate: String?
    let runtime: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case voteAverage = "vote_average"
        case firstAirDate = "first_air_date"
        case releaseDate = "release_date"
        case runtime
    }

    var displayTitle: String {
        title ?? name ?? "Untitled"
    }

    var posterURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }

    var mediaType: MediaType {
        title != nil ? .movie : .tv
    }
}

enum MediaType: String {
    case movie, tv
}
```

**Step 2: Create TMDB service**

```swift
// Channeled/Services/TMDBService.swift
import Foundation

final class TMDBService {
    static let shared = TMDBService()
    private let apiKey = ProcessInfo.processInfo.environment["TMDB_API_KEY"] ?? ""
    private let baseURL = "https://api.themoviedb.org/3"
    private let session = URLSession.shared

    private init() {}

    func search(query: String) async throws -> [TMDBShow] {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }

        var components = URLComponents(string: "\(baseURL)/search/multi")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query)
        ]

        guard let url = components?.url else { throw TMDBError.invalidURL }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
        return response.results
    }

    func getDetails(id: Int, type: MediaType) async throws -> TMDBShow {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }

        let endpoint = type == .movie ? "movie" : "tv"
        var components = URLComponents(string: "\(baseURL)/\(endpoint)/\(id)")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "append_to_response", value: "credits,similar")
        ]

        guard let url = components?.url else { throw TMDBError.invalidURL }

        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(TMDBShow.self, from: data)
    }

    enum TMDBError: Error, LocalizedError {
        case missingAPIKey
        case invalidURL
        case networkError(Error)
    }
}
```

**Step 3: Build to verify**

Run: `xcodebuild -project Channeled.xcodeproj -scheme Channeled -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Channeled/Services/ Channeled/Models/TMDBShow.swift
git commit -m "feat: add TMDB service and models"
```

---

### Task 7: Discover UI with Search

**Files:**
- Modify: `Channeled/Views/DiscoverView.swift`
- Create: `Channeled/Views/Components/SearchResultsGrid.swift`
- Create: `Channeled/Views/Components/ShowDetailSheet.swift`

**Step 1: Update DiscoverView with search**

```swift
// Channeled/Views/DiscoverView.swift
import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var searchResults: [TMDBShow] = []
    @State private var isSearching = false
    @State private var selectedShow: TMDBShow?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, isSearching: $isSearching)
                    .padding()

                if isSearching {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if searchResults.isEmpty {
                    ContentUnavailableView("Search for shows and movies",
                                       systemImage: "magnifyingglass")
                } else {
                    SearchResultsGrid(shows: $searchResults, selectedShow: $selectedShow)
                }

                Spacer()
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(item: $selectedShow) { show in
                ShowDetailSheet(show: show)
            }
            .onChange(of: searchText) { _, newValue in
                Task {
                    await performSearch(query: newValue)
                }
            }
        }
    }

    private func performSearch(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            let results = try await TMDBService.shared.search(query: query)
            searchResults = results.filter { $0.mediaType == .tv || $0.mediaType == .movie }
        } catch {
            errorMessage = "Search failed. Please try again."
            searchResults = []
        }

        isSearching = false
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search shows, movies...", text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

#Preview {
    DiscoverView()
}
```

**Step 2: Create results grid**

```swift
// Channeled/Views/Components/SearchResultsGrid.swift
import SwiftUI

struct SearchResultsGrid: View {
    @Binding var shows: [TMDBShow]
    @Binding var selectedShow: TMDBShow?

    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(shows) { show in
                    ShowPoster(show: show)
                        .onTapGesture {
                            selectedShow = show
                        }
                }
            }
            .padding()
        }
    }
}

struct ShowPoster: View {
    let show: TMDBShow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: show.posterURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(width: 120, height: 180)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(width: 120, height: 180)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                        }
                @unknown default:
                    EmptyView()
                }
            }

            Text(show.displayTitle)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 120)
        }
    }
}

#Preview {
    SearchResultsGrid(
        shows: .constant([
            TMDBShow(id: 1, title: "Example Show", overview: "Test", posterPath: "/test.jpg", genreIds: nil),
            TMDBShow(id: 2, name: "Another Show", overview: "Test", posterPath: "/test2.jpg", genreIds: nil)
        ]),
        selectedShow: .constant(nil)
    )
}
```

**Step 3: Create detail sheet**

```swift
// Channeled/Views/Components/ShowDetailSheet.swift
import SwiftUI

struct ShowDetailSheet: View {
    let show: TMDBShow
    @Environment(\.dismiss) private var dismiss
    @State private var isInWatchlist = false
    @State private var isInMaybePool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Backdrop
                    backdropHeader

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(show.displayTitle)
                            .font(.title)

                        if let overview = show.overview {
                            Text(overview)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        if let rating = show.voteAverage {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)

                    // Actions
                    actionsView
                        .padding()

                    Spacer()
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var backdropHeader: some View {
        GeometryReader { geometry in
            AsyncImage(url: show.backdropURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                default:
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 200)
                }
            }
        }
        .frame(height: 200)
    }

    private var actionsView: some View {
        VStack(spacing: 12) {
            Button(action: { isInWatchlist.toggle() }) {
                Label(isInWatchlist ? "In Watchlist" : "Add to Watchlist",
                       systemImage: isInWatchlist ? "checkmark" : "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: { isInMaybePool.toggle() }) {
                Label(isInMaybePool ? "In Maybe Pool" : "Add to Maybe Pool",
                       systemImage: isInMaybePool ? "checkmark" : "calendar.badge.plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
}

extension TMDBShow {
    var backdropURL: URL? {
        guard let backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(backdropPath)")
    }
}

#Preview {
    ShowDetailSheet(show: TMDBShow(
        id: 1,
        title: "Example Movie",
        overview: "An exciting movie about things.",
        posterPath: "/test.jpg",
        backdropPath: "/backdrop.jpg",
        voteAverage: 7.5
    ))
}
```

**Step 4: Build and test**

Run: `xcodebuild -project Channeled.xcodeproj -scheme Channeled -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Channeled/Views/
git commit -m "feat: add discover UI with search"
```

---

## Phase 5: Watchlist Management

### Task 8: Watchlist View with Local Storage

**Files:**
- Modify: `Channeled/Views/WatchlistView.swift`
- Create: `Channeled/ViewModels/WatchlistViewModel.swift`

**Step 1: Create view model**

```swift
// Channeled/ViewModels/WatchlistViewModel.swift
import SwiftUI
import SwiftData

@Observable
final class WatchlistViewModel {
    var watching: [Show] = []
    var upNext: [Show] = []
    var wantToWatch: [Show] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadWatchlist()
    }

    private func loadWatchlist() {
        // For MVP, we'll use simple in-memory
        // Will implement actual SwiftData queries in next task
    }

    func addToWatchlist(_ show: TMDBShow) {
        let newShow = Show(
            tmdbId: show.id,
            type: show.mediaType == .movie ? .movie : .series,
            title: show.displayTitle,
            overview: show.overview,
            artworkURL: show.posterPath,
            genres: [], // Will fetch from TMDB details
            runtime: show.runtime ?? 0
        )
        modelContext.insert(newShow)
        try? modelContext.save()
        loadWatchlist()
    }
}
```

**Step 2: Update WatchlistView**

```swift
// Channeled/Views/WatchlistView.swift
import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WatchlistViewModel?
    @State private var selectedShow: Show?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    List {
                        Section("Watching") {
                            ForEach(viewModel.watching) { show in
                                ShowRow(show: show)
                            }
                        }

                        Section("Up Next") {
                            ForEach(viewModel.upNext) { show in
                                ShowRow(show: show)
                            }
                        }

                        Section("Want to Watch") {
                            ForEach(viewModel.wantToWatch) { show in
                                ShowRow(show: show)
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WatchlistViewModel(modelContext: modelContext)
            }
        }
        .sheet(item: $selectedShow) { show in
            Text("Show detail: \(show.title)")
                .presentationDetents([.medium])
        }
    }
}

struct ShowRow: View {
    let show: Show

    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            AsyncImage(url: show.artworkURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                        .frame(width: 60, height: 90)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.headline)

                Text("\(show.runtime) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if show.isBingeable {
                    Label("Bingeable", systemImage: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchlistView()
        .modelContainer(for: Show.self, inMemory: true)
}
```

**Step 3: Build**

Run: `xcodebuild -project Channeled.xcodeproj -scheme Channeled -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Channeled/Views/WatchlistView.swift Channeled/ViewModels/
git commit -m "feat: add watchlist view"
```

---

## Phase 6: Manual Scheduling

### Task 9: Basic EPG Grid

**Files:**
- Modify: `Channeled/Views/ScheduleView.swift`
- Create: `Channeled/Views/Components/EPGGrid.swift`
- Create: `Channeled/Views/Components/EPGSlot.swift`

**Step 1: Create EPG slot component**

```swift
// Channeled/Views/Components/EPGSlot.swift
import SwiftUI

struct EPGSlot: View {
    let slot: ScheduledSlot
    let show: Show?
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let show = show {
                Text(show.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if slot.episodeCount > 1 {
                    Text("\(slot.episodeCount) eps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(slot.type == .placeholder ? "TV" : "Free")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(backgroundForType)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture(perform: onTap)
    }

    private var backgroundForType: some View {
        Group {
            if slot.type == .placeholder {
                Color.gray.opacity(0.3)
            } else if slot.familyFriendly {
                Color.green.opacity(0.3)
            } else {
                Color.blue.opacity(0.3)
            }
        }
    }
}

#Preview {
    EPGSlot(slot: ScheduledSlot(
        householdId: "test",
        startTime: Date(),
        duration: 120,
        type: .booked,
        showId: "show1",
        familyFriendly: true
    ), show: nil) {})
}
```

**Step 2: Create EPG grid**

```swift
// Channeled/Views/Components/EPGGrid.swift
import SwiftUI

struct EPGGrid: View {
    @State private var selectedDate = Date()
    @State private var slots: [ScheduledSlot] = []

    private let timeSlots = [
        "18:00", "18:30", "19:00", "19:30", "20:00",
        "20:30", "21:00", "21:30", "22:00", "22:30"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Day selector
                daySelector

                Divider()

                // Timeline
                timelineGrid
            }
        }
    }

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<7) { offset in
                    if let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) {
                        DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                selectedDate = date
                            }
                    }
                }
            }
            .padding()
        }
    }

    private var timelineGrid: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Time")
                    .frame(width: 60)
                ForEach(timeSlots, id: \.self) { time in
                    Text(time)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            Divider()

            // Show rows (for demo, just one day)
            VStack(spacing: 8) {
                ForEach(0..<3) { _ in
                    timeRow
                }
            }
            .padding()
        }
    }

    private var timeRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "tv")
                .frame(width: 60)

            ForEach(timeSlots, id: \.self) { _ in
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 50)
                    .overlay {
                        Text("Free")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(date, format: .dateTime.weekday(.wide))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(date, format: .dateTime.day())
                .font(.title3)
                .fontWeight(isSelected ? .bold : .regular)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    EPGGrid()
}
```

**Step 3: Update ScheduleView**

```swift
// Channeled/Views/ScheduleView.swift
import SwiftUI

struct ScheduleView: View {
    var body: some View {
        NavigationStack {
            EPGGrid()
                .navigationTitle("Schedule")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("This Week") {}
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {}) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
    }
}

#Preview {
    ScheduleView()
}
```

**Step 4: Build**

Run: `xcodebuild -project Channeled.xcodeproj -scheme Channeled -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Channeled/Views/Components/
git commit -m "feat: add EPG grid layout"
```

---

## Phase 7: Sign in with Apple

### Task 10: Sign in with Apple Integration

**Files:**
- Create: `Channeled/Services/AuthService.swift`
- Create: `Channeled/Views/SignInView.swift`
- Create: `backend/src/routes/auth.ts`

**Step 1: Create iOS auth service**

```swift
// Channeled/Services/AuthService.swift
import Foundation
import AuthenticationServices
import CryptoKit

final class AuthService: NSObject {
    static let shared = AuthService()

    private var currentNonce: String?

    private override init() {}

    func signInWithApple() async throws -> AppleCredential {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let result = try await performAuthorization(request)

        return AppleCredential(
            userID: result.credential.user,
            email: result.credential.email,
            fullName: result.credential.fullName,
            identityToken: result.credential.identityToken,
            authorizationCode: result.credential.authorizationCode
        )
    }

    private func performAuthorization(_ request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests { result in
                switch result {
                case .success(let authorization):
                    continuation.resume(returning: authorization)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Handled in performAuthorization
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error
    }
}

struct AppleCredential {
    let userID: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: Data?
    let authorizationCode: Data?
}

// MARK: - Nonce helpers
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0..<16).map { _ in
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            return random
        }

        for random in randoms {
            if random < UInt8(charset.count) {
                result.append(charset[Int(random)])
                remainingLength -= 1
                if remainingLength == 0 {
                    break
                }
            }
        }
    }

    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
}
```

**Step 2: Create backend auth routes**

```typescript
// backend/src/routes/auth.ts
import express from 'express';
import { verifyIdToken } from 'apple-signin-auth';

export function createAuthRoutes() {
  const router = express.Router();

  router.post('/apple', async (req, res) => {
    try {
      const { id_token } = req.body;

      if (!id_token) {
        return res.status(400).json({ error: 'id_token required' });
      }

      const appleUser = await verifyIdToken(id_token);

      // Find or create user
      const user = await findOrCreateUser(appleUser.sub);

      // Generate JWT
      const token = generateJWT(user);

      res.json({
        user: { id: user.id, name: user.name },
        token
      });
    } catch (error) {
      console.error('Auth error:', error);
      res.status(401).json({ error: 'Authentication failed' });
    }
  });

  return router;
}

async function findOrCreateUser(appleUserId: string) {
  // Implementation with Prisma
  return { id: 'user-id', name: 'User Name' };
}

function generateJWT(user: any): string {
  // Implementation with jsonwebtoken
  return 'jwt-token';
}
```

**Step 3: Create sign in view**

```swift
// Channeled/Views/SignInView.swift
import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "tv")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Channeled")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your personal TV guide")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Signing in...")
                } else {
                    Button(action: signIn) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Continue with Apple")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let credential = try await AuthService.shared.signInWithApple()
                // Send to backend and store token
                dismiss()
            } catch {
                errorMessage = "Sign in failed. Please try again."
                isLoading = false
            }
        }
    }
}

#Preview {
    SignInView()
}
```

**Step 4: Build**

Run: `xcodebuild -project Channeled.xcodeproj -scheme Channeled -destination 'platform=iOS Simulator,name=iPhone 17' build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add Channeled/Services/AuthService.swift Channeled/Views/SignInView.swift
git commit -m "feat: add Sign in with Apple"
```

---

## Summary

This MVP plan covers:
1. Core data models (SwiftData + Prisma)
2. App navigation shell with 3 tabs
3. Backend foundation with Express + PostgreSQL
4. TMDB search integration (iOS + backend)
5. Discover UI with search and show details
6. Watchlist management with local storage
7. Basic EPG grid for schedule view
8. Sign in with Apple authentication

**Not in MVP** (for Phase 2):
- Automatic scheduling algorithm
- Backend sync
- Household joining with QR codes
- Veto flow with alternatives
- Binge mode suggestions
- Maybe pool

**Next Steps:**
1. Run tests as you implement
2. Commit frequently
3. Test on device for Sign in with Apple
4. Deploy backend to Railway
5. Update CLAUDE.md with API endpoints
