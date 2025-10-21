## Agent Brief: Jinnie Web Preview

This agent maintains the stripped-down Next.js app that powers Jinnie’s public web experience. Focus areas:

1. **Routes & Scope**
- `/` – lightweight landing page that points people to the mobile apps.
- `/[username]` – public profile view (read-only).
- `/[username]/[wishlist]` – public wishlist detail with reservation modal.
- `/w/[token]` – legacy share-token route (kept for backwards compatibility).
- `/verify-reservation` – completes Firebase magic-link flows for email confirmation.
   - Avoid reintroducing marketing routes (about, blog, app dashboard) unless product requirements change.

2. **Design System**
   - Use shadcn/ui primitives from `web/components/ui/*`.
   - Tailwind config already matches the mobile brand palette; keep layouts calm, generous, and copy-light.
   - Reuse shared components before adding new ones. If a new primitive is required, follow the existing shadcn pattern.

3. **Reservation Flow**
   - Email is mandatory for reservations until verification is built.
   - Persist the email locally (`localStorage`) for convenience.
  - Send reserver data through `api.reserveWish` `{ name?, email, message? }`; keep hide-from-owner `false`.

4. **Data Access**
   - REST layer lives in `web/lib/api.ts`; prefer extending that client instead of adding fetch calls inside components.
   - Use Next.js App Router conventions: server components for data fetch, client components for interactivity.

5. **Testing & QA**
   - Add Jest/Playwright suites next to routes under `__tests__/` when modifying page behaviour.
   - Run `npm run lint` before handing changes back.
   - For visual adjustments, run the Playwright MCP snapshot workflow if available.

6. **Docs & Naming**
   - Keep docs, TODOs, and helper files in sync with the Jinnie branding (project folder lives at `web/`).
   - Update `AGENTS.md` or other references when adding new capabilities.

When unsure, align behaviour and content with the mobile app’s public sharing experience—the web preview should feel like a lightweight portal into those same wishlists.
