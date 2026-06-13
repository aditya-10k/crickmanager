---
title: CrickManager Backend
emoji: 🏏
colorFrom: green
colorTo: blue
sdk: docker
app_port: 7860
pinned: false
---

# CrickManager Backend

Spring Boot REST API for the CricManager IPL strategy game.

## Endpoints
- `POST /api/auth/register` — register a user
- `POST /api/auth/login` — login, returns JWT
- `GET  /api/game/draft` — get a random draft squad
- `POST /api/game/simulate` — simulate the season
- `GET  /api/game/leaderboard` — global leaderboard

## Environment Secrets (set in HF Space Settings)
| Secret name | Value |
|---|---|
| `SPRING_DATASOURCE_URL` | Neon PostgreSQL JDBC URL |
| `SPRING_DATASOURCE_USERNAME` | `neondb_owner` |
| `SPRING_DATASOURCE_PASSWORD` | your Neon password |
| `SPRING_JPA_HIBERNATE_DDL_AUTO` | `update` |
