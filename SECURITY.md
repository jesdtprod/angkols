Review and strengthen this web application’s security, data integrity, and performance based on its actual architecture.

The project contains an HTML/JavaScript frontend, Supabase-related files, an Apps Script folder, and a service worker. Inspect how these components are used before deciding which controls apply.

Read AGENTS.md, SECURITY.md, and applicable project instructions first. Follow current OWASP guidance and official documentation for the technologies in use.

Implement focused, maintainable fixes while preserving legitimate workflows and existing functionality.

1. Architecture and trust boundaries

Map authentication, user roles, database access, API endpoints, integrations, browser storage, caching, and deployment configuration.

Identify which components enforce security. Treat frontend code, browser storage, request parameters, and client-provided values as untrusted.

Distinguish confirmed vulnerabilities from potential risks and configuration that cannot yet be verified.

2. Authentication and session management

Review login, logout, password recovery, session expiration, and token handling. Use the authentication provider’s supported security mechanisms.

If the application manages passwords directly, use an appropriate password-hashing algorithm and never store plaintext passwords.

Verify token authenticity, expiration, and intended use at trusted endpoints. Ensure logout clears private application state and account switching cannot expose the previous user’s data.

Use secure cookie settings where cookie-based authentication is used. Apply CSRF protection where the authentication mechanism requires it.

Protect privileged accounts with MFA where supported and appropriate. Require recent authentication for highly sensitive account changes.

3. Authorization and role management

Enforce authorization at the backend or database layer for every protected operation.

Check both the user’s role and permission to access the specific requested record. Prevent unauthorized access by changing IDs, URLs, request bodies, or API parameters.

Do not rely on hidden buttons, disabled controls, frontend route guards, or client-provided roles as security boundaries.

Prevent users from granting themselves privileges. Restrict role changes and administrative actions to authorized users.

4. Supabase and database security

Review Row Level Security policies and database grants for exposed tables, views, storage buckets, and database functions.

Verify SELECT, INSERT, UPDATE, and DELETE permissions separately. Ensure updates cannot move records into an unauthorized user’s or organization’s ownership.

Test unauthenticated access, normal user access, administrative access, and attempts to access another user’s records.

Review SECURITY DEFINER functions, execution grants, search paths, and other elevated database operations for privilege escalation risks.

Keep service-role keys, secret keys, and database credentials out of frontend code and version control. Public client configuration must be backed by correctly enforced database permissions.

5. SQL injection and query safety

Use parameterized queries or safe parameter binding for user-provided values. Never concatenate untrusted input into SQL.

Review Supabase RPC functions, dynamic SQL, backend queries, and raw filter expressions.

Use explicit allowlists for dynamic table names, column names, sort directions, and other identifiers that cannot be parameterized.

Validate input types, lengths, ranges, and accepted values. RLS and input validation must complement safe queries rather than replace them.

6. Input validation and frontend security

Validate incoming data at the trusted backend or database boundary, in addition to frontend validation.

Review innerHTML, HTML templates, URL handling, and other DOM operations for XSS risks. Prefer safe text rendering and context-appropriate output encoding. Sanitize rich HTML only where intentionally supported.

Prevent mass assignment by explicitly selecting fields users are allowed to change.

Validate request content types, payload sizes, pagination limits, and file metadata. Return useful errors without exposing stack traces, queries, credentials, or internal implementation details.

7. Rate limiting and abuse protection

Enforce rate limits at a trusted layer such as the backend or API gateway. Frontend throttling alone is insufficient.

Prioritize authentication, password recovery, public endpoints, searches, exports, expensive reports, uploads, and sensitive writes.

Choose limits appropriate to each operation, using user, account, and IP information where suitable. Trust forwarded IP headers only when provided by a trusted proxy.

Ensure enforcement works across server instances where applicable. Verify protected operations cannot bypass limits through a directly exposed alternative API.

Return HTTP 429 with appropriate retry guidance. Use bounded retries with backoff and avoid retrying non-idempotent operations automatically.

Use frontend debouncing and submission controls for usability, alongside trusted enforcement.

8. Transaction integrity and business rules

For orders, sales, expenses, inventory, bank transactions, and similar records, enforce critical business rules at the backend or database layer.

Calculate or validate authoritative totals, prices, discounts, balances, and stock changes using trusted data.

Use database transactions for operations that must succeed or fail together. Address concurrent updates, duplicate requests, and replayed submissions.

Use idempotency and database constraints where appropriate. Ensure users cannot bypass approval, cancellation, refund, or record-locking rules through direct requests.

9. Secrets and sensitive data

Keep secrets in an appropriate server-side secret store or environment configuration.

Review source code, tracked configuration, generated assets, logs, and build output for exposed credentials. If a secret has been exposed, identify the need for rotation; removing it from the current file alone is insufficient.

Retrieve and return only the information each user needs. Protect sensitive exports and downloads with the same authorization rules as the original records.

Exclude passwords, access tokens, privileged keys, and unnecessary personal data from logs and analytics.

10. Apps Script and external integrations

If Apps Script or other integrations are active, inspect deployment permissions, execution identity, authentication, authorization, validation, and secret storage.

Do not treat an endpoint URL, CORS setting, or secret embedded in JavaScript as sufficient authentication.

Where webhooks are used, verify signatures and apply appropriate replay protection. Restrict outbound destinations where user-controlled URLs could cause server-side request forgery.

11. Uploads and storage

Where uploads are supported, enforce authorization, file-size limits, allowed formats, and content validation at a trusted layer.

Do not trust file extensions or client-supplied MIME types alone. Prevent executable or active content from being served in an unsafe context.

Review storage policies and download access. Use private storage and appropriately scoped, expiring links where required.

12. Service worker, caching, and browser storage

Review service worker caching, localStorage, sessionStorage, IndexedDB, and offline behavior.

Define which data may be stored, for how long, and for which user. Prevent private responses or cached records from being exposed after logout or account switching.

Avoid unnecessary persistence of sensitive data. Review token storage against the authentication provider’s supported approach and the application’s XSS risks.

Ensure service worker updates and cache invalidation work correctly without serving incompatible or stale application files.

13. Deployment and dependencies

Review HTTPS, security headers, Content Security Policy, framing restrictions, CORS, and production error handling.

Use explicit allowed origins where appropriate. Do not use CORS as a substitute for authentication or authorization.

Inspect dependencies and externally loaded scripts for known vulnerabilities. Apply compatible fixes and verify affected features.

Prevent deployment of private configuration, backups, database dumps, debug endpoints, and other internal files.

14. Audit logging and recovery

Record security-relevant events and sensitive business changes, including permission changes, important record modifications, and financial operations where applicable.

Capture the actor, action, target, timestamp, and outcome without logging secrets. Protect audit records against unauthorized modification and deletion.

Review backup coverage, retention, access restrictions, and recovery procedures. Verify restoration in a safe environment before claiming recovery readiness.

15. Code and database optimization

Measure relevant bottlenecks before optimizing.

Address duplicate API requests, N+1 queries, excessive data retrieval, unnecessary polling, unused realtime subscriptions, event-listener leaks, and expensive rendering.

Use explicit field selection, pagination, bounded queries, and indexes supported by actual query patterns.

Apply caching with correct authorization scope, expiration, and invalidation. Never improve performance by removing validation, authorization, RLS, or necessary audit logging.

Keep changes focused and avoid unrelated rewrites.

16. Verification and completion criteria

Use a safe test environment and controlled request volumes. Do not perform destructive tests against production.

Verify:

- Unauthenticated users cannot access protected data or operations.
- Users cannot access another user’s or organization’s records.
- Roles cannot be escalated through modified requests.
- Malicious input cannot alter query intent or execute unintended scripts.
- Rate limits apply at the trusted enforcement layer.
- Repeated or concurrent submissions preserve transaction integrity.
- Logout and account switching do not expose cached private data.
- Existing authorized workflows continue to function.

Document findings and results in SECURITY.md. For each material issue, include severity, affected component, evidence, implemented fix, and verification status.

Separate completed code changes from pending database, Supabase dashboard, hosting, or credential-rotation actions. Provide exact migration or configuration steps when needed.

Report anything that could not be tested. Do not claim the application is fully secure or mark unverified protections as complete.