<!-- Paste everything below the line into the pull request description. -->

---

## What this is

A proof of concept for the product catalogue: a SwiftUI iOS app backed by a Node.js API. Customers
browse, search and send an enquiry, and the sales inbox receives it by email. Only the API talks to
the Fake Store API.

The data source, the email provider and the look and feel are each behind their own interface, so
replacing one means adding an implementation, not rewriting screens or services.

## Running it

```bash
docker compose up --build          # API on :3000, sales inbox (Mailpit) on http://localhost:8025
open apps/ios/Catalogue.xcodeproj  # then ⌘R on an iPhone simulator
```

Without Docker, `npm install && npm run dev` starts the API and prints emails in the terminal. The
README has the details.

## Acceptance criteria

| Criterion                                    | Where to see it                         |
| -------------------------------------------- | --------------------------------------- |
| Home shows the 5 chosen products             | Launch the app (`FEATURED_PRODUCT_IDS`) |
| Category shows top rated, then the rest      | Tap a category                          |
| Search shows only matches                    | Type `ssd`, tap Search                  |
| Tile opens the product page                  | Tap any product                         |
| Enquiry emails sales and thanks the customer | Enquire, fill in, Send; check Mailpit   |

## Where to start reviewing

1. `DECISIONS.md`: assumptions, cuts and how this grows.
2. The seams: `apps/api/src/ports`, `apps/api/src/container.ts`, and the app's `CatalogueAPI` and
   `AppDependencies`.
3. `packages/shared`: the contract and the fixtures both test suites check.
4. One flow end to end, the enquiry: `EnquiryFormView` → `EnquiryViewModel` → `POST /api/v1/enquiries`
   → `EnquiryService` → `EmailSender`.

## Tests

- 62 backend tests (`npm run check`).
- 41 iOS unit tests and 4 UI tests (⌘U or `./scripts/test-ios.sh`), plus an opt-in end-to-end test
  against the real API.
- A Postman collection covering every endpoint (`docs/`).
- A Docker smoke test that confirms the email arrives (`scripts/smoke-test.sh`).

CI runs the backend checks, the smoke test and the iOS tests.

## Known limitations

- Enquiries aren't stored. If sending fails, the customer can retry, but nothing is queued; that's the
  first thing I'd add.
- Search and filtering run in memory, which is fine for 20 products.
- Product images load directly from the URLs in the data.

How I used AI, and the time I spent (about 4 hours), are in `AI_USAGE.md`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
