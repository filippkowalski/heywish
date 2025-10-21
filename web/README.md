## Jinnie Web Preview

Jinnie’s web client focuses on a read-only experience that mirrors the public surface area of the mobile app. Visitors can:

- Look up a profile by username or wishlist share token.
- Browse public profiles with their published wishlists.
- Reserve wishes after leaving an email address (next release will validate/verify).

The app is built with **Next.js 14**, **shadcn/ui**, and **Tailwind CSS**.

## Local Development

```bash
npm install
npm run dev
```

The dev server runs on [http://localhost:3000](http://localhost:3000). Routes of interest:

- `/` – landing page + profile/wishlist lookup.
- `/[username]` – public profile view sourced from the backend.
- `/[username]/[wishlist]` – public wishlist detail with reservation dialog.
- `/w/[token]` – legacy share-token route (kept for backwards compatibility).

## Code Organization

- `app/` – App Router routes and metadata definitions.
- `components/` – shadcn-based primitives and feature components.
- `lib/api.ts` – lightweight REST client for the backend proxy.
- `public/` – static assets and Open Graph imagery.

## Helpful Scripts

- `npm run dev` – start the local dev server.
- `npm run lint` – run Next.js/ESLint using the shared config.
- `npm run build` – production build (helpful before deploying to Cloudflare Pages).

## Environment

Create `web/.env.local` with the values listed in `web/.env.example`. At minimum you need:

- `NEXT_PUBLIC_API_BASE_URL`
- `NEXT_PUBLIC_FIREBASE_API_KEY`
- `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
- `NEXT_PUBLIC_FIREBASE_APP_ID`
- `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
- `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
- `NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID`

Firebase credentials power the magic-link reservation flow; without them, visitors cannot verify email addresses.

## Testing & QA

- Keep new component tests alongside their routes under `__tests__/`.
- Snapshot/visual checks can be automated with Playwright when available; otherwise document manual QA.
- Always run `npm run lint` before submitting a PR.
# Trigger build
