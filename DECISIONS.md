# Decisions

## Stack

- **iOS app in SwiftUI, iOS 17+.** iOS is my platform. `@Observable` view models are small and easy
  to unit test, and with no third-party packages there is nothing to resolve or audit.
- **Node.js API in TypeScript (Fastify).** The contract is written once as Zod schemas, which give
  compile-time types and runtime validation. Fastify's `inject()` makes HTTP tests fast, with no port
  to open.
- **One repository with npm workspaces.** A single install and CI pipeline. Nx or Turborepo would be
  overkill at this size.

## Design

The brief names three things that will change: the product data source, the look and feel, and the
email provider. Each is behind an interface, and one file per side picks the implementation
(`apps/api/src/container.ts` and `apps/ios/Catalogue/App/AppDependencies.swift`).

**Backend.** Requests flow `route → service → port ← adapter`.

- Services depend on `ProductSource`, `FeaturedSelector` and `EmailSender`, never on Fake Store or
  SMTP directly.
- `FakeStoreProductSource` validates Fake Store's payload and maps it to our own `Product` type, so
  that format never leaks further.
- Caching wraps any source (`CachedProductSource`). Tests use `InMemoryProductSource`, which also
  shows the source really can be swapped.
- Services throw domain errors. One error handler turns them into HTTP responses with a single error
  shape, and never returns stack traces or upstream messages.

**App.** MVVM.

- Views and view models depend only on the `CatalogueAPI` protocol. `HTTPCatalogueAPI` is the only
  type that knows URLs and JSON.
- Every screen uses the same `LoadState`, so loading, error with retry, and empty states behave
  consistently.
- Navigation goes through a `Route` value. Colours, fonts and spacing come only from `Theme`.

**Contract.** Swift can't import the Zod schemas, so the Swift models mirror them. To stop the two
drifting apart, `packages/shared/fixtures` holds one JSON sample per request and response. The API
tests validate each sample against its schema, and fail if any field would be dropped; the iOS tests
decode the same files.

## Assumptions

The acceptance criteria leave these open, so I chose the following.

**Top-rated products**

- "I have chosen 5 products" means the owner lists product IDs in config (`FEATURED_PRODUCT_IDS`, in
  display order). If fewer than five are valid, the list is topped up with the highest-rated products,
  so the home screen never has a gap.
- A category page applies the same rule within the category, up to three products. "Additional
  products" are the rest of that category.
- Categories come from the data source, in its order; the owner doesn't curate them.

**Search**

- A case- and accent-insensitive substring match on title, description and category name, with title
  matches listed first.
- It runs when the Search button (or the keyboard's Search key) is pressed, not on every keystroke.
  Blank terms are ignored, and terms are capped at 100 characters.
- The search bar is on the home screen only.

**Enquiries**

- Name and email are required. Phone and message are optional. Each field has a length limit.
- The form opens as a sheet over the product and turns into the thank-you screen, showing a
  reference number.
- There's one sales inbox (`SALES_INBOX_EMAIL`). The customer's address is the Reply-To, so sales can
  simply reply. The customer doesn't get an email; the brief doesn't ask for one, and sending mail to
  addresses typed into a form invites abuse.
- Locally, "the sales inbox" is Mailpit (or the terminal without Docker).

**Data and platform**

- Fake Store gives no currency, so prices are treated as USD (configurable).
- Product data can be up to five minutes old because of the cache. Changing the top-rated picks means
  restarting the backend.
- The app loads product images straight from the URLs in the data. The rule about going through the
  backend is about product data, which it does.
- iPhone and iPad, portrait and landscape. English only; prices are formatted for the device's region.
- "A proof of concept they can interact with" means running it from Xcode in the simulator, not a
  TestFlight build. Reviewers need Xcode 16 or later.

## What I cut or simplified

- **No database.** Enquiries aren't stored; the email is the record. If sending fails, the customer
  sees an error and can retry, but nothing is queued. This is the first thing I'd fix.
- **No pagination.** Fake Store has 20 products. Lists are wrapped in `{ items }` so paging fields can
  be added without breaking the app.
- **Search and filtering run in memory**, because Fake Store has no search endpoint. A real catalogue
  would do this in the database.
- **The cache lives in each server process.** That's fine for one instance; several would need Redis.
- **Spam protection is a rate limit only:** five enquiries a minute per IP by default. The local
  Docker setup raises it to 30 so the test commands can run back to back. App Attest or a CAPTCHA
  would need accounts the brief rules out.
- **Validation runs twice.** The app repeats the server's rules, with the same messages, for instant
  feedback. The server stays the authority, and its field errors are shown on the form.
- **Swift models are written by hand.** The shared fixtures catch drift; code generation can come later.
- **No login, admin screens, cart, offline mode or localisation.**
- **Placeholder design.** The creative work isn't done yet, so the UI is plain system styling with
  Dark Mode and Dynamic Type working.
- **Nothing is deployed.** The API is a stateless container with a health check, which maps onto ECS
  Fargate behind a load balancer, and SMTP maps onto SES. The bundle ID is a placeholder
  (`com.example.catalogue`).

## Security basics

- Every request body, path parameter and query is validated with length limits; bodies are capped at
  16 KB.
- Customer input is HTML-escaped in the email, and line breaks are stripped from the subject to
  prevent header injection.
- Security headers come from `@fastify/helmet`. Error responses never include internals.
- The only write endpoint is rate limited. Logs record the enquiry reference and product ID, not the
  customer's details.
- The app allows plain HTTP to local addresses only (`NSAllowsLocalNetworking`), with no blanket App
  Transport Security exception.
- No secrets are committed, configuration is validated at startup, and the API container runs as a
  non-root user.

## Growing beyond the PoC

| Change                        | What it takes                                                                                                                           |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Real product database or CMS  | A new `ProductSource` adapter, selected in `container.ts`. Services, routes and the app stay as they are.                               |
| Another email provider        | A new `EmailSender` (or point SMTP at SES) and a config value.                                                                          |
| The real visual design        | New values in `Theme.swift`.                                                                                                            |
| Owner-managed top-rated picks | A `FeaturedSelector` backed by an admin screen or CMS.                                                                                  |
| More traffic                  | More API containers (the API is stateless), a shared cache, search in the database, and a CDN (responses already send `Cache-Control`). |
| Android or web clients        | The same versioned `/api/v1` contract and fixtures.                                                                                     |

When the catalogue outgrows loading everything, `ProductSource` will gain query methods (paging,
search) implemented by the database. That changes one interface; the rest of the code is unaffected.

## With another day

1. Save enquiries before emailing, and send email from a queue with retries, so an outage never loses
   a lead.
2. Infrastructure as code for AWS (CDK or Terraform): ECS Fargate, a load balancer and SES.
3. Generate the Swift models from an OpenAPI spec the API produces.
4. Pagination and sorting, with search pushed down into the data source.
5. Snapshot tests for the main screens, and an image cache.
6. A scheduled check that the live Fake Store API still matches the adapter's schema.
7. Request metrics, tracing, and alerts on upstream and email failures.
