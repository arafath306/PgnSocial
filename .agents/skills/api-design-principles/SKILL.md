---
name: api-design-principles
description: Expert guidance for designing APIs, Supabase Edge Functions, and backend contracts in Pigeon Social. Use when creating new endpoints, Edge Functions, HTTP interfaces, or defining data contracts between Flutter and Supabase.
---

# API Design Principles — Pigeon Social

## Use this skill when

- creating a new Supabase Edge Function
- designing a new database RPC function
- defining request/response data contracts
- designing pagination interfaces
- designing error response formats
- reviewing API consistency
- adding a new backend feature that Flutter calls

## Do not use this skill when

- making purely UI changes in Flutter
- working on local state management only
- changing database schema without any HTTP interface

## Pigeon Backend Stack

- Supabase PostgreSQL (primary data store)
- Supabase Edge Functions (Deno / TypeScript)
- Supabase RPC (PostgreSQL functions called via PostgREST)
- Supabase Realtime (subscriptions)
- Supabase Storage (media files)
- Flutter Dart client (consumer)

---

## Response Format

All Edge Functions and RPCs must return consistent JSON:

**Success:**
```json
{
  "data": { ... },
  "error": null
}
```

**Error:**
```json
{
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message"
  }
}
```

Never return raw unstructured error strings to the Flutter client.

---

## HTTP Status Codes

Use appropriate HTTP status codes:

| Code | When to use |
|------|-------------|
| 200  | Successful GET, UPDATE |
| 201  | Successful CREATE |
| 400  | Bad request / invalid input |
| 401  | Not authenticated |
| 403  | Authenticated but not authorized |
| 404  | Resource not found |
| 409  | Conflict (e.g. duplicate) |
| 422  | Validation error |
| 429  | Rate limited |
| 500  | Unexpected server error |

---

## Input Validation

Always validate inputs at the Edge Function / RPC level.

Never trust client-supplied data without server-side validation.

Validate:
- required fields are present
- string lengths are within bounds
- enum values are valid
- user IDs match the authenticated user
- timestamps are within reasonable ranges

---

## Authentication

Every protected Edge Function must verify the JWT token from Supabase Auth.

```typescript
const { data: { user }, error } = await supabase.auth.getUser(token)
if (!user) return errorResponse(401, 'UNAUTHORIZED')
```

Never allow unauthenticated access to user data.

---

## Pagination

All list endpoints must be paginated.

Prefer cursor-based pagination for feeds, comments, notifications, messages.

Example cursor pagination contract:
```json
{
  "data": {
    "items": [...],
    "next_cursor": "2024-01-15T10:30:00Z",
    "has_more": true
  },
  "error": null
}
```

Never return unlimited lists.

Default page size: 20 items.
Maximum page size: 50 items.

---

## Naming Conventions

### Edge Functions
- Use kebab-case: `get-feed`, `send-message`, `follow-user`
- Use verb-noun pattern for actions

### RPC Functions (PostgreSQL)
- Use snake_case: `get_user_feed`, `mark_messages_read`
- Prefix with action: `get_`, `create_`, `update_`, `delete_`, `check_`

### Response Fields
- Use snake_case for all JSON fields
- Use ISO 8601 for all timestamps
- Use UUIDs for all IDs

---

## Idempotency

Write operations that could be retried must be safe to call multiple times.

Examples:
- Following a user twice should not create duplicate follow records
- Liking a post twice should not create duplicate likes
- Sending the same message twice should be detected and deduplicated

---

## Rate Limiting

Sensitive endpoints must have rate limiting:
- Authentication attempts
- Message sending
- Post creation
- Follow/unfollow actions
- Search queries

Implement rate limiting at the Edge Function level or via Supabase policies.

---

## Security Rules

Never expose:
- Internal database IDs that could be enumerated
- Other users' private data
- System configuration
- Stack traces in production error responses

Never allow:
- Horizontal privilege escalation (accessing another user's data)
- Mass assignment of protected fields
- Bypassing RLS through Edge Functions

---

## Versioning

If breaking changes are needed, version the Edge Function:
- `v1/get-feed`
- `v2/get-feed`

Maintain backward compatibility for at least one version cycle.

---

## Flutter Client Contract

The Flutter client must:
- Always handle both `data` and `error` fields
- Never assume a successful HTTP status means valid data
- Implement retry logic for transient network failures
- Never expose raw API error messages directly to users
- Map API error codes to user-friendly messages in the UI layer
