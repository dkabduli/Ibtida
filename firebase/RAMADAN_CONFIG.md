# Ramadan Tab – Server-Driven Config

The Ramadan tab appears **only when** the server enables it. No app update is required.

## Firestore document

- **Collection:** `app_config`
- **Document ID:** `calendar_flags`

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `ramadan_enabled` | boolean | When `true`, the Ramadan tab can show (if dates are set or TBD). |
| `ramadan_start_gregorian` | string | Start date in user-local terms: `"YYYY-MM-DD"` (e.g. `"2027-02-18"`). |
| `ramadan_end_gregorian` | string | End date: `"YYYY-MM-DD"` (e.g. `"2027-03-19"`). |
| `ramadan_source_note` | string (optional) | Debug note (e.g. `"Saudi announcement"`). |

## When to update

1. **Before Ramadan (TBD):**  
   Set `ramadan_enabled: true`, leave `ramadan_start_gregorian` and `ramadan_end_gregorian` unset or null.  
   The app shows the Ramadan tab with a “TBD” / “Ramadan dates not confirmed yet” message and does **not** allow logging.

2. **After announcement (e.g. Saudi):**  
   Set `ramadan_start_gregorian` to the first day of Ramadan (e.g. tomorrow’s date) and `ramadan_end_gregorian` to the last day (29 or 30 days later).  
   The app will show the Ramadan tab and the fasting calendar/list; users can log from the start date.

## Who can write

- **Read:** any authenticated user (needed for tab visibility and dates).
- **Write:** only users with the **admin** custom claim (set in Firebase Auth).

## Example (Firebase Console or Admin SDK)

```json
{
  "ramadan_enabled": true,
  "ramadan_start_gregorian": "2027-02-18",
  "ramadan_end_gregorian": "2027-03-19",
  "ramadan_source_note": "Saudi announcement"
}
```

## Fasting logs

- Stored at: `users/{uid}/ramadanLogs/{YYYY-MM-DD}`.
- Each user can read and write only their own documents (enforced by Firestore rules).
