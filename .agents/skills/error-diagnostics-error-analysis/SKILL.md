---
name: error-diagnostics-error-analysis
description: Systematic error diagnosis and root cause analysis for Pigeon Social. Use when debugging Flutter exceptions, Supabase errors, E2EE failures, realtime subscription issues, auth problems, or any unexpected behavior in the app.
---

# Error Diagnostics & Analysis — Pigeon Social

## Use this skill when

- debugging a Flutter crash or exception
- diagnosing a Supabase query failure
- investigating an authentication error
- debugging E2EE encryption/decryption failures
- investigating realtime subscription issues
- diagnosing feed or post loading failures
- investigating storage upload/download errors
- analyzing unexpected UI behavior
- tracing a bug reported by a user

## Do not use this skill when

- adding a new feature from scratch
- making purely visual UI changes
- writing new tests without a specific bug to trace

---

## Diagnostic Workflow

Before touching any code, follow this order:

1. **Reproduce** — Can you reliably reproduce the issue?
2. **Isolate** — Which layer is failing? (UI / State / Repository / Supabase / Network)
3. **Collect evidence** — Gather error messages, stack traces, logs
4. **Form hypothesis** — What is the most likely root cause?
5. **Verify hypothesis** — Confirm before fixing
6. **Fix minimally** — Make the smallest correct change
7. **Verify fix** — Confirm the fix resolves the issue without regressions

Never jump to fixing without completing steps 1-4.

---

## Layer-by-Layer Diagnosis

### Flutter UI Layer
Check:
- Widget lifecycle (initState, dispose called correctly?)
- setState called after dispose?
- BuildContext used after widget unmounted?
- Null safety violations?
- Type cast failures?

### State Management Layer
Check:
- Provider/Riverpod/BLoC state updated correctly?
- Listener disposed properly?
- Race condition between async operations?
- Stale state from previous session?

### Repository/Service Layer
Check:
- Correct method called?
- Parameters passed correctly?
- Error propagated or silently swallowed?
- Correct model mapping from JSON?

### Supabase Layer
Check:
- RLS policy blocking the query?
- Query targeting wrong table or column?
- Missing index causing timeout?
- Auth token expired?
- Insufficient permissions?

### Network Layer
Check:
- Device offline?
- Request timing out?
- Supabase service issue?
- SSL/certificate error?

---

## Common Pigeon Error Patterns

### Authentication Errors

**Symptom:** User suddenly logged out or can't access data  
**Check:**
- Supabase session expired?
- Token refresh failing?
- Auth state listener disposed?
- RLS requires auth but user is null?

**Resolution approach:**
1. Check `supabase.auth.currentSession`
2. Verify token refresh is configured
3. Verify RLS policies allow the operation for authenticated users

---

### E2EE Errors

**Symptom:** Messages not decrypting, showing garbled text, or crashing

**CRITICAL:** Never log decrypted content, keys, or nonces during diagnosis.

**Check:**
- Key exchange completed before sending message?
- Nonce reused? (must be unique per message)
- AES-GCM authentication tag failing? (message tampered or wrong key)
- Private key missing from secure storage?
- Key mismatch between sender and recipient?

**Resolution approach:**
1. Verify key exchange handshake completed for that conversation
2. Verify nonce generation is using secure random
3. Check if keys were cleared (logout, reinstall)
4. Never attempt to "fix" crypto failures by disabling authentication

---

### Feed/Realtime Errors

**Symptom:** Feed not loading, not updating, or duplicating posts

**Check:**
- Supabase realtime subscription created multiple times?
- Subscription not disposed on widget unmount?
- Duplicate event handling?
- Pagination cursor incorrect?
- Query missing indexes causing timeout?

**Resolution approach:**
1. Verify subscription is created once and disposed on unmount
2. Check for duplicate subscription creation in widget rebuild
3. Verify cursor pagination logic is correct

---

### Supabase Query Errors

**Symptom:** Data not loading, empty results, or RLS errors

**Check:**
```sql
-- Check if RLS is blocking
SELECT * FROM table_name WHERE id = 'uuid'; -- run as service role to compare
```

Common RLS issues:
- Policy references `auth.uid()` but user is not authenticated
- Policy missing for INSERT/UPDATE/DELETE
- Policy too restrictive (blocking legitimate access)
- Policy too permissive (security risk)

**Resolution approach:**
1. Test query with service role key in Supabase dashboard
2. Compare results — if service role works but user doesn't, it's RLS
3. Check the specific policy blocking the operation
4. Fix the policy, not the RLS enforcement

---

### Storage Errors

**Symptom:** Images not uploading, not loading, or access denied

**Check:**
- Storage bucket policy configured?
- File size within limits?
- File type allowed?
- Correct bucket name used?
- Auth token attached to request?
- Signed URL expired?

---

### Flutter Rendering Errors

**Symptom:** UI crash, black screen, or overflow

**Check:**
- `setState()` called after `dispose()`?
- Async gap with unmounted context?
- Missing null check on nullable data?
- Widget tree receiving unexpected null?

**Safe async pattern:**
```dart
if (!mounted) return;
setState(() { ... });
```

---

## Error Logging Rules

### Always log:
- Error type and message
- Stack trace
- Context (which screen, which action)
- Timestamp

### Never log:
- Plaintext message content
- Encryption keys or nonces
- Private keys
- User passwords
- Auth tokens
- Personally identifiable information (beyond user ID)

---

## Identifying Silent Failures

Silent failures are the most dangerous. Look for:
- Empty catch blocks: `catch (e) {}`
- Swallowed futures: calling async without await
- Missing error states in UI
- Returning empty list instead of propagating error

When finding a silent failure, propagate the error properly rather than hiding it.

---

## Reporting a Bug

When a bug is confirmed, document:

1. **What happened** — exact symptoms
2. **Steps to reproduce** — reliable reproduction steps
3. **Root cause** — identified cause
4. **Layer affected** — UI / State / Repository / Supabase / Network
5. **Fix applied** — what was changed
6. **Verification** — how the fix was confirmed
