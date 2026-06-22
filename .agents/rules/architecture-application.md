---
description: Condensed Master Architecture & Coding Standards for AI Agents
globs: *
---
# Elite Architecture & Coding Standards

This document condenses the master repository rules into a dense, actionable reference for AI coding agents. It preserves all critical constraints, patterns, and vocabulary from the foundational architecture texts.

## 1. Clean Architecture & SOLID Principles (Robert C. Martin)
- **The Dependency Rule**: Source code dependencies MUST point strictly inward toward high-level policies (Entities/Use Cases).
- **Entities**: Encapsulate enterprise-wide Critical Business Rules and Data. MUST NOT depend on frameworks, DBs, or UI.
- **Use Cases**: Application-specific business rules orchestrating Entities. MUST NOT contain SQL, HTML, or routing. Use simple Request/Response DTOs.
- **Interface Adapters**: Convert data between Use Cases and external agencies (Web, DB). Contains MVC components, Presenters, and DB Gateways.
- **Frameworks & Drivers**: Outermost layer. Treat frameworks as interchangeable details. Do NOT inherit core objects from framework base classes (avoid Asymmetric Marriages).
- **Boundaries**: Use Dependency Inversion (interfaces) to cross boundaries against the flow of control. Pass simple DTOs across boundaries, NEVER Entities or DB rows.
- **Main Component**: The dirtiest component. Centralizes DI, configuration, and instantiation. Plugs into high-level policy.
- **Screaming Architecture**: Top-level directories MUST reveal business intent (e.g., `/Checkout`), not frameworks (e.g., `/Controllers`).
- **SRP (Single Responsibility)**: A module should be responsible to one, and only one, actor. Separate code serving different actors.
- **OCP (Open-Closed)**: Open for extension, closed for modification. Protect high-level components from low-level changes.
- **LSP (Liskov Substitution)**: Subtypes MUST be substitutable for base types without altering caller behavior. Avoid type-checking conditionals (`instanceof`, `switch` on type).
- **ISP (Interface Segregation)**: Do not depend on unused methods. Segregate bloated interfaces into client-specific ones to avoid Architectural Baggage.
- **DIP (Dependency Inversion)**: Depend on abstractions, not concretions. Use Abstract Factories for volatile concrete object creation.
- **Component Cohesion (REP, CCP, CRP)**: Group classes that change together (CCP) and are reused together (CRP). Release as cohesive units (REP).
- **Component Coupling (ADP, SDP, SAP)**: Zero dependency cycles (ADP). Depend in the direction of stability (SDP). Stable components must be abstract (SAP).
- **Humble Object Pattern**: Split hard-to-test behaviors (UI/IO) into a Humble Object (View) and a testable object (Presenter/Interactor).
- **Partial Boundaries**: Use when full boundaries are too expensive: Skip the Last Step (same deployable), One-Dimensional (Strategy pattern), or Facade.
- **Clean Embedded Architecture**: Eliminate Target-Hardware Bottleneck using HAL, PAL, and OSAL. Test off-target.
- **The Missing Chapter (Packaging)**: Prefer Package by Component for monoliths. Use compiler access modifiers (`package-private`/`internal`) to enforce boundaries, not just folders.

## 2. Microservices Patterns (Chris Richardson & Sam Newman)
- **Bounded Contexts**: Align microservices to business domains, not technical layers. Each service MUST own its database. NO shared databases.
- **Fallacies of Distributed Computing**: Network is not reliable, latency is not zero. MUST use timeouts, retries (with backoff for transient errors), and Circuit Breakers for all remote calls.
- **Stamp Coupling**: Minimize payload size. Do not send 500kb if only 200 bytes are needed.
- **Sagas**: Use for distributed transactions. NO 2PC/XA. Use Choreography (events) for simple/cross-team workflows, Orchestration (central mediator) for complex/single-team workflows. Define Compensating Transactions for rollbacks.
- **API Gateway & BFF**: Use API Gateways for North-South traffic (auth, rate limiting). Use Backends for Frontends (BFF) for client-specific aggregation. Do NOT put business logic in gateways.
- **Strangler Fig Pattern**: Migrate monoliths incrementally. Extract vertical slices. Use Anti-Corruption Layers (ACL) to translate between legacy and new domain models.
- **Service Mesh**: Use for East-West traffic reliability (mTLS, retries, routing) via sidecars.
- **Communication**: Default to asynchronous messaging. Use synchronous (REST/gRPC) only when immediate response is required.
- **Architecture Quantum**: An independently deployable artifact with high functional cohesion and synchronous connascence. Dictates monolith vs distributed.
- **First Law of Distributed Object Design**: Don't distribute your objects! Use Clustering instead. Use Remote Facades and DTOs at strict distribution boundaries.
- **Testing Microservices**: Follow the Test Pyramid. Use Solitary Unit Tests for Domain Services/Controllers. Use Sociable Unit Tests for Entities/Value Objects. Use Consumer-Driven Contracts (CDC) like Pact instead of brittle E2E tests.
- **Deployment**: Serverless -> Containers -> VMs. One logical service per container. Use Deployments, Services, Liveness/Readiness probes. Externalize config via ConfigMaps/Secrets.
- **Progressive Delivery**: Separate deployment from release. Use Feature Toggles, Canary Releases, and Parallel Runs.
- **Security**: Zero Trust. mTLS for inter-service. Centralized Auth at Gateway, decentralized Authorization (via JWT claims) in services. Principle of Least Privilege. Datensparsamkeit (data frugality).
- **Scaling**: Evaluate Vertical -> Horizontal -> Partitioning -> Functional Decomposition. Implement Caching judiciously (Client, Server, Request).

## 3. Event-Driven Architecture & Streaming (Adam Bellemare & Ben Stopford)
- **Event Sourcing**: Store state as an immutable sequence of events. Rebuild state by replaying events. Use Snapshots and Upcasting.
- **CQRS**: Segregate Command (write) and Query (read) models. Update read models asynchronously via events.
- **Single Writer Principle**: Only ONE microservice may write to a specific event stream.
- **Kafka/Streaming**: Treat the event log as the single source of truth. Push data to code (materialized views/state stores) instead of remote DB queries.
- **Stateful Streaming**: Use local state stores (e.g., RocksDB) backed by compacted changelog topics.
- **Exactly-Once Processing**: Wrap consume-process-produce in Kafka transactions.
- **Schema Evolution**: Use explicit schemas (Avro/Protobuf). Prefer forward/backward compatibility. For breaking changes, use Dual Schema Upgrade Window (v1 and v2 topics).
- **Determinism**: Use Event Time (not wall-clock time). Handle late events via Grace Periods. Avoid external synchronous API calls in stream processors.
- **Dead Letter Queues (DLQ)**: Route unprocessable messages to a DLQ to prevent blocking the main stream.
- **Join-Filter-Process**: Standard streaming topology pattern. Use `selectKey` to rekey/copartition before joining.
- **Data Liberation**: Extract legacy data via Outbox Pattern, CDC (Log-Based), or Query-Based liberation.
- **FaaS/Serverless**: Map one function per microservice or per aggregate. Manage cold starts. Commit offsets ONLY after successful execution.
- **Basic Producer and Consumer (BPC)**: Use Sidecar Pattern for legacy integration, Gating Pattern for unordered prerequisites.
- **Heavyweight Frameworks**: Spark/Flink. Use Driver Mode, Checkpoints, External Shuffle Service.

## 4. Refactoring & Code Quality (Martin Fowler)
- **Two Hats**: Strictly separate adding functionality from refactoring. Do not do both simultaneously.
- **Code Smells**: Extract long functions, replace temps with queries, encapsulate mutable data, replace primitives with objects (Value Objects).
- **Conditional Logic**: Decompose complex conditionals. Use Guard Clauses for edge cases. Replace type-code switches with Polymorphism. Use Special Case (Null) Objects.
- **Testing**: Tests MUST be isolated and deterministic. Use Fresh Fixtures (no shared mutable state).
- **Test Boundary**: Tests are system components in the outermost circle. They depend on the system; the system NEVER depends on tests. Use a Testing API to bypass volatile GUIs.
- **Moving Features**: Slide Statements, Split Loop, Replace Loop with Pipeline.
- **Dealing with Inheritance**: Pull Up/Push Down methods. Replace Subclass/Superclass with Delegate (Composition over Inheritance).
- **Organizing Data**: Split Variable, Derived Variable, Value vs Reference Object.
- **Refactoring APIs**: Command-Query Separation, Flag Arguments, Preserve Whole Object.

## 5. Enterprise Application Architecture (Martin Fowler)
- **Database is a Detail**: Keep DB logic in the outermost circle. Business rules MUST be ignorant of SQL/ORM.
- **Data Source Patterns**: 
  - *Active Record*: Simple domain logic, isomorphic schema.
  - *Data Mapper*: Complex domain logic, divergent schema.
  - *Table/Row Data Gateway*: Transaction Scripts or Table Modules.
- **Unit of Work**: Track changes and commit all DB updates at the end of a business transaction.
- **Identity Map**: Cache loaded objects per session to prevent duplicate instances and inconsistent reads.
- **Lazy Load**: Defer loading related objects. Avoid Ripple Loading (N+1 queries) by using Ghost Lists.
- **Offline Concurrency**: 
  - *Optimistic Offline Lock*: Default choice. Use version numbers, check on update.
  - *Pessimistic Offline Lock*: Use only for high-conflict scenarios. Fail fast, do not block.
- **Session State**: Prefer Client Session State (encrypted DTOs) or Database Session State (Pending Tables). Avoid Server Session State in memory for clustered environments.
- **Object-Relational Structural Patterns**: Use Meaningless Keys (Identity Field). Map inheritance via Single Table, Class Table, or Concrete Table Inheritance.
- **Web Presentation Patterns**: MVC, Page/Front Controller, Template/Transform/Two Step View.
- **Base Patterns**: Gateway, Mapper, Layer Supertype, Registry, Value Object, Special Case.

## 6. Fundamentals of Software Architecture (Mark Richards)
- **Architecture Styles**: 
  - *Layered Architecture*: Enforce closed layers to maintain isolation. Beware the Architecture Sinkhole anti-pattern.
  - *Pipeline Architecture*: Unidirectional, stateless Pipes and Filters.
  - *Microkernel Architecture*: Core system + independent Plug-in components.
  - *Service-Based Architecture*: Coarse-grained services sharing a monolithic database.
  - *Space-Based Architecture*: Tuple space, Processing Units, Data Grids, Data Pumps. High elasticity, no synchronous DB bottlenecks.
  - *Orchestration-Driven SOA*: Legacy ESB pattern. High reuse, high coupling. Avoid for modern systems.
- **Architecture Characteristics**: Explicit vs Implicit, Operational vs Structural. Least Worst Architecture.
- **Measuring and Governing**: Performance Budgets, Cyclomatic Complexity, Fitness Functions, Chaos Engineering.
- **Component-Based Thinking**: Actor/Actions, Event Storming, Workflow Approach. Avoid Entity Trap.
- **Organizational & Soft Skills**:
  - *Conway's Law*: Align architecture with team structures (Stream-Aligned Teams).
  - *ADRs*: Document architecturally significant decisions using Architecture Decision Records (Context, Decision, Consequences).
  - *Risk Matrix*: Calculate risk as Impact × Likelihood. Unproven tech = 9 (High Risk).
  - *Elastic Leadership*: Adjust architectural control based on team size, familiarity, and project complexity.
  - *Negotiation*: Use "Divide-and-Conquer" for extreme requirements (e.g., 5 nines). "Demonstration Defeats Discussion". Use collaborative grammar.
  - *Diagramming*: Enforce Representational Consistency (macro before micro). Use C4 Model. Avoid "Irrational Artifact Attachment" by starting low-fidelity.
  - *Career Path*: Follow the 20-Minute Rule for daily learning. Maintain a Technology Radar (Hold, Assess, Trial, Adopt).
