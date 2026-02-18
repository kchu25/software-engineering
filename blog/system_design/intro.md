@def title = "System Design: A Comprehensive Introduction"
@def published = "18 February 2026"
@def tags = ["system-design"]

# System Design: A Comprehensive Introduction

With AI automating more and more coding, the real skill is shifting: **thinking in systems**. Writing a function matters less when Copilot can do it. Knowing *which* function to write, *where* it runs, *how* it scales, and *what happens when it fails*—that's what matters.

But if you've ever tried to learn system design, you've probably hit a wall. Interview prep books jump into "design Twitter" without explaining the building blocks. Blog posts assume you already know what a load balancer is. Textbooks are 800 pages long.

This post is the overview I wish I'd had. No interview tricks. Just: **what is system design, what are the pieces, and how do they fit together?**

---

## What Is System Design?

System design is the process of defining the **architecture, components, and interactions** of a system to satisfy a set of requirements.

That sounds abstract. Let's make it concrete.

When you write a script that processes a CSV file, you don't need system design. One machine, one process, done.

But what if:
- 10,000 users hit your app at the same time?
- Your database has 500 million rows?
- A server crashes at 3 AM and nobody's awake?
- Users in Tokyo need sub-100ms response times?
- You need to deploy a new feature without downtime?

**System design is how you answer these questions.** It's the discipline of building software that works reliably at scale, under real-world constraints.

---

## The Two Questions That Drive Everything

Every system design decision boils down to:

1. **What are the requirements?** (What must this system do?)
2. **What are the constraints?** (What are the limits we operate within?)

### Functional Requirements

What the system *does*:
- "Users can upload photos"
- "The system sends a notification when an order ships"
- "Users can search for products by keyword"

### Non-Functional Requirements

How the system *behaves*:
- **Availability** — Is it up when users need it? (99.9%? 99.99%?)
- **Latency** — How fast does it respond? (50ms? 500ms?)
- **Throughput** — How many requests per second can it handle?
- **Consistency** — Does every user see the same data at the same time?
- **Durability** — If the power goes out, is the data still there?
- **Scalability** — Can it handle 10x more users next year?

These non-functional requirements are where system design lives. Anyone can build an app that works for 1 user. Making it work for 1 million is the hard part.

---

## The Building Blocks

Here are the core components that appear in almost every system. Think of them like LEGO bricks—you combine them to build what you need.

### 1. Client and Server

The most basic split: something **requests** (client) and something **responds** (server).

```
User's Browser (Client) → HTTP Request → Your Server → HTTP Response → Browser
```

This is the foundation. Everything else is about making this flow fast, reliable, and scalable.

### 2. DNS (Domain Name System)

DNS translates human-readable names (`google.com`) to IP addresses (`142.250.80.46`). It's the internet's phone book.

```
User types "myapp.com"
  → DNS lookup: "myapp.com" → 203.0.113.42
  → Browser connects to 203.0.113.42
```

You usually don't build DNS yourself, but you configure it. DNS is also used for load balancing (pointing a domain to multiple IPs).

### 3. Load Balancer

When one server isn't enough, you run multiple servers. A **load balancer** distributes incoming requests across them.

```
                    ┌─→ Server 1
User → Load Balancer├─→ Server 2
                    └─→ Server 3
```

**Common strategies:**
- **Round Robin** — Rotate through servers in order
- **Least Connections** — Send to the server with fewest active connections
- **IP Hash** — Same user always goes to same server (useful for sessions)
- **Weighted** — Send more traffic to beefier servers

**Why it matters:** Without a load balancer, one server handles everything. If it dies, your app dies. With a load balancer + multiple servers, one can crash and users don't notice.

### 4. Databases

Where your data lives permanently. Two main families:

#### Relational Databases (SQL)

Structured data in tables with relationships. PostgreSQL, MySQL, SQLite.

```
Users table:
| id | name    | email           |
|----|---------|-----------------|
| 1  | Alice   | alice@mail.com  |
| 2  | Bob     | bob@mail.com    |

Orders table:
| id | user_id | product    | total  |
|----|---------|------------|--------|
| 1  | 1       | Widget     | 29.99  |
| 2  | 1       | Gadget     | 49.99  |
```

**Strengths:** ACID transactions (data is always consistent), complex queries with JOINs, well-understood, mature.

**Use when:** Your data has clear structure and relationships. Most applications start here.

#### Non-Relational Databases (NoSQL)

Flexible data without strict schemas. Several sub-types:

| Type | Examples | Good for |
|------|----------|----------|
| **Document** | MongoDB, CouchDB | JSON-like objects, flexible schemas |
| **Key-Value** | Redis, DynamoDB | Simple lookups, caching, sessions |
| **Wide-Column** | Cassandra, HBase | Time-series, IoT, massive write volumes |
| **Graph** | Neo4j, Amazon Neptune | Social networks, recommendation engines |

**Use when:** Your data doesn't fit neatly into tables, or you need extreme scale/performance for specific access patterns.

> **SQL vs NoSQL isn't a war—it's a choice.** Many real systems use both. User accounts in PostgreSQL, shopping cart in Redis, activity log in Cassandra. Pick the right tool for each job.

### 5. Cache

A cache stores frequently accessed data in memory so you don't have to hit the database every time.

```
Request → Check Cache → Hit? Return cached data (fast!)
                      → Miss? Query database, store in cache, return data
```

**Common tools:** Redis, Memcached

**Why it matters:** A database query might take 10-100ms. A cache lookup takes <1ms. For data that's read often but changes rarely (user profiles, product listings), caching is a massive win.

**Cache strategies:**
- **Cache-aside (Lazy)** — App checks cache first, loads from DB on miss
- **Write-through** — Every write goes to cache AND database
- **Write-behind** — Write to cache immediately, sync to database later (faster but riskier)
- **TTL (Time to Live)** — Data expires after N seconds, forcing a fresh fetch

**The hard problem:** Cache invalidation. When the underlying data changes, the cache has stale data. This is famously one of the hardest problems in computer science.

### 6. CDN (Content Delivery Network)

A CDN is a global network of servers that serves static content (images, CSS, JS, videos) from locations geographically close to users.

```
User in Tokyo → CDN edge server in Tokyo (fast!)
  instead of
User in Tokyo → Your server in Virginia (slow)
```

**Common CDNs:** Cloudflare, AWS CloudFront, Akamai, Fastly

**Use for:** Images, videos, static files, any content that doesn't change per-user.

### 7. Message Queue

A queue decouples components that produce work from components that process work.

```
Producer → [Message Queue] → Consumer

Example:
User uploads photo → Queue: "resize this photo" → Worker resizes photo
```

**Common tools:** RabbitMQ, Apache Kafka, Amazon SQS, Redis Streams

**Why it matters:**
- **Decoupling** — The uploader doesn't wait for the resize to finish
- **Buffering** — If 1000 photos are uploaded simultaneously, they queue up instead of crashing the resize service
- **Retry** — If a worker fails, the message stays in the queue for another worker

### 8. API Gateway

A single entry point that sits in front of your services. It handles routing, authentication, rate limiting, and more.

```
Client → API Gateway → Routes to correct service
                     → Checks authentication
                     → Applies rate limiting
                     → Logs the request
```

Instead of your client knowing about 10 different services, it talks to one gateway.

---

## Key Concepts

### Vertical vs Horizontal Scaling

**Vertical scaling (scale up):** Get a bigger machine. More RAM, more CPU.
- Simple, but there's a ceiling—you can't buy an infinitely big server.

**Horizontal scaling (scale out):** Add more machines.
- More complex (need load balancers, distributed state), but no ceiling.

```
Vertical:   1 big server          → eventually maxes out
Horizontal: 10 small servers      → add more as needed
```

Most real systems use horizontal scaling because it's the only way to handle truly large scale.

### Stateless vs Stateful Services

**Stateless:** The server doesn't remember anything between requests. Every request contains all the info needed to process it.

```
Request 1: "I'm user Alice, show my profile"
Request 2: "I'm user Alice, show my orders"
// Each request is self-contained
```

**Stateful:** The server remembers things (like sessions, connections, or cached data).

**Why it matters:** Stateless services are easy to scale horizontally—any server can handle any request. Stateful services are harder because you need to route users to the right server or share state.

**Rule of thumb:** Make services stateless whenever possible. Push state into databases, caches, or external stores.

### Replication

Keeping copies of your data on multiple machines.

```
Primary Database ──writes──→ Replica 1 (read-only)
                           → Replica 2 (read-only)
                           → Replica 3 (read-only)
```

**Why:** If the primary dies, a replica takes over. Plus, reads can be spread across replicas for better performance.

**Types:**
- **Leader-Follower** — One primary handles writes, replicas handle reads
- **Leader-Leader** — Multiple primaries can accept writes (more complex, risk of conflicts)

### Partitioning (Sharding)

Splitting your data across multiple databases, each holding a subset.

```
Users A-M → Database 1
Users N-Z → Database 2
```

**Why:** When one database can't hold all your data or handle all your traffic, you split it up.

**Common strategies:**
- **Range-based** — Shard by ranges (A-M, N-Z)
- **Hash-based** — Hash the key to determine which shard (more even distribution)

**The trade-off:** Queries that span multiple shards are expensive. You lose easy JOINs across the full dataset.

### CAP Theorem

A distributed system can provide at most **two out of three** guarantees:

- **C**onsistency — Every read returns the most recent write
- **A**vailability — Every request gets a response (even if it's stale)
- **P**artition tolerance — The system works even when network links between nodes fail

Since network partitions *will* happen in distributed systems, you're really choosing between:

- **CP** — Consistent but might be unavailable during partitions (e.g., banks choosing accuracy over speed)
- **AP** — Available but might return stale data during partitions (e.g., social media showing a slightly old like count)

> **This isn't a one-time choice.** Different parts of your system can make different trade-offs. Your payment system should be CP (never show wrong balances). Your news feed can be AP (showing a post 2 seconds late is fine).

### Consistency Models

How "up-to-date" is the data you read?

| Model | Meaning | Example |
|-------|---------|---------|
| **Strong consistency** | Always read the latest write | Bank balance |
| **Eventual consistency** | Will catch up eventually, might be stale now | Social media likes |
| **Causal consistency** | Respects cause-and-effect ordering | Chat messages |

**Strong consistency** is simplest to reason about but hardest to scale. **Eventual consistency** scales well but requires your app to handle stale reads gracefully.

---

## Common Patterns

### Rate Limiting

Protect your system from being overwhelmed (malicious or accidental).

**Algorithms:**
- **Token Bucket** — Tokens accumulate over time; each request costs a token
- **Sliding Window** — Count requests in the last N seconds
- **Fixed Window** — Count requests per time window (e.g., 100 per minute)

### Circuit Breaker

When a service you depend on starts failing, stop calling it temporarily instead of piling up errors.

```
Closed (normal) → Failures exceed threshold → Open (reject all calls)
                                               ↓ after timeout
                                            Half-Open (try one call)
                                               ↓ success? → Closed
                                               ↓ fail?    → Open
```

Prevents a failing dependency from taking down your entire system.

### Idempotency

An operation is **idempotent** if doing it multiple times produces the same result as doing it once.

```
Idempotent:     "Set balance to $100"   (safe to retry)
Not idempotent: "Add $10 to balance"    (retrying doubles the addition!)
```

**Why it matters:** In distributed systems, messages can be delivered more than once. If your operations are idempotent, retries are safe.

### Heartbeat / Health Checks

Services periodically signal "I'm alive" to a monitor. If signals stop, the system knows something is wrong and can route traffic elsewhere.

### Event-Driven Architecture

Instead of services calling each other directly, they communicate through events:

```
Traditional:  Order Service → calls → Inventory Service → calls → Notification Service
Event-driven: Order Service → publishes "OrderCreated" event
              Inventory Service subscribes → updates stock
              Notification Service subscribes → sends email
```

**Benefits:** Services are decoupled, can evolve independently, and new consumers can be added without changing the producer.

---

## Putting It All Together: A Real System

Let's walk through a simplified e-commerce platform:

```
                                    ┌─────────────┐
                              ┌────→│ Product API  │──→ Product DB
                              │     └─────────────┘
┌──────┐    ┌───────────┐     │     ┌─────────────┐
│ User │───→│   CDN      │    ├────→│ Order API    │──→ Order DB
│      │    │(static files)   │     └──────┬──────┘
│      │───→│           │     │            │
└──────┘    └───────────┘     │            ▼
       │                      │     ┌─────────────┐
       │    ┌───────────┐     │     │Message Queue │
       └───→│API Gateway│─────┤     └──────┬──────┘
            │+ Auth     │     │            │
            │+ Rate Limit│    │     ┌──────┴──────┐
            └───────────┘     │     │   Workers    │
                              │     │(email, resize│
                              │     │ inventory)   │
                              │     └─────────────┘
                              │     ┌─────────────┐
                              └────→│ User API     │──→ User DB
                                    └─────────────┘
                                           ↑
                                    ┌─────────────┐
                                    │   Cache      │
                                    │  (Redis)     │
                                    └─────────────┘
```

**What's happening:**
1. **CDN** serves static assets (images, CSS, JS)
2. **API Gateway** handles auth, rate limiting, routes to services
3. **Product/Order/User APIs** are separate services (microservices)
4. **Each has its own database** (can scale independently)
5. **Cache (Redis)** stores hot data (product listings, user sessions)
6. **Message Queue** decouples order processing from notifications, inventory updates
7. **Workers** consume queue messages asynchronously

This isn't how you'd build day one. You'd start with a monolith and evolve. But this is what a mature system looks like.

---

## How Systems Evolve

Real systems don't start complex. They grow:

### Stage 1: Monolith
```
Browser → Single Server (app + database on same machine)
```
Good for: MVPs, prototypes, small teams. **Start here.**

### Stage 2: Separate Database
```
Browser → App Server → Database Server
```
App and database on different machines. Each can be scaled independently.

### Stage 3: Add Caching
```
Browser → App Server → Cache → Database
```
Redis in front of the database. 10x read performance.

### Stage 4: Load Balancer + Multiple Servers
```
Browser → Load Balancer → App Server 1, 2, 3 → Cache → Database
```
Handle more traffic. Survive server failures.

### Stage 5: Read Replicas
```
Browser → LB → App Servers → Cache → Primary DB
                                    → Read Replica 1
                                    → Read Replica 2
```
Distribute read load across replicas.

### Stage 6: CDN + Message Queues
```
Browser → CDN (static) + LB → App Servers → Cache → DB (with replicas)
                                           → Message Queue → Workers
```
Offload static content and async processing.

### Stage 7: Microservices + Sharding
When the monolith gets too big, split into services. When the database gets too big, shard it.

**The lesson:** Don't design for Stage 7 on day one. Each stage adds complexity. Only move forward when the current stage can't handle your needs.

---

## Back-of-the-Envelope Numbers

Good system designers have intuition for rough numbers. Here are some useful ones:

### Latency

| Operation | Time |
|-----------|------|
| L1 cache read | ~1 ns |
| L2 cache read | ~4 ns |
| RAM read | ~100 ns |
| SSD random read | ~100 μs |
| HDD random read | ~10 ms |
| Network round trip (same datacenter) | ~500 μs |
| Network round trip (cross-continent) | ~150 ms |

### Throughput

| System | Rough capacity |
|--------|----------------|
| Single web server | 1,000-10,000 requests/sec |
| Single database | 5,000-10,000 queries/sec |
| Redis | 100,000+ operations/sec |
| Kafka | 1,000,000+ messages/sec |

### Storage

| Data | Rough size |
|------|-----------|
| 1 character (UTF-8) | 1-4 bytes |
| 1 tweet (280 chars + metadata) | ~1 KB |
| 1 photo (compressed) | ~200 KB - 2 MB |
| 1 minute of video (HD) | ~100-150 MB |
| 1 million users × 1 KB profile | ~1 GB |

These help you estimate: "Can one database handle this?" or "How much storage do we need?"

---

## Common Mistakes

1. **Over-engineering from day one.** Microservices for a team of 2? Sharding a database with 10,000 rows? Don't.

2. **Ignoring failure modes.** Every component will fail. What happens when the cache is down? When a database replica lags? Design for failure.

3. **Treating consistency as free.** Strong consistency across distributed systems is expensive. Choose wisely.

4. **Neglecting monitoring and observability.** A system you can't observe is a system you can't fix. Logging, metrics, tracing, alerting—build these in from the start.

5. **Forgetting the human element.** Can your team operate this system? Can someone debug it at 3 AM? Complexity has a human cost.

---

## Where To Go From Here

This post covered the **vocabulary and mental models** of system design. To go deeper:

**Concepts to explore next:**
- Consistent hashing (for distributed caching/sharding)
- Consensus algorithms (Raft, Paxos)
- Bloom filters (probabilistic data structures)
- Database indexing (B-trees, LSM trees)
- API design (REST, gRPC, GraphQL)
- Observability (distributed tracing, metrics, logging)
- Container orchestration (Docker, Kubernetes)

**The meta-skill:** System design is about **trade-offs**. There's never a "correct" answer—only trade-offs that fit your constraints. The more systems you study, the better your intuition for these trade-offs becomes.

> **The AI angle:** AI can write your code, but it can't decide your architecture—because architecture depends on business requirements, team capabilities, budget, timeline, and risk tolerance. These are judgment calls. System design is where human judgment remains irreplaceable.
