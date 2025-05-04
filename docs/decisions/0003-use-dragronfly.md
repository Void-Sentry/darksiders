# Dragonfly

## Purpose
In-memory cache used to accelerate access to frequently queried data.

## Why Dragonfly instead of Redis?
- Much faster than Redis under concurrent workloads.
- Lower memory usage.
- Drop-in compatibility with existing Redis clients.

## Use Cases
- Caching follower/following counts.
- Feed assembly optimizations.

## Justification Summary
Dragonfly improves performance with minimal config change compared to Redis. It supports high throughput needed for real-time user interactions.
