---
description: "Core Domain-Driven Design (DDD), Architecture, and Business Logic Rules"
globs: "*"
---
# Architecture & Business Standards (DDD)

## 🎯 Directives

### 1. Domain Analysis & Subdomains
- ALWAYS classify subdomains: **Core** (complex, competitive edge -> build in-house, Domain Model/Event Sourcing), **Generic** (complex, solved -> buy/open-source), **Supporting** (simple CRUD -> build in-house, Transaction Script/Active Record).
- ALWAYS use the **Ubiquitous Language (UL)** for all class, method, and variable names. NEVER use technical jargon (e.g., `Manager`, `Processor`).
- ALWAYS resolve ambiguous or synonymous business terms into strict, single-meaning definitions.

### 2. Bounded Contexts (BC) & Integration
- ALWAYS enforce Bounded Contexts as strict linguistic and physical boundaries. One team per BC.
- ALWAYS define integration patterns explicitly (Context Map):
  - **Anticorruption Layer (ACL)**: ALWAYS use for downstream Core Subdomains to translate and protect against upstream legacy/foreign models.
  - **Open-Host Service (OHS) & Published Language (PL)**: ALWAYS use upstream to expose a stable, decoupled API (e.g., JSON schema) hiding internal implementation.
  - **Shared Kernel**: ONLY use for sharing minimal integration contracts.
  - **Separate Ways**: Duplicate functionality if integration cost > duplication cost (NEVER for Core Subdomains).

### 3. Tactical Design (Domain Model)
- ALWAYS prefer **Value Objects (VO)** (immutable, no identity, value-based equality, side-effect-free, conceptual whole) over Entities.
- ALWAYS model **Entities** with unique, immutable identity (using custom VOs, e.g., `TenantId`) and mutable state. Use self-encapsulation (private setters).
- ALWAYS design **Aggregates** as strict transactional boundaries:
  - NEVER modify more than ONE Aggregate instance per database transaction. Use Eventual Consistency (Domain Events) for multi-aggregate updates.
  - NEVER reference other Aggregates by object reference; ALWAYS reference by ID.
  - ALWAYS keep Aggregates as small as possible (true invariants only).
  - ALWAYS designate one Entity as the **Aggregate Root (AR)**. All external access MUST go through the AR.
  - ALWAYS use Intention-Revealing Interfaces (e.g., `commitTo()`) and hide state mutation.
  - ALWAYS implement Optimistic Concurrency (e.g., `version` field) on the AR.
- ALWAYS use **Domain Services** for stateless operations spanning multiple Aggregates or requiring technical infrastructure. NEVER use them to strip behavior from Entities (Anemic Domain Model).
- ALWAYS use **Factories** (Factory Methods on ARs or Domain Services) to encapsulate complex creation and enforce invariants. Hide constructors.
- ALWAYS restrict **Repositories** to Aggregate Roots ONLY. Hide persistence details. NEVER manage transactions inside Repositories.

### 4. Business Logic & Architecture Patterns
- ALWAYS align architecture with business logic complexity:
  - **Transaction Script**: Simple procedural logic. Use Minimal Layered Architecture. Test via Reversed Pyramid (E2E).
  - **Active Record**: Simple logic, complex data mapping. Use Layered Architecture + Application Service. Test via Diamond (Integration).
  - **Domain Model**: Complex rules/invariants. Use Ports & Adapters (Hexagonal). Test via Pyramid (Unit).
  - **Event-Sourced Domain Model (A+ES)**: Financial/audit-heavy domains. State is an append-only stream of Domain Events. ALWAYS pair with CQRS. Separate `Apply` (append event) and `Mutate` (update state).
- ALWAYS keep **Application Services** thin. They MUST ONLY handle task coordination, transaction boundaries, and security. NEVER put business logic in Application Services. Use Command Objects for input.

### 5. Communication & Event-Driven Architecture (EDA)
- ALWAYS classify asynchronous messages: **Events** (past tense, e.g., `OrderSubmitted`) or **Commands** (imperative, e.g., `SubmitOrder`).
- ALWAYS select the correct Event type:
  - **Event Notification**: Lightweight ping (ID/link). Use for sensitive data or strict concurrency.
  - **Event-Carried State Transfer (ECST)**: State snapshot. Use for local caching/high availability.
  - **Domain Event**: Internal BC modeling. NEVER expose raw Domain Events externally; translate to a Published Language.
- ALWAYS use the **Outbox Pattern** (atomic save of state + outgoing events) to guarantee at-least-once delivery.
- ALWAYS design consumers to be **Idempotent**.
- ALWAYS use **Sagas** for linear, multi-step processes across BCs (with compensating actions). Use **Process Managers** for complex workflows with conditional routing.

### 6. Microservices & Modules
- ALWAYS design Microservices as "deep modules" aligned with Subdomains. Encapsulate the database. Compress public interfaces (OHS).
- NEVER create "shallow services" (e.g., single-method or single-aggregate services) that cause Distributed Big Balls of Mud.
- ALWAYS group cohesive domain concepts into **Modules** (namespaces/packages) using the UL (e.g., `com.company.context.domain.model.concept`). NEVER group mechanically (e.g., all exceptions together).

### 7. Legacy Modernization & Data Mesh
- ALWAYS use the **Strangler Pattern** with a Façade to incrementally replace legacy systems.
- ALWAYS treat analytical data as a **Data Product** owned by the operational Bounded Context (Data Mesh).
- ALWAYS use CQRS to project operational events into analytical **Fact** (append-only) and **Dimension** (normalized) tables. Expose via Polyglot Data Endpoints. NEVER extract directly from operational DB schemas.

### 8. EventStorming
- ALWAYS follow the 10-step process for complex domains: Domain Events (Orange, past tense) -> Timelines -> Pain Points (Pink) -> Pivotal Events -> Commands (Blue, imperative) & Actors (Yellow) -> Policies (Purple) -> Read Models (Green) -> External Systems (Pink) -> Aggregates (Yellow) -> Bounded Contexts.

## 📝 Examples

### ✅ DO
```csharp
// DO: Small Aggregate, ID references, Intention-Revealing Interface, Eventual Consistency
public class Ticket : Entity 
{
    private TicketId _id;
    private CustomerId _customerId; // ID reference, not object
    private int _version;

    // Hidden constructor
    protected Ticket() { }

    // Intention-revealing command
    public void Escalate(EscalationReason reason) 
    {
        if (this.IsClosed) throw new DomainException("Cannot escalate closed ticket.");
        
        this.IsEscalated = true;
        this._version++;
        
        // Publish Domain Event for eventual consistency
        DomainEventPublisher.Instance.Publish(new TicketEscalated(_id, reason));
    }
}

// DO: Thin Application Service handling transactions and coordination
public class TicketService 
{
    [Transactional]
    public void EscalateTicket(TicketId id, EscalationReason reason) 
    {
        var ticket = _repository.Load(id);
        ticket.Escalate(reason);
        _repository.Save(ticket); // Outbox pattern handled by repository/infrastructure
    }
}
```

### ❌ DON'T
```csharp
// DON'T: Large cluster, object references, anemic domain model, multi-aggregate transactions
public class Ticket 
{
    public Guid Id { get; set; }
    public Customer Customer { get; set; } // Direct object reference
    public bool IsEscalated { get; set; }
}

public class TicketService 
{
    [Transactional]
    public void EscalateTicket(Guid ticketId, string reason) 
    {
        var ticket = _repository.Load(ticketId);
        
        // Business logic leaked into Application Service
        if (ticket.Status == "Closed") return; 
        
        ticket.IsEscalated = true;
        
        // Modifying multiple aggregates in one transaction
        ticket.Customer.EscalationCount++; 
        
        _repository.Save(ticket);
        _customerRepository.Save(ticket.Customer);
        
        // Unsafe event publishing (prone to dual-write failure)
        _messageBus.Publish(new TicketEscalatedEvent(ticketId)); 
    }
}