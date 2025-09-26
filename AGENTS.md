# Repository Guidelines

## Project Structure & Module Organization
HeyWish runs as a monorepo. `web/` contains the Next.js 14 app and API; routes live in `app/`, shared UI in `components/ui`, and utilities in `lib/`. `mobile/` holds the Flutter client with code split across `lib/screens`, `lib/services`, and `lib/widgets`, while platform configs stay in `ios/` and `android/`. `extension/` hosts the Chrome extension scaffold. Reference material lives in `docs/` and the SQL-focused `documentation/database/` directory.

## Build, Test, and Development Commands
From `web/`, run `npm run dev` for the local server, `npm run build` before deploys, and `npm run lint` to enforce the Next.js ESLint rules. In `mobile/`, execute `flutter pub get` after touching dependencies, `flutter run` for iteration, and `flutter build ipa` or `flutter build appbundle` when preparing releases. Bootstrapping the extension currently requires `npm install`; align future scripts with the web package (`npm run dev`, `npm run build`) once the tooling lands.

## Coding Style & Naming Conventions
Web code follows the default Next.js ESLint profile: keep two-space indentation, export React components with `PascalCase`, and retain lowercase filenames (`components/ui/button.tsx`). Tailwind classes should mirror the utility-first ordering already in the repo. Flutter inherits `flutter_lints`; prefer `const` widgets, snake_case filenames, and grouped imports. SQL files in `documentation/database/` remain lower_snake_case and should document intent inline when altering production tables.

## Testing Guidelines
Linting is currently the primary guard on the web app; pair new features with Jest or Playwright coverage placed alongside the affected route (`web/app/.../__tests__`). Always run `npm run lint` before pushing. Flutter logic should be validated with `flutter test`, targeting widget behavior and service integrations; add golden tests for UI regressions when feasible. Capture manual QA notes in the PR if automated coverage is missing.

## Commit & Pull Request Guidelines
Commits generally follow Conventional Commits (`feat:`, `fix:`, `docs:`). Keep summaries under 72 characters, isolate changes per platform, and include migration scripts in the same commit as related code. Pull requests should link issues, call out environment or schema changes, and attach screenshots or screencasts for UI updates. Mention corresponding SQL files or config updates so reviewers can trace the impact.

## Security & Configuration Tips
Store secrets in local `.env` files (`web/.env.local`, `mobile/.env`) and never commit them. Firebase keys, Render connection strings, and Chrome extension tokens belong in the shared secret manager rather than git. Stage database migrations under `documentation/database/` and coordinate deploy windows with the backend when altering live tables.
