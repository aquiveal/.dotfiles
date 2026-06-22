---
description: Core architecture and integration standards for designing APIs, microservices, and messaging systems.
globs: **/*.{ts,js,java,cs,py,go,md}
---
# Architecture & Integration Standards

## 🎯 Directives

### API Design & RESTful Principles
- ALWAYS use standard HTTP methods correctly: `GET` (read, idempotent), `POST` (create/action), `PUT` (replace, idempotent), `PATCH` (partial update), `DELETE` (remove, idempotent).
- ALWAYS use nouns for resource URIs (e.g., `/users/123`), NEVER verbs (e.g., `/getUser/123`).
- ALWAYS enforce statelessness. NEVER store client session state on the server.
- ALWAYS implement pagination (cursor-based preferred for large datasets) and filtering via query parameters.
- ALWAYS version APIs (e.g., via `Accept` header or URI `/v1/`) and maintain backward compatibility (additive changes only).
- ALWAYS return standard HTTP status codes (2xx, 3xx, 4xx, 5xx) and structured, machine-readable error payloads.
- NEVER use Basic Authentication for public APIs; ALWAYS use OAuth 2.0 or JWT with granular scopes.

### Messaging & Enterprise Integration Patterns
- ALWAYS decouple applications using asynchronous messaging (Publish-Subscribe for events, Point-to-Point for commands/documents).
- ALWAYS separate routing/system metadata (Headers) from business data (Body) in messages.
- ALWAYS use a Dead Letter Channel for undeliverable/expired messages and an Invalid Message Channel for parsing errors.
- ALWAYS implement Idempotent Receivers to safely handle duplicate message deliveries.
- NEVER hardcode reply channels; ALWAYS use a `Return Address` and `Correlation Identifier` for Request-Reply patterns.
- NEVER mix different data schemas on the same channel; ALWAYS use Datatype Channels.
- ALWAYS use a Messaging Gateway to encapsulate messaging infrastructure APIs away from business logic.

### Microservices & API Gateways
- ALWAYS route external traffic through an API Gateway (Layer 7) for cross-cutting concerns (auth, rate limiting, SSL termination).
- ALWAYS assign an isolated, exclusive database to each microservice (Polyglot Persistence). NEVER share databases or use cross-service SQL JOINs.
- ALWAYS use Circuit Breakers with fallbacks and Retries (with exponential backoff) for downstream service calls.
- ALWAYS pass a Correlation ID across all microservice boundaries for distributed tracing.
- NEVER store rate-limiting counters or state in the API Gateway's local memory; use a distributed cache (e.g., Redis).

## 📝 Examples

### ✅ DO
```http
GET /api/v1/users/123/orders?limit=50&cursor=eyJpZCI6MTIzNDV9 HTTP/1.1
Authorization: Bearer <token>
Accept: application/json
```

```java
// Messaging Gateway abstracting infrastructure
public interface OrderGateway {
    void sendOrder(Order order);
}
```

### ❌ DON'T
```http
// Anti-pattern: Verbs in URI, stateful session cookie, missing version
POST /api/updateUserOrder HTTP/1.1
Cookie: session_id=abcxyz
```

```java
// Anti-pattern: Infrastructure leaked into business logic
public void processOrder(Order order) {
    JMSContext context = connectionFactory.createContext();
    // ...
}