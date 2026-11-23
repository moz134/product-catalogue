# Product Catalogue

A proof of concept for a product catalogue: customers browse and search products, and send an
enquiry about one. The sales inbox receives the enquiry by email.

It's an iOS app (SwiftUI) backed by a Node.js API (TypeScript, Fastify). Product data comes from the
[Fake Store API](https://fakestoreapi.com), and only the backend talks to it. Nothing needs an
account or API key.

## Why this stack

I build iOS apps for a living, so the client is where I can make the most decisions and defend them.
SwiftUI with `@Observable` keeps the screens small and the view models easy to test, and the app has
no third-party dependencies, so Xcode is all a reviewer needs.

For the backend I chose TypeScript so the API contract could be written once, as Zod schemas that
give both types and runtime validation. Fastify adds fast in-process HTTP tests, security and
rate-limit plugins, and structured logs.

## Running it

You need Xcode 16 or later, plus Docker or Node.js 20+.

**1. Start the backend**

```bash
docker compose up --build
```

This starts the API on http://localhost:3000 and [Mailpit](https://mailpit.axllent.org), a local
mail catcher, on http://localhost:8025. Every enquiry email lands in Mailpit; nothing is sent out.

Without Docker:

```bash
npm install
npm run dev
```

Here enquiry emails are printed in the terminal instead. No `.env` file is needed in either case.

**2. Run the app**

Open `apps/ios/Catalogue.xcodeproj`, pick an iPhone simulator and press ⌘R. The simulator reaches
the backend on `localhost` without any setup.

To run on a real iPhone, set your signing team and bundle ID, then in the scheme's Run environment
enable `CATALOGUE_API_BASE_URL` and point it at your Mac, e.g. `http://192.168.1.10:3000/api/v1`.

## What to try

- **Home** shows the five products listed in `FEATURED_PRODUCT_IDS` (default `1,5,9,13,18`).
- **Categories:** tap one under the search bar. Top-rated products come first, then the rest.
- **Search:** type `ssd` and tap Search. Only matching products are shown.
- **Product:** tap any tile for the details.
- **Enquiry:** on a product, tap Enquire, fill in the form and send. You'll see a thank-you screen,
  and the email appears in Mailpit (or the backend's terminal).

## Tests

Run these in a second terminal, with the backend still running in the first. The backend tests need
Node.js 20+ even if you started the backend with Docker:

```bash
npm install
npm run check
```

That's lint, type checks and the backend tests. For the app, press ⌘U in Xcode, or run this, which
picks whichever iPhone simulator you have installed:

```bash
./scripts/test-ios.sh
```

The UI tests run against built-in sample data, so they don't need the backend. One extra UI test
sends a real enquiry through the running backend; it's off by default:

```bash
TEST_RUNNER_CATALOGUE_E2E=1 ./scripts/test-ios.sh -only-testing:CatalogueUITests/RealBackendUITests
```

There are two more ways to exercise the running backend:

- `./scripts/smoke-test.sh` checks the Docker stack end to end, including the email reaching Mailpit.
  It uses `jq`, which ships with macOS 15 and later (`brew install jq` on older versions).
- `docs/catalogue.postman_collection.json` covers every endpoint with assertions. Import it into
  Postman, or run `npx newman run docs/catalogue.postman_collection.json`.

Enquiries are rate limited. The Docker setup allows 30 a minute so these commands can run back to
back; with `npm run dev` the limit is 5 a minute.

CI runs the backend checks, the Docker smoke test and the iOS tests on every pull request.

## How it's organised

```
apps/ios          SwiftUI app
apps/api          Fastify API
packages/shared   API contract (Zod schemas) and JSON fixtures shared by both test suites
scripts           Docker smoke test
docs              Design plan, pull request notes, Postman collection
```

The brief says the data source, the look and feel, and the email provider will all change, so each
sits behind its own seam:

| What changes          | Seam                                    | Today                             |
| --------------------- | --------------------------------------- | --------------------------------- |
| Product data          | `ProductSource` in `apps/api/src/ports` | Fake Store, with a 5-minute cache |
| Email                 | `EmailSender` in `apps/api/src/ports`   | SMTP (Mailpit locally)            |
| Look and feel         | `apps/ios/Catalogue/Theme/Theme.swift`  | Neutral placeholder theme         |
| Backend, from the app | `CatalogueAPI` protocol                 | `HTTPCatalogueAPI`                |

Concrete implementations are chosen in one place on each side: `apps/api/src/container.ts` and
`apps/ios/Catalogue/App/AppDependencies.swift`.

### API

All endpoints are under `/api/v1`. Errors always look like
`{ "error": { "code", "message", "fields" } }`, where `fields` is only present for validation errors.

| Method | Path                         | Returns                                  |
| ------ | ---------------------------- | ---------------------------------------- |
| GET    | `/products/featured`         | The five top-rated products              |
| GET    | `/products?search=term`      | Products matching the term               |
| GET    | `/products/:id`              | One product                              |
| GET    | `/categories`                | All categories                           |
| GET    | `/categories/:slug/products` | `{ category, topRated, others }`         |
| POST   | `/enquiries`                 | `202` with `{ reference }`               |
| GET    | `/health`                    | `{ status: "ok" }` (no `/api/v1` prefix) |

## Configuration

The backend reads environment variables, all optional, documented in `.env.example`. They're
validated at startup, so a bad value stops the server with a clear message. The app's backend URL
lives in `apps/ios/Config/Info.plist` and can be overridden with `CATALOGUE_API_BASE_URL`.

## Troubleshooting

**"We couldn't reach the server."** The backend isn't running on port 3000, or, on a real device,
`CATALOGUE_API_BASE_URL` doesn't point at your Mac.

**Behind a corporate HTTPS-inspection proxy (e.g. Zscaler).** The proxy re-signs some connections
with its own certificate, which the simulator and Docker containers don't trust. You'll see missing
product images in the simulator, or `502` responses from the Docker API with
`unable to get local issuer certificate` in its log. Export the proxy's root certificate from your
Mac:

```bash
mkdir -p .local-certs && security find-certificate -a -c "Zscaler" -p /Library/Keychains/System.keychain > .local-certs/corporate-ca.pem
```

Trust it in the booted simulator, then relaunch the app (`xcrun simctl keychain booted reset`
undoes this):

```bash
xcrun simctl keychain booted add-root-cert .local-certs/corporate-ca.pem
```

For Docker, create `docker-compose.override.yml` (Compose picks it up automatically), then run
`docker compose up -d`:

```yaml
services:
  api:
    volumes:
      - ./.local-certs/corporate-ca.pem:/etc/ssl/certs/corporate-ca.pem:ro
    environment:
      NODE_EXTRA_CA_CERTS: /etc/ssl/certs/corporate-ca.pem
```

Both files are git-ignored.

## Further reading

- [DECISIONS.md](DECISIONS.md): assumptions, trade-offs, what I cut and what comes next
- [AI_USAGE.md](AI_USAGE.md): how I used AI tools and checked their output
- [CLAUDE.md](CLAUDE.md): the instructions the coding agent worked from
- [docs/PLAN.md](docs/PLAN.md): the design plan written before any code
