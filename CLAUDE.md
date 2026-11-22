# Agent instructions

An iOS app (`apps/ios`, SwiftUI), a Fastify API (`apps/api`, TypeScript) and their shared contract
(`packages/shared`). Read `README.md` and `DECISIONS.md` first.

## Rules

**Contract**

- Only the API talks to Fake Store or any other data source.
- Change the contract in `packages/shared/src` first, then update `packages/shared/fixtures`, then the
  Swift models. Both test suites check the fixtures.

**API**

- Requests flow `routes → services → ports ← adapters`. Services never import Fastify; routes never
  import adapters. Only `src/container.ts` chooses adapters.
- Upstream formats stay inside their adapter.
- Services throw domain errors. Only `http/error-handler.ts` turns them into responses, always in the
  shared error shape, and never with stack traces or upstream messages.
- Configuration comes from environment variables validated in `src/config.ts`. Document new ones in
  `.env.example`.

**iOS**

- Views and view models depend on the `CatalogueAPI` protocol. Only `HTTPCatalogueAPI` knows URLs and
  JSON, and only `App/AppDependencies.swift` picks the implementation.
- View models are `@MainActor @Observable` and expose `LoadState`; screens render it with
  `LoadableView`. Show `APIError.userMessage`, never a raw error.
- Navigate through `Route`. Style only through `Theme`.
- Add no third-party dependency without recording the decision in `DECISIONS.md`.
- Give anything a UI test touches an accessibility identifier.

**General**

- Validate all external input. Never log customer details or commit secrets.
- Test through public interfaces: `InMemoryProductSource` and fake email senders in the API;
  `FakeCatalogueAPI`, `StubURLProtocol` and `-UITestStubAPI` in the app.
- Comment only to explain why, not what.

## Before calling a change done

```bash
npm run check
./scripts/test-ios.sh
```

For UI changes, run the app against the local API and look at it. If a new test passes first time,
break the code briefly to make sure it can fail.
