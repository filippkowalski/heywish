# Repository Guidelines

## Project Structure & Module Organization
- Monorepo layout: `web/` hosts the Next.js 14 app; API routes live under `web/app/`, shared UI in `web/components/ui`, and helpers in `web/lib/`.
- Place feature tests beside their routes, e.g. `web/app/foo/__tests__/`.
- Flutter code resides in `mobile/lib/` with screens, services, and widgets separated by folder; platform settings sit in `mobile/ios/` and `mobile/android/`.
- The Chrome extension scaffold is under `extension/`; reference docs are in `docs/`, and SQL specs in `documentation/database/`.

## Architecture & References
- Jinnie serves a modular Next.js 14 backend; REST endpoints live at `/api/v1` and verify Firebase ID tokens.
- The current web surface is read-only: it exposes public profiles and wishlists, with reservation calls flowing through the same backend.
- Reservations use Firebase email magic links (`/verify-reservation`) before marking wishes as held.
- Flutter handles the mobile client with native transitions and offline-first sync; Cloudflare R2 stores media.
- Review `docs/TECHNICAL_SPEC.md`, `docs/API_SPECIFICATION.md`, and `docs/DESIGN_SYSTEM.md` before significant updates.

## Build, Test, and Development Commands
- `cd web && npm run dev` starts the local web server; use `npm run build` before deploying and `npm run lint` prior to commits.
- `cd mobile && flutter pub get` after dependency changes, `flutter run` for iterative testing, and `flutter build ipa` or `flutter build appbundle` for releases.
- Initialize the Chrome extension with `cd extension && npm install`, keeping future scripts aligned with `web/`.

## Coding Style & Naming Conventions
- Web: Next.js ESLint defaults with two-space indentation, `PascalCase` components, lowercase filenames (e.g. `components/ui/button.tsx`), and Tailwind utilities ordered consistently.
- Flutter: follow `flutter_lints`, prefer `const` constructors, snake_case files, grouped imports, and rely on `NativeTransitions` from `mobile/lib/common/navigation/native_page_route.dart` for routes and modals.
- Document SQL intent inline and keep schema files lower_snake_case.

## Testing Guidelines
- Add Jest or Playwright suites next to the impacted route under `__tests__/`; run `npm run lint` plus any new tests before pushing.
- In Flutter, cover logic with `flutter test` and add golden tests for UI updates when feasible; capture manual QA steps in the PR if automation is light.

## Commit & Pull Request Guidelines
- Use Conventional Commits (`feat:`, `fix:`, `docs:`) under 72 characters, scoping changes per platform and bundling schema updates with code.
- PRs must link issues, describe environment or schema shifts, and include screenshots or screencasts for UI changes so reviewers can trace impact.

## Security & Configuration Tips
- Store secrets in environment files (`web/.env.local`, `mobile/.env`) or the shared secret manager; never commit API keys or tokens.
- Stage database migrations under `documentation/database/` and coordinate deploy windows with backend stakeholders before altering live tables.
