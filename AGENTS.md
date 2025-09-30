# Repository Guidelines

## Project Structure & Module Organization
HeyWish runs as a monorepo. `web/` hosts the Next.js 14 app and API routes under `app/`; shared UI lives in `components/ui`, and helpers in `lib/`. Flutter code sits in `mobile/lib` with screens, services, widgets split by folder, while platform configs stay in `mobile/ios` and `mobile/android`. The Chrome extension scaffold is in `extension/`. Reference docs live in `docs/` and SQL specs in `documentation/database/`. Keep tests beside routes or features (`web/app/foo/__tests__`) and Flutter widgets.

## Build, Test, and Development Commands
From `web/`, run `npm run dev` for the local server, `npm run lint` before commits, and `npm run build` ahead of deploys. In `mobile/`, call `flutter pub get` after dependency edits, `flutter run` for iteration, and `flutter build ipa` or `flutter build appbundle` when shipping. Bootstrapping the extension currently requires `npm install`; align future scripts with the web package (`npm run dev`, `npm run build`).

## Coding Style & Naming Conventions
Web follows the default Next.js ESLint profile: two-space indent, `PascalCase` components, and lowercase file names like `components/ui/button.tsx`. Tailwind classes should stick to the utility-first ordering already in use. Flutter code adopts `flutter_lints`, favors `const` constructors, snake_case filenames, and grouped imports. Document SQL intent inline and keep files lower_snake_case.

## Testing Guidelines
Linting guards most web changes; add Jest or Playwright suites beside affected routes under `__tests__`. Run `npm run lint` and any new tests before opening a PR. For Flutter, target logic with `flutter test` and add golden tests for UI deltas when reasonable. Capture manual QA notes in the PR if coverage is light.

## Commit & Pull Request Guidelines
Commits follow Conventional Commits (`feat:`, `fix:`, `docs:`) under 72 characters and should isolate changes per platform. Include schema updates alongside related code. PRs must link issues, call out environment or schema shifts, and attach screenshots or screencasts for UI updates so reviewers can trace impact.

## Security & Configuration Tips
Secrets belong in local `.env` files (`web/.env.local`, `mobile/.env`) or the shared secret manager. Never commit Firebase keys, Render strings, or extension tokens. Stage database migrations under `documentation/database/` and coordinate deployment windows with backend before altering live tables.
