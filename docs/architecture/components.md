# System Components

## 1. Services

### Death
- **Purpose**: Social connection management (follow/unfollow)
- **Language**: Python
- **Framework**: Flask
- **Storage**: CockroachDB
- **Cache**: Dragonfly

### War
- **Purpose**: User profile management
- **Language**: Python
- **Framework**: Flask
- **Storage**: CockroachDB

### Fury
- **Purpose**: Post creation and interactions (likes)
- **Language**: Python
- **Framework**: Flask
- **Storage**: CockroachDB
- **Object Storage**: MinIO (for images)

### Strife
- **Purpose**: Notification delivery and management
- **Language**: Python
- **Framework**: Flask
- **Message Broker**: RabbitMQ

### Eireneon (Frontend)
- **Purpose**: User interface
- **Framework**: Next.js
- **Communication**: REST API with backend services

---

## 2. Infrastructure

### Zitadel
- **Purpose**: Authentication and Identity Management
- **Deployment**: Single instance

### CockroachDB
- **Purpose**: Relational database for all services
- **Architecture**: 3-node distributed cluster
- **PostgreSQL-compatible**: Yes

### Dragonfly
- **Purpose**: High-performance in-memory cache (used instead of Redis)

### RabbitMQ
- **Purpose**: Asynchronous message queue for inter-service communication
- **Deployment**: 3-node cluster

### MinIO
- **Purpose**: S3-compatible object storage
- **Use Case**: Hosting user-uploaded images (e.g., posts)

### Postfix + Mailpit
- **Purpose**: Email delivery and local visualization
- **Use Case**: Verification emails, notifications

### HAProxy
- **Purpose**: Reverse proxy and load balancer
- **Use Case**: External gateway to backend services
