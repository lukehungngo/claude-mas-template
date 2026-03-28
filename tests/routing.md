# MAS Routing Tests — Tier 2

## Purpose

Verify the routing table in dev-loop Step 6 correctly classifies tasks. Each test case has an input scenario and expected routing decision. Run by dispatching a lightweight agent that applies the routing table without implementing anything.

## How to Run

For each test case, dispatch a quick agent:

```
Agent(
  subagent_type: "Explore",
  prompt: """
  You are testing the MAS routing table. Given this task description,
  apply the routing table and return ONLY:
  1. routing: "novel" or "known" or "bug-fix" or "ui" or "refactor"
  2. First agent to dispatch
  3. One-line justification

  Routing Table:
  | Task Type | Route |
  |-----------|-------|
  | Novel approach needed | Researcher → Differential Reviewer → Engineer |
  | Known pattern exists | Engineer directly |
  | Bug fix from review | Bug-Fixer |
  | UI component (has_ui: true) | UI/UX Designer → Engineer |
  | Refactor / cleanup | Engineer directly |

  Novel task criteria (if ANY, route to Researcher):
  1. No existing implementation of this pattern in codebase
  2. Algorithm/approach not yet used in this project
  3. New system boundary
  4. Competing approaches with non-obvious trade-offs
  5. Similar task failed in a prior session

  Task: {test case input}
  """
)
```

## Test Cases

### Known Pattern → Engineer

| # | Input | Expected | Justification |
|---|-------|----------|---------------|
| K1 | "Add a new REST endpoint for /api/users following existing endpoint patterns" | known → Engineer | Pattern exists in codebase |
| K2 | "Add input validation to the signup form" | known → Engineer | Standard validation pattern |
| K3 | "Add a new test for the calculateTotal function" | known → Engineer | Test writing is known pattern |
| K4 | "Update the error message in the login handler" | known → Engineer | Simple text change |

### Novel → Researcher First

| # | Input | Expected | Justification |
|---|-------|----------|---------------|
| N1 | "Implement real-time collaboration using CRDTs" | novel → Researcher | CRDT is a non-trivial algorithm, likely new to codebase |
| N2 | "Add a code analysis tool that detects security vulnerabilities using AST parsing" | novel → Researcher | Novel approach, competing implementations |
| N3 | "Migrate from REST to GraphQL" | novel → Researcher | System boundary change, competing approaches |
| N4 | "Implement a custom caching layer with LRU eviction and TTL" | novel → Researcher | Algorithm choice, trade-offs |
| N5 | "Build a plugin system that allows third-party extensions" | novel → Researcher | Architecture decision, multiple approaches |

### Bug Fix → Bug-Fixer

| # | Input | Expected | Justification |
|---|-------|----------|---------------|
| B1 | "Fix: login fails when email has uppercase letters" | bug-fix → Bug-Fixer | Clear bug with reproduction |
| B2 | "The API returns 500 instead of 404 when resource not found" | bug-fix → Bug-Fixer | Incorrect error handling |
| B3 | "Memory leak in WebSocket connection handler" | bug-fix → Bug-Fixer | Performance bug |

### Refactor → Engineer

| # | Input | Expected | Justification |
|---|-------|----------|---------------|
| R1 | "Extract the validation logic into a shared utility module" | refactor → Engineer | Code reorganization |
| R2 | "Rename all instances of 'userId' to 'accountId'" | refactor → Engineer | Renaming cleanup |
| R3 | "Split the 500-line UserService into smaller modules" | refactor → Engineer | Decomposition |

### UI → Designer First (has_ui: true)

| # | Input | Expected | Justification |
|---|-------|----------|---------------|
| U1 | "Design and build a user profile settings page" | ui → UI/UX Designer | New UI component |
| U2 | "Add a dark mode toggle to the navigation bar" | ui → UI/UX Designer | UI interaction change |
| U3 | "Redesign the dashboard layout to show 3 columns on desktop" | ui → UI/UX Designer | Layout redesign |

### Edge Cases (tricky routing)

| # | Input | Expected | Justification |
|---|-------|----------|---------------|
| E1 | "Add WebSocket support for real-time notifications" | novel → Researcher | New system boundary (WebSocket), even though the feature is common |
| E2 | "Fix the CSS alignment on the settings page" | bug-fix → Bug-Fixer | UI bug, NOT a design task — it's a fix |
| E3 | "Add internationalization support (i18n)" | novel → Researcher | System-wide change, competing libraries (i18next, react-intl, etc.) |
| E4 | "Update React from 18 to 19" | novel → Researcher | Similar tasks historically break things, competing migration strategies |
| E5 | "Add a loading spinner to the submit button" | known → Engineer | Simple UI enhancement (has_ui: true could route to designer, but this is too small) |

## Scoring

Run all test cases. For each:
- **CORRECT**: routing matches expected
- **ACCEPTABLE**: routing is defensible even if different from expected (e.g., E5 going to Designer instead of Engineer)
- **WRONG**: routing is clearly incorrect (e.g., bug fix routed to Researcher)

**Pass threshold:** ≥ 80% CORRECT + ACCEPTABLE across all test cases.

## Results Log

| Run Date | Total | Correct | Acceptable | Wrong | Score | Pass? |
|----------|-------|---------|------------|-------|-------|-------|
|          |       |         |            |       |       |       |

## How to Add Test Cases

When a routing failure occurs in a real session:
1. Add the input as a new test case in the appropriate category
2. Document the expected routing and justification
3. If the routing table itself was wrong (not just the model's classification), update the routing table in dev-loop.md Step 6
