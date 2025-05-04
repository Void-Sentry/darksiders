# Capacity Planning

This document outlines the projected resource requirements for the Darksiders microservices platform, based on expected user growth, data storage, and message throughput. The plan aims to ensure performance, reliability, and cost-efficiency.

---

## 1. Traffic Assumptions

| Metric                          | Estimate                          |
|---------------------------------|-----------------------------------|
| Monthly Active Users (MAU)      | 100,000                           |
| Peak Concurrent Users           | 5,000                             |
| Average Requests/User/Day       | 200                               |
| Peak API Requests per Second    | ~2,000 RPS                        |
| Average Post Size               | 500 KB (with image)               |
| Daily New Posts                 | 50,000                            |
| Average Follows/Day             | 30,000                            |
| Daily Notifications             | ~80,000                           |

---

## 2. Services & Resource Estimates

### 🟩 Death (Followers Service)
- **CPU**: 1 vCPU per 2,000 RPS
- **RAM**: 512MB per instance
- **Scale**: 2–4 replicas (HPA enabled)
- **Storage (CockroachDB)**: ~5GB/year (index-heavy)

### 🟩 War (Profiles Service)
- **CPU**: Low — mostly reads/writes at user registration
- **RAM**: 512MB
- **Scale**: 1–2 replicas
- **Storage**: ~2GB/year (low write frequency)

### 🟩 Fury (Posts & Likes Service)
- **CPU**: 2 vCPU per 1,000 RPS (due to media handling)
- **RAM**: 1GB per instance
- **Scale**: 3–6 replicas (based on post traffic)
- **MinIO Storage**: ~1TB/year (based on image usage)
- **CockroachDB Storage**: ~50GB/year (post content + likes)

### 🟩 Strife (Notifications)
- **CPU**: 0.5 vCPU per 1,000 msg/s
- **RAM**: 512MB per instance
- **Scale**: 2–3 consumers
- **RabbitMQ Throughput**: ~100 msg/s avg, ~1,000 msg/s burst

---

## 3. Infrastructure Components

### 🛠 CockroachDB (3-node cluster)
- **vCPU**: 4–8 per node
- **RAM**: 16–32 GB per node
- **Disk**: SSD, 2TB/node (with 50% usage target)
- **Scaling**: Add nodes based on IOPS or storage pressure

### 🛠 RabbitMQ (3-node cluster)
- **vCPU**: 2–4 per node
- **RAM**: 4–8 GB per node
- **Storage**: Minimal (ephemeral queues + retention <24h)

### 🛠 Dragonfly
- **Memory**: 8–16 GB (mostly in-memory cache)
- **CPU**: 2–4 vCPU
- **Scaling**: Horizontal or vertical as needed

### 🛠 MinIO (2–3 nodes)
- **Storage**: S3-compatible disks, starting at 2TB/node
- **CPU/RAM**: 2 vCPU, 4GB RAM per node
- **Scaling**: Horizontally with erasure coding enabled

---

## 4. Frontend (Eireneon)

### Next.js (Nginx)
- **Peak Concurrent Sessions**: 5,000
- **Deployment Target**: Edge CDN
- **RAM**: 1–2 GB per instance
- **CPU**: 2 vCPU
- **Scale**: Auto-scaled via load balancer (HAProxy)

---

## 5. Load Balancer (HAProxy)

- **vCPU**: 2–4
- **RAM**: 2 GB
- **Throughput Target**: 5,000 RPS sustained
- **Scaling Strategy**: Active-passive or LVS-backed replication

---

## 6. Scaling Strategy

| Component        | Strategy                                 |
|------------------|------------------------------------------|
| Backend Services | Horizontal Pod Autoscaling (HPA)         |
| RabbitMQ         | Sharded queues + clustered nodes         |
| CockroachDB      | Add nodes; redistribute ranges           |
| MinIO            | Expand with erasure coding               |
| Dragonfly        | Vertical scale first; shard if needed    |
| HAProxy          | Keepalive + sticky sessions              |

---

## 7. Alerts & Monitoring

- **Prometheus/Grafana**: Metrics collection (CPU, memory, DB queries)
- **AlertManager**: Notify on saturation, latency, and failures
- **Health checks**: Readiness and liveness for all pods

---

## 8. Backup & Disaster Recovery

- **CockroachDB**: Nightly backups, WAL archiving
- **MinIO**: Weekly image snapshot + replication
- **RabbitMQ**: Queue mirroring + persistent disk

---

## 9. Cost Estimation (Optional)

Can be provided in a separate spreadsheet or broken down by:
- Compute (vCPUs, memory)
- Storage (MinIO, CockroachDB)
- Network (egress, internal traffic)
- Object storage cost per GB/month

---

## 10. Future-Proofing

- Plan for sharded feed delivery or fan-out on write (for scaling Fury)
- Consider CDN-based media delivery for MinIO
- Optional: Replace RabbitMQ with Kafka if message throughput exceeds 10k/sec
