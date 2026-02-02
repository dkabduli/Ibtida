# Reels seed – sample documents (DEV only)

Reels are **read-only from the client**. To add sample reels:

1. **Firebase Console** → Firestore → `reels` collection → Add document (or use Admin SDK).
2. **Create the composite index** first (see ReelService.swift or Firebase Console prompt).

## Composite index (required for reels query)

- **Collection:** `reels`
- **Fields:** `isActive` (Ascending), `tags` (Array-contains), `sortRank` (Ascending), `createdAt` (Descending)
- **Query scope:** Collection

## Sample document shape (paste and adjust IDs/URLs)

Each document in `reels` should have:

| Field           | Type    | Required | Example                          |
|----------------|---------|----------|----------------------------------|
| title          | string  | yes      | "Surah Al-Fatiha"                |
| videoURL       | string  | yes      | "https://example.com/video.mp4"  |
| isActive       | boolean | yes      | true                             |
| tags           | array   | yes      | ["quran"]                        |
| sortRank       | number  | yes      | 1                                |
| createdAt      | timestamp | yes    | server timestamp                 |
| reciterName    | string  | no       | "Reciter Name"                   |
| surahName      | string  | no       | "Al-Fatiha"                      |
| videoType      | string  | no       | "mp4"                            |
| thumbnailURL   | string  | no       | ""                               |
| durationSeconds| number  | no       | 120                              |

## Example (3 sample reels for Firebase Console)

Create 3 documents in `reels` with auto-generated IDs, or use these as reference:

**Document 1:**
- title: `Surah Al-Fatiha`
- videoURL: `https://example.com/fatiha.mp4`
- isActive: `true`
- tags: `["quran"]`
- sortRank: `1`
- createdAt: (use **current timestamp**)
- reciterName: `Sample Reciter`
- surahName: `Al-Fatiha`
- videoType: `mp4`

**Document 2:** same shape, sortRank: `2`, title e.g. "Surah Al-Ikhlas"  
**Document 3:** same shape, sortRank: `3`, title e.g. "Surah An-Nas"

Replace `https://example.com/...` with real video URLs when you have them.
