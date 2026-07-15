# Fernecito - Owner Manager

Internal/admin manager for Fernecito platform operations.

[![PWA](https://img.shields.io/badge/PWA-Live-5A0FC8?logo=pwa&logoColor=white)](https://fernecitoapp.online)
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white)
![Vercel](https://img.shields.io/badge/Vercel-000000?logo=vercel&logoColor=white)

Live PWA: [fernecitoapp.online](https://fernecitoapp.online)

## What It Does

Owner Manager is the central workspace used to supervise and operate the Fernecito ecosystem.

Core flows:

- Review platform activity from a centralized dashboard.
- Support administrative and moderation workflows.
- Manage operational status across users, venues and events.
- Keep platform-level controls separated from venue-facing tools.
- Provide a secure internal surface for product operations.

## Product Context

Fernecito is split into specialized apps instead of forcing every role into one interface:

- Users App: event discovery, reservations, squads and QR flows.
- Locales App: venue and staff operations.
- Owner Manager: this repository, focused on central administration.
- Backend: private Supabase project with Edge Functions and database logic.

## Stack

- Flutter / Dart
- Flutter Web as PWA
- Supabase Auth and database integration
- Vercel prebuilt deployment
- Operational dashboard UX

## Security Notes

This public repository is safe portfolio material. It does not expose production backend source, private database migrations, service-role keys or operational secrets.

Local `.env` files are ignored. Production builds inject public runtime configuration at build time and block `.env` requests in the deployed static output.

## Run Locally

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=URL_SUPABASE="your-url" \
  --dart-define=CLAVE_PUBLICA_SUPABASE="your-anon-key"
```

## Production Build

```bash
./deploy.sh
```

The deploy script builds locally, prepares Vercel prebuilt output and deploys the production PWA.

## Engineering Highlights

- **Owner-gated by design.** Administrative actions are separated from user- and venue-facing flows and authorized at the edge, never trusted from the client.
- **Operations dashboard.** Platform metrics, subscription/payment review, moderation queues and support tickets in one internal surface.
- **Targeted push at scale.** Compose and send geo-segmented, deduplicated broadcasts across the ecosystem's apps.
- **Moderation & support.** Review reported accounts/events and resolve support cases with clear, auditable state transitions.

## Why It Matters

This project shows platform thinking: separating user, venue and admin roles into purpose-built products while keeping production deployment and security constraints in mind.
