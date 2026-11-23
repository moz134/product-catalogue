# AI usage

## Tools

I used Claude Code (Claude desktop app) with Claude Opus 5.5 for planning, writing code, running the
tests, driving the iOS Simulator and reading its logs. I used no other AI tools.

The agent worked from [CLAUDE.md](CLAUDE.md), which sets the architecture rules, the conventions and
the checks to run before calling anything done. The design plan I approved before any code was
written is in [docs/PLAN.md](docs/PLAN.md).

## Key prompts

These are my own prompts, lightly corrected for spelling, with what each one changed.

1. **"Write the plan first for the design only. What tools do I need? I don't want to use any paid
   tools."**

2. **"Is the Fake Store API called directly, or through the backend? What services were created?"**

4. **A fresh-clone check before submitting:**

   > I want to verify the reviewer experience before I submit. Clone the repository from the bundle
   > into a fresh temporary folder, as if you had never seen it. Follow README.md exactly as written,
   > step by step, without using anything you know from this session. Start the backend with Docker,
   > build and run the iOS app in the simulator, and run every test command in the README.
   > Time the whole process. The brief says it must take under 10 minutes.
   > For every step, report: the exact command, whether it worked first time, how long it took.
   > Don't change any files. Give me a list of problems ranked by how likely they are to block a
   > reviewer, and suggest a fix for each. I'll decide which to make.

5. **"You've listed key prompts in AI_USAGE.md that I never wrote."**

   The first draft of this file presented things the agent did on its own as my prompts. I caught it
   and had the section rewritten with my actual prompts. The agent's own checks are listed separately
   below.

## How the agent checked its own output

- Before writing tests, it called the live Fake Store API. That showed an unknown product ID returns
  `200` with an empty body rather than `404`; the adapter handles it, and a test covers it.
- When a suite passed first time, it broke the code on purpose (search case-folding in the API, email
  validation in the app), confirmed the tests failed, then restored it.
- It walked every acceptance criterion through the simulator, ran the Postman collection with Newman,
  and wrote an opt-in UI test that sends a real enquiry from the app to the running backend.

## Where the AI got it wrong

| Mistake                                                                                                               | How it was caught                         | Fix                                                                            |
| --------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- | ------------------------------------------------------------------------------ |
| Passed a logger to Fastify 5 the Fastify 4 way; the server crashed at startup                                         | Running the API against the real upstream | `loggerInstance`                                                               |
| Started on Zod 3, which has a high-severity advisory                                                                  | `npm audit`                               | Zod 4                                                                          |
| Named the Swift model `Category`, which clashes with an Objective-C runtime type                                      | Compiler error                            | Renamed to `ProductCategory`                                                   |
| A loading helper took an `@Observable` property `inout` across an `await`, which would have delayed the loading state | Review before compiling                   | The helper returns the new state instead                                       |
| Assumed Swift infers typed `throws` for closures                                                                      | Compiler error                            | The helper takes a plain throwing closure                                      |
| A test named "keeps showing data if a refresh fails" asserted the opposite                                            | Re-reading the tests                      | Renamed to match the behaviour                                                 |
| Explained the missing images as "the simulator doesn't trust the proxy"                                               | My Safari test in the simulator           | Logs and the simulator trust store showed per-app inspection; README corrected |
| Too many comments that restated the code or repeated the docs                                                         | My review                                 | Removed about 160 lines, keeping only those that explain why                   |
| Presented its own actions as my key prompts in this file                                                              | I noticed I hadn't written two of them    | Rewritten with my real prompts; the agent's checks listed separately           |

Several dependencies (Fastify 5, Vitest 5, Nodemailer 10) were newer than the model knew well, so the
agent read their installed type definitions before using them rather than guessing.

## My own review

- I ran the app and the Docker stack myself, and debugged the missing images (prompt 3).
- I checked a hard requirement of the brief myself, rather than trusting it was met (prompt 2).
- I had a fresh-clone check done from a reviewer's point of view, and chose which of its findings to
  fix (prompt 4).
- I read through the generated code and documents, and cut comments and wording that didn't help a
  reviewer.

## Verification

Verified locally:

- All backend and iOS tests.
- The opt-in end-to-end UI test against the real backend.
- The Postman collection, run with Newman.
- `docker compose up` with the smoke test, including the email reaching Mailpit.
- A fresh clone followed step by step from the README, timed (prompt 4).

On this machine the backend can only reach Fake Store with the corporate proxy certificate installed
locally; that file is git-ignored and not needed on a normal network. The iOS job in CI hasn't run on
GitHub's macOS runners yet, which may have an older Xcode. The project needs Xcode 16 or later.

## Time spent

About 4 hours of active work, over the 2–3 hour time-box. Roughly 25 minutes went on corporate-proxy
problems unrelated to the code, and about 35 minutes on the final fresh-clone check and the fixes it
led to. The figures come from file and commit timestamps and exclude breaks.

| Activity  | Time    |
| --------- | ------- |
| Planning  | ~30 min |
| Building  | ~65 min |
| Testing   | ~85 min |
| Reviewing | ~60 min |
