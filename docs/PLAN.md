# Design plan

Written and approved before building, then used as the brief for the coding agent.

## Goal

A product catalogue the entrepreneur can try straight away, built so it can keep growing. The brief
says the product data source, the look and feel, and the email provider will all change, so each
gets an interface with one working implementation today. Stay inside the time-box: the right seams,
not extra features.

## Stack

| Layer          | Choice                                | Reason                                                       |
| -------------- | ------------------------------------- | ------------------------------------------------------------ |
| Client         | iOS, SwiftUI, iOS 17+                 | My platform; `@Observable` view models are easy to test      |
| Backend        | Node.js, TypeScript, Fastify          | Typed contract, fast in-process HTTP tests, security plugins |
| Contract       | Zod schemas in `packages/shared`      | Types plus runtime validation, written once                  |
| Email          | Nodemailer over SMTP, Mailpit locally | Real email a reviewer can see, with no account               |
| Infrastructure | Docker Compose                        | One command to run; the image fits ECS Fargate later         |

Everything is free; nobody needs to sign up for anything.

## Structure

```
apps/api/src
  ports/      ProductSource, FeaturedSelector, EmailSender
  adapters/   Fake Store, in-memory, cache, SMTP, console, configured picks
  services/   CatalogueService, EnquiryService, search
  http/       routes, validation, one error handler
  container   chooses the adapters from config
apps/ios/Catalogue
  API/        CatalogueAPI protocol, HTTP client, offline stub
  Features/   Home, Category, Search, Product, Enquiry (view + view model each)
  Navigation/ Route enum, one NavigationStack
  Theme/      design tokens
packages/shared  schemas and JSON fixtures
```

## API

`/api/v1`: featured products, categories, a category page (top rated plus the rest), search, product
details, and `POST /enquiries`. Every error uses one shape: `{ error: { code, message, fields } }`.

## Key rules

- Only the backend talks to Fake Store. Its payload is validated and mapped to our own `Product` type
  inside the adapter.
- "Top rated" means the owner's chosen product IDs from config, topped up by rating. The same rule
  applies within each category.
- Search matches title, description and category, and runs on the Search button only.
- An enquiry is validated, the product is checked, and an email goes to the sales inbox with the
  customer as Reply-To. The app then shows a thank-you screen with a reference.
- Security basics: validation with limits, HTML-escaped email, security headers, a rate limit on
  enquiries, no internals in error responses, no secrets in the repo.

## Tests

- **Backend:** adapters, services and every endpoint through Fastify's `inject()`, including the error
  paths.
- **iOS:** the HTTP client (with a stubbed `URLProtocol`), each view model (with a fake API), and
  validation.
- **UI:** one test per acceptance flow against the offline stub.
- **Contract:** the shared fixtures are checked by both suites.
- **Docker:** a smoke test that confirms the email reaches Mailpit.

## Build order

1. Contract and backend skeleton, then adapters, services, routes and tests.
2. Email through Mailpit, then Docker Compose.
3. Xcode project, models and HTTP client, then screens and view models, then the enquiry flow and UI
   tests.
4. README, DECISIONS, AI usage notes and CI.
