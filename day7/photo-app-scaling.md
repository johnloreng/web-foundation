# SnapShare — Photo-Sharing App Scaling Plan

---

## 1. Assumptions

| #   | Assumption                                                                                                                                                      |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Registered users:** 10 million total accounts                                                                                                                 |
| 2   | **Daily Active Users (DAU):** 10 % of registered users → **1 million DAU**                                                                                      |
| 3   | **Upload rate:** Each active user uploads **1 photo per day**                                                                                                   |
| 4   | **Feed consumption:** Each active user views **50 feed pages per day** (each page loads ~10 photos)                                                             |
| 5   | **Photo size:** Average original photo = **2 MB**; thumbnail = **50 KB**                                                                                        |
| 6   | **Peak multiplier:** Traffic is not uniform; assume peak load is **5× the daily average** (covers burst traffic from viral posts, morning/evening spikes, etc.) |
| 7   | **Retention:** Photos are stored indefinitely (no deletion model assumed)                                                                                       |
| 8   | **Replication factor:** Each photo is stored in **3 geographic replicas** in object storage                                                                     |
| 9   | **Metadata:** Each photo record in the database is ~**1 KB** (owner, timestamp, caption, location, URLs)                                                        |
| 10  | **Feed page = 10 photos rendered**; the feed is pre-computed/cached, not re-queried from scratch on every request                                               |

---

## 2. Back-of-the-Envelope Estimates

### 2a. Uploads per Second

```
Daily uploads = 1,000,000 DAU × 1 photo/day
             = 1,000,000 photos/day

Average uploads/sec = 1,000,000 / 86,400 s  ≈  11.6 uploads/s

Peak uploads/sec (5× spike)
             = 11.6 × 5                      ≈  58 uploads/s
```

### 2b. Feed Views per Second

```
Each feed "view" = 1 page request = 10 photos served

Daily feed requests = 1,000,000 DAU × 50 pages/day
                    = 50,000,000 requests/day

Average feed requests/sec = 50,000,000 / 86,400  ≈  579 req/s

Average photos served/sec = 579 × 10              ≈  5,790 photos/s

Peak feed requests/sec (5× spike)                 ≈  2,894 req/s
Peak photos served/sec                            ≈  28,940 photos/s
```

### 2c. Storage per Year

```
── Original photos ──────────────────────────────────────────────────
Annual uploads  = 1,000,000 photos/day × 365 days = 365,000,000 photos/yr

Raw storage     = 365,000,000 × 2 MB             = 730,000,000 MB
                                                 ≈ 730 TB/yr

With 3× geo-replication:                         ≈ 2,190 TB/yr  (≈ 2.1 PB)

── Thumbnails ───────────────────────────────────────────────────────
Thumbnail storage = 365,000,000 × 50 KB          = 18,250,000 MB
                                                 ≈ 18.3 TB/yr

With 3× replication:                             ≈ 54.9 TB/yr

── Database metadata ────────────────────────────────────────────────
Metadata storage = 365,000,000 × 1 KB            ≈ 365 GB/yr

── Total (rough) ────────────────────────────────────────────────────
≈ 2.15 PB/yr (dominated by replicated originals)
```

---

## 3. Read-Heavy or Write-Heavy?

**SnapShare is strongly read-heavy.**

- **Write rate:** ~12 uploads/s (average)
- **Read rate:** ~5,790 photo-file requests/s (average) — almost **500× more reads than writes**

This means the architecture must be heavily optimized for reads: aggressive caching, CDN offloading, and read replicas are the primary levers for scaling.

---

## 4. Architecture Diagram

```
 Users (Mobile / Web)
        │
        │  HTTPS
        ▼
┌───────────────────┐
│       CDN         │  ◄─── thumbnails & original photos served from edge
│  (e.g. CloudFront)│
└────────┬──────────┘
         │ Cache miss / API requests
         ▼
┌───────────────────┐
│   Load Balancer   │  ◄─── distributes HTTP traffic across app servers
│  (e.g. AWS ALB)   │
└────────┬──────────┘
         │
   ┌─────┴──────┐
   ▼            ▼
┌──────┐    ┌──────┐   ... (horizontal scale)
│ App  │    │ App  │
│Server│    │Server│   ◄─── stateless; handles auth, feed gen, upload orchestration
└──┬───┘    └──┬───┘
   │            │
   │   ┌────────┘
   ▼   ▼
┌───────────────────┐
│   Cache Layer     │  ◄─── stores pre-built feed lists & photo metadata
│   (e.g. Redis)    │
└────────┬──────────┘
         │ Cache miss → read DB
         ▼
┌───────────────────────────────────┐
│        Primary Database           │  ◄─── writes (metadata, follows, likes)
│    (e.g. PostgreSQL / Aurora)     │
└────────────────┬──────────────────┘
                 │  async replication
                 ▼
┌───────────────────────────────────┐
│       Read Replica DB             │  ◄─── handles all metadata read queries
└───────────────────────────────────┘

  (upload path only)
        │
        ▼
┌───────────────────┐
│  Object Storage   │  ◄─── stores original photo files & thumbnails (S3 / GCS)
│  (e.g. Amazon S3) │
└────────┬──────────┘
         │ upload event published
         ▼
┌───────────────────┐
│   Message Queue   │  ◄─── decouples upload from thumbnail generation
│  (e.g. SQS/Kafka) │
└────────┬──────────┘
         │ consumed by
         ▼
┌───────────────────┐
│  Thumbnail Worker │  ◄─── resizes photo, writes 50 KB thumbnail back to S3
│  (e.g. Lambda /   │        then updates DB record with thumbnail URL
│   container fleet)│
└───────────────────┘
```

---

## 5. Component Explanations

| Component               | Problem It Solves                                                                                                                                                                      |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **CDN**                 | Caches photos and thumbnails at edge nodes worldwide, eliminating the need to serve ~13,890 photo files/s directly from origin servers and drastically cutting latency for end users.  |
| **Load Balancer**       | Distributes incoming HTTP requests across multiple stateless app servers so no single server becomes a bottleneck as traffic scales.                                                   |
| **App Servers**         | Execute business logic (authentication, feed generation, upload orchestration) as stateless, horizontally scalable units so new instances can be added under load.                     |
| **Cache (Redis)**       | Stores pre-built feed timelines and frequently accessed photo metadata in memory, turning expensive multi-join DB reads into sub-millisecond lookups.                                  |
| **Primary Database**    | Durably records all writes (photo metadata, user follows, likes) as the single source of truth, ensuring consistency.                                                                  |
| **Read Replica DB**     | Offloads the high volume of metadata read queries from the primary, preventing read traffic from degrading write performance.                                                          |
| **Object Storage (S3)** | Provides infinitely scalable, cost-efficient blob storage for multi-petabyte photo files, freeing the database from storing binary data.                                               |
| **Message Queue**       | Decouples photo upload (user-facing, latency-sensitive) from thumbnail creation (background, compute-heavy) so uploads return fast and thumbnail work happens asynchronously.          |
| **Thumbnail Worker**    | Performs CPU-intensive image resizing in the background, producing the 50 KB thumbnails that feed views serve instead of the full 2 MB original, saving ~97 % of CDN egress bandwidth. |

---

## 6. Photo Upload — Step-by-Step Flow

1. **Client → CDN / Load Balancer:** The user's app sends a `POST /upload` request with the photo binary through HTTPS; the CDN passes the non-cacheable POST to the load balancer.
2. **Load Balancer → App Server:** The load balancer routes the request to an available, healthy app server.
3. **App Server — Authentication:** The app server validates the user's JWT / session token and checks upload quotas.
4. **App Server → Object Storage (presigned URL):** The app server generates a time-limited presigned URL pointing to S3 and returns it to the client, so the large binary transfer goes directly client → S3 (bypassing app servers entirely).
5. **Client → Object Storage:** The client streams the 2 MB photo file directly to S3 using the presigned URL.
6. **App Server → Primary Database:** Once S3 confirms the upload (via a callback or after the presigned PUT completes), the app server writes a new photo metadata record (owner ID, S3 key, timestamp, caption) to the primary database.
7. **App Server → Message Queue:** The app server publishes a `photo.uploaded` event containing the S3 object key to the message queue and immediately returns `HTTP 200` to the client.
8. **Message Queue → Thumbnail Worker:** A thumbnail worker polls/subscribes and receives the event.
9. **Thumbnail Worker → Object Storage:** The worker downloads the original from S3, resizes it to the thumbnail dimensions, and uploads the result back to S3 under a separate key.
10. **Thumbnail Worker → Primary Database:** The worker updates the photo record with the thumbnail URL, marking the photo as fully processed and ready to appear in followers' feeds.
11. **Cache Invalidation:** The app server (or worker) invalidates or updates any pre-built feed caches in Redis for the uploader's followers, so the new photo appears in the next feed refresh.

---

## 7. Trade-offs

### Trade-off 1 — Pre-computed Feeds vs. Real-Time Fan-out

**Choice:** Feeds are pre-built and cached in Redis (fan-out on write) rather than computed fresh on each read.

- **Benefit:** Feed reads are O(1) cache lookups instead of expensive JOIN queries across follows/photos tables, keeping read latency low even at 1,300+ req/s peak.
- **Cost:** Every photo upload must fan out to all of the uploader's followers' feed caches. A celebrity with 500 K followers creates 500 K cache write operations on a single upload, potentially overwhelming Redis during viral moments. A hybrid model (fan-out on read for high-follower accounts) can mitigate this but adds algorithmic complexity.

---

### Trade-off 2 — Asynchronous Thumbnail Generation vs. Synchronous

**Choice:** Thumbnail creation happens asynchronously via a queue and worker pool, not inline during the upload request.

- **Benefit:** The upload API returns in ~200 ms regardless of image complexity, and thumbnail workers can be scaled independently of app servers. The queue also acts as a buffer against traffic spikes, preventing a flood of uploads from overwhelming workers.
- **Cost:** There is a window of time (seconds to minutes under high load) after a photo is uploaded where the thumbnail does not yet exist. The app must handle this gracefully — e.g., showing a loading placeholder or the full-resolution image as a fallback — adding UI and logic complexity. If the worker crashes before acknowledging the message, the queue must support at-least-once delivery and the worker must be idempotent.
