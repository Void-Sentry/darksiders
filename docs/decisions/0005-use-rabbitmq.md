# RabbitMQ

## Purpose
Asynchronous message broker used to decouple services and allow event-driven communication.

## Why RabbitMQ?
- Mature, reliable, and widely supported.
- Built-in retry and dead-letter capabilities.
- Good tooling and observability.

## Use Cases
- Notifying users about follows, likes, or mentions.
- Decoupling side-effects (e.g., sending emails, updating caches).

## Justification Summary
RabbitMQ allows services to scale independently and react to events without tight coupling. It ensures reliable delivery and reprocessing in failure scenarios.
