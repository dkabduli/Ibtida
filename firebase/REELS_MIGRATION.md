# Reels: How to Add Reels in Firestore

The Reels tab shows Quran recitation short videos. The feed is **data-driven via Firestore** so you can add or update reels without an app release.

## Firestore structure

### Collection: `reels`

Each document is one reel. Document ID can be any unique string (e.g. auto-generated or slug).

| Field            | Type     | Required | Description |
|-----------------|----------|----------|-------------|
| `title`         | string   | Yes      | e.g. "Surah Al-Mulk (Beautiful Recitation)" |
| `videoURL`      | string   | Yes      | HTTPS URL (Firebase Storage CDN or your CDN) |
| `isActive`      | boolean  | Yes      | Only reels with `isActive == true` are shown |
| `tags`          | array    | Yes      | Must include `"quran"` for Quran recitation (app filters on this) |
| `videoType`     | string   | No       | `"mp4"` (default) or `"hls"` for future HLS |
| `reciterName`   | string   | No       | Reciter name |
| `surahName`     | string   | No       | Surah name |
| `thumbnailURL`   | string   | No       | HTTPS image URL for thumbnail |
| `durationSeconds` | number | No       | Duration in seconds |
| `createdAt`     | timestamp| No       | Creation time |
| `sortRank`      | number   | No       | Lower = earlier in feed (default 0). Order: sortRank asc, createdAt desc |

### User interactions (private): `users/{uid}/reelInteractions/{reelId}`

Stored per user; only that user can read/write.

| Field                | Type     | Description |
|----------------------|----------|-------------|
| `liked`              | boolean  | User liked the reel |
| `saved`              | boolean  | User saved/bookmarked |
| `lastWatchedSeconds` | number   | Optional; last watched position |
| `updatedAt`          | timestamp| Last update |

## Example reel document

```json
{
  "title": "Surah Al-Mulk (Beautiful Recitation)",
  "reciterName": "Mishary Rashid",
  "surahName": "Al-Mulk",
  "tags": ["quran", "recitation"],
  "videoType": "mp4",
  "videoURL": "https://your-cdn.or.firebasestorage.app/reels/almulk.mp4",
  "thumbnailURL": "https://your-cdn.or.firebasestorage.app/reels/almulk.jpg",
  "durationSeconds": 180,
  "isActive": true,
  "createdAt": "2025-01-15T12:00:00Z",
  "sortRank": 0
}
```

## Rules summary

- **Reels**: Anyone can read documents where `isActive == true`. No client write (admin/server only to add reels).
- **Reel interactions**: Users can read and write only their own `users/{uid}/reelInteractions/{reelId}`.

## Composite index (Firestore)

The app queries:

- `reels` where `isActive == true` and `tags` array-contains `"quran"`
- Order by `sortRank` ascending, then `createdAt` descending

Create a composite index in Firestore Console:

- Collection: `reels`
- Fields: `isActive` (Ascending), `tags` (Array-contains), `sortRank` (Ascending), `createdAt` (Descending)

Or deploy and use the index link from the first query error in the console.

## Extending beyond Quran

The app currently filters to `tags` containing `"quran"`. To add Islamic advice or other categories later:

1. Add new tags (e.g. `"advice"`, `"sunnah"`) and documents with those tags.
2. In the app, extend the feed query or add a category filter (e.g. segment control) and query by the chosen tag.

No change to the document shape is required; only query/filter logic in the client (and optionally a category field if you prefer).
