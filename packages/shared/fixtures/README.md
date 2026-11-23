# Contract fixtures

One sample JSON document per API request/response shape. They are the bridge between the
TypeScript contract (`../src`, Zod) and the Swift models in `apps/ios`:

- `apps/api/test/contract-fixtures.test.ts` checks every fixture is valid against its Zod schema.
- `apps/ios/CatalogueTests/ContractFixtureTests.swift` decodes the same files into the Swift models.

If you change the contract, update the fixtures; whichever side you forgot will fail its tests.
