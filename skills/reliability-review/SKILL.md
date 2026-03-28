---
name: reliability-review
description: Checklist for reviewing code reliability, performance, and security — use during code review or before merge
---

# Reliability & Performance Review

## When to Use

- During code review (Reviewer agent Phase B)
- Before merging any feature that touches: APIs, databases, external services, auth, user input
- When reviewing performance-sensitive code paths

## Checklist

For each area, flag issues using severity from `rules/severity-discipline.md`:
- **P0:** Confirmed exploitable issue, data loss, crash
- **P1:** Likely issue with clear evidence
- **P2:** Potential issue, needs investigation

---

### Error Handling

- [ ] Errors caught and handled at system boundaries (API handlers, message consumers, CLI entry points)
- [ ] No swallowed exceptions (`catch {}` with no logging or re-throw)
- [ ] Fail-fast on invalid state — don't propagate bad data silently
- [ ] Error messages are actionable (include context: what failed, with what input)
- [ ] Partial failures handled — if step 3 of 5 fails, are steps 1-2 rolled back or is state consistent?

### Resource Cleanup

- [ ] Connections (DB, HTTP, WebSocket) closed after use — check for `try/finally`, `defer`, `using`, or equivalent
- [ ] File handles released — no open file descriptors leaking on error paths
- [ ] Timers and intervals cleared on component unmount / process exit
- [ ] Event listeners removed when no longer needed
- [ ] Temporary files cleaned up

### Concurrency

- [ ] No shared mutable state accessed from multiple threads/goroutines/async tasks without synchronization
- [ ] No race conditions on read-modify-write sequences (check for non-atomic updates)
- [ ] Deadlock potential — are multiple locks acquired in consistent order?
- [ ] Async operations have proper error handling (no unhandled promise rejections, no fire-and-forget)

### Unbounded Operations

- [ ] Loops have termination guarantees — no infinite loops on unexpected input
- [ ] List endpoints have pagination (limit + offset or cursor)
- [ ] Batch operations have size limits
- [ ] Retries have max count + exponential backoff (no infinite retry loops)
- [ ] Recursive functions have depth limits

### Database & Queries

- [ ] No N+1 queries — no database query inside a loop; use joins or batch fetches
- [ ] Queries have appropriate indexes (check WHERE/JOIN columns)
- [ ] Transactions used for multi-step mutations that must be atomic
- [ ] Large result sets are streamed, not loaded entirely into memory
- [ ] Migrations are backwards-compatible (no column drops without migration period)

### Input Validation

- [ ] All user input validated at system boundary (API handlers, form submissions, CLI args)
- [ ] Size limits on string inputs, file uploads, request bodies
- [ ] Type validation — reject unexpected types early, don't coerce silently
- [ ] Enum/allowlist validation for constrained fields (status, role, etc.)
- [ ] Path traversal prevention on file operations with user-provided paths

### Security

- [ ] No SQL injection — parameterized queries or ORM, never string concatenation
- [ ] No XSS — output encoding/escaping for user content rendered in HTML
- [ ] No command injection — no `exec(user_input)` or `system(user_input)`
- [ ] Auth checks on every protected endpoint/operation — not just the frontend
- [ ] Secrets not in code, logs, error messages, or stack traces
- [ ] CORS configured to allow only expected origins
- [ ] Rate limiting on authentication endpoints

### Timeout & Retry

- [ ] External HTTP calls have timeouts (connect + read)
- [ ] Database queries have statement timeouts
- [ ] Retries use exponential backoff with jitter
- [ ] Circuit breaker pattern for frequently-failing dependencies
- [ ] Graceful degradation — if dependency X is down, what happens? Crash or fallback?

### Memory & Performance

- [ ] Large objects not held in memory longer than needed
- [ ] Streaming used for large payloads (files, large API responses) instead of buffering
- [ ] Cache has eviction policy (TTL, LRU, or size-based) — no unbounded caches
- [ ] No blocking operations on hot paths (I/O on request thread, sync file reads on event loop)
- [ ] Logging level appropriate — no debug-level logging in production paths

---

## How to Use in Review

For each checklist item that applies to the code under review:

1. **Check** — does the code handle this correctly?
2. **If yes** — move on
3. **If no** — flag in review with severity and `file:line` citation
4. **If N/A** — skip (not all items apply to every review)

Don't check items that clearly don't apply (e.g., don't check database queries if the code doesn't use a database).

## Anti-Patterns

- Checking every item mechanically regardless of relevance — focus on what the code actually does
- Flagging theoretical concerns as P0 — use evidence-based severity per `rules/severity-discipline.md`
- Reviewing only the happy path — error paths and edge cases are where reliability issues live
