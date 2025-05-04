# MinIO

## Purpose
Object storage for media files (e.g., user-uploaded post images).

## Why MinIO?
- S3-compatible: no need to rewrite SDK logic.
- Lightweight, self-hosted, and scalable.
- Supports redundancy and access control.

## Use Cases
- Store and serve images attached to posts.
- Decouple binary data from structured databases.

## Justification Summary
MinIO provides cost-effective media storage without sacrificing S3 compatibility. Ideal for social apps where users frequently upload images.
