# Language-Specific Hardening Proposal — Python + TypeScript

**Date:** 2026-04-12  
**Status:** Proposal (pre-implementation)  
**Scope:** Seamless language-aware enhancement of engineer + reviewer agents for Python and TypeScript

---

## Problem Statement

The MAS engineer and reviewer are language-agnostic. They apply good general practices but miss:

- Python: bare `except:`, mutable defaults, f-string SQL injection, N+1 queries, missing context managers
- TypeScript: `any` type abuse, unhandled promise rejections, `==` vs `===`, `async/forEach` anti-pattern, missing dependency arrays

When the controller dispatches `mas:reviewer:reviewer` on a TypeScript project, it gets the same review behavior as on a Python project. No lint commands, no language-specific anti-pattern checks, no type system verification.

Real cost: In the eduquest session audit, **zero reviewer dispatches ran `tsc --noEmit` or `eslint`** as part of their review — TypeScript type errors were caught incidentally if at all.

---

## What We Learned from ECC + GSD

### ECC's Approach: Vertical Specialization

Separate `python-reviewer` and `typescript-reviewer` agents. Each has deep expertise in one language, embeds mandatory diagnostic commands, and defers to language-specific skills (`python-patterns`, `coding-standards`).

**Strength:** Deep expertise, clear boundaries, no cross-language noise.  
**Weakness:** Manual dispatch (user must know to pick the right agent). Doesn't integrate with MAS's flat dispatch model.

### GSD's Approach: Horizontal Integration

Single reviewer agent auto-detects language from file extensions at runtime. Groups findings by language in one unified report.

**Strength:** Transparent to user, handles multi-language projects, no extra dispatch step.  
**Weakness:** Language context embedded in agent (large), patterns less deep than ECC's specialized agents.

### What MAS Should Do: Bootstrap-Injected Context

Neither vertical separation nor embedded detection. Instead:

1. **Bootstrap detects the stack once** and writes a `rules/language-stack.md` with language-specific rules, anti-patterns, and diagnostic commands.
2. **Engineer and reviewer agents read that file** via the existing rules loading they already do — no prompt changes needed, no new agents.
3. **Hook enforces language diagnostics** — reviewer blocked from approving unless it ran the language's type-check + lint commands.

This is the MAS pattern applied to language: **structural enforcement, not prose guidance**.

---

## Proposed Architecture

```
bootstrap (detect once)
    ↓ writes
rules/language-stack.md
    ↓ read by
engineer/CLAUDE.md   ← already reads rules/
reviewer/CLAUDE.md   ← already reads rules/
    ↓ enforced by
validate-dispatch.sh ← new: block reviewer approval if type-check not run
```

No new agents. No changes to how `dev-loop` dispatches. Seamless.

---

## Component Design

### 1. Bootstrap Language Detection (enhanced)

`bootstrap.md` already detects stack for `{{test-command}}` etc. Extend it to also write `rules/language-stack.md`.

**Detection signals:**
- `package.json` + `tsconfig.json` → TypeScript
- `package.json` (no tsconfig) → JavaScript
- `pyproject.toml` / `requirements.txt` / `setup.py` → Python
- `go.mod` → Go (future)
- Combination (e.g., FastAPI backend + Next.js frontend) → multi-stack

**Output: `rules/language-stack.md`**

```markdown
# Language Stack

## Detected Stack
- **Primary:** TypeScript (Node.js / Fastify)
- **Framework:** Fastify + Drizzle ORM + Zod

## Engineer Rules

### Mandatory Before Committing
- Run: `tsc --noEmit` — must pass
- Run: `eslint src/ --ext .ts` — must pass
- Run: `prettier --check src/` — or auto-fix with `prettier --write`

### TypeScript Non-Negotiables
- No `any` type without explicit justification comment
- All async functions must have error handling (try/catch or .catch())
- All `Promise.all()` vs sequential await — must prefer parallel where independent
- Input validation at API boundaries using Zod schemas

### Anti-Patterns — Auto-Block During Self-Review
- `as any` — flag as P1 in self-review
- `!` non-null assertion without null check — flag as P1
- `==` instead of `===` — flag as P2
- `async` function inside `.forEach()` — flag as P1 (fire-and-forget)
- `useEffect` with missing dependency array — flag as P1

## Reviewer Rules

### Mandatory Diagnostic Commands (Phase B Step 1)
```bash
tsc --noEmit                          # Zero type errors required
eslint src/ --ext .ts --max-warnings 0  # Zero lint warnings required  
{{test-command}}                       # All tests must pass
```

### Language-Specific P0/P1 Checks
**P0 (always block):**
- `eval()` or `new Function()` with user input
- `innerHTML` with unsanitized content
- SQL string concatenation (not parameterized)
- Hardcoded credentials in source

**P1 (must fix):**
- `any` type without justification
- Unhandled promise rejection (floating promise, missing .catch())
- `async/forEach` anti-pattern
- Missing `await` on async call in critical path
- API endpoint accepts unvalidated user input

**P2 (should fix):**
- `==` instead of `===`
- `!` non-null assertion without guard
- Sequential awaits that could be `Promise.all`
- Missing return type annotation on exported functions

### Framework-Specific (Fastify)
- Route handler missing schema validation → P1
- Plugin not decorated on server instance → P1
- Missing error handler plugin → P2
```

Python version would follow the same structure with `mypy`, `ruff`, `pytest` and Python-specific anti-patterns.

---

### 2. Engineer Agent Enhancement (minimal)

Add one instruction to **Phase 4 — Pre-completion** in `agents/engineer/CLAUDE.md`:

```markdown
- [ ] **Language diagnostics:** Run the commands in `rules/language-stack.md` under "Mandatory Before Committing". All must pass before writing the result.
```

That's it. The language-specific commands live in `rules/language-stack.md`, not in the agent. When the stack changes, only one file updates.

**For the deviation taxonomy (already shipped in v2.9.0):** Language-specific anti-patterns from `rules/language-stack.md` extend Rule 1 and Rule 2 automatically — the engineer reads the rules file and knows what to auto-fix vs flag.

---

### 3. Reviewer Agent Enhancement (minimal)

Add one instruction to **Phase B Step 1** in `agents/reviewer/CLAUDE.md`:

```markdown
**Language diagnostics:** Read `rules/language-stack.md`. Run ALL commands listed under "Mandatory Diagnostic Commands". A review cannot be APPROVED if any diagnostic command fails — this is a P0 regardless of other findings.
```

And extend the anti-pattern check:

```markdown
**Language-specific P0/P1 checks:** After running diagnostics, apply the language-specific anti-pattern checks from `rules/language-stack.md` under "Language-Specific P0/P1 Checks".
```

Again — no anti-patterns embedded in the agent. They live in the rules file.

---

### 4. Hook Enforcement (optional but recommended)

Extend `validate-dispatch.sh` with a new check:

```bash
# Block reviewer APPROVED verdict if rules/language-stack.md exists but no diagnostic evidence
# (Read prompt, check if it mentions tsc/mypy/eslint output — if not, warn)
```

This is softer enforcement than the depth/model check — a warning (exit 0 with message) rather than a block. The diagnostic commands themselves will fail and block the reviewer from issuing APPROVED.

---

### 5. Superpowers Integration

When using `superpowers:subagent-driven-development` with MAS agents:

```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  model: "sonnet",
  prompt: "depth: standard\n\nReview TASK-006 — rate limiting middleware"
)
```

The reviewer reads `rules/language-stack.md` as part of its normal rules loading. Language hardening applies automatically. No change to the dispatch call.

---

## What This Does NOT Do (Intentionally)

| Excluded | Why |
|----------|-----|
| New `python-reviewer` / `typescript-reviewer` agents | Adds complexity, breaks flat dispatch, requires controller to know language |
| Embedding anti-patterns in agent CLAUDE.md | Makes agents large and hard to update; stack-specific rules belong in project rules |
| Language detection at runtime in reviewer | Fragile (file extension inference), not needed when bootstrap already knows the stack |
| Go / Rust / Swift support in this proposal | Ship Python + TypeScript first. Same pattern extends to other languages. |

---

## Comparison: MAS Approach vs Alternatives

| | ECC (vertical) | GSD (horizontal) | **MAS (rules-injected)** |
|---|---|---|---|
| New agents per language | Yes (separate agents) | No | **No** |
| Auto-applies to existing workflow | No (manual dispatch) | Yes | **Yes** |
| Anti-patterns location | Agent CLAUDE.md | Agent CLAUDE.md | **`rules/language-stack.md`** |
| Project-customizable | Via skills override | Via CLAUDE.md | **Edit one rules file** |
| Bootstrap writes rules | No | No | **Yes** |
| Hook enforcement | No | No | **Yes (diagnostic must pass)** |
| Multi-language project | Run 2 agents | One agent auto-detects | **One rules file, multi-stack section** |

The MAS approach is the only one where language context is written by bootstrap (knows your stack), lives in a project-owned rules file (customizable), and is enforced structurally (hook blocks approval if diagnostics didn't run).

---

## Migration Path for Existing Projects

Existing projects running v2.9.0 get language hardening by:

```bash
claude "/mas:bootstrap --update"
```

Bootstrap detects the stack, writes `rules/language-stack.md`, and the next engineer + reviewer dispatch picks it up automatically. No other changes required.

---

## Implementation Scope

5 tasks, all small:

| Task | Change | Effort |
|------|--------|--------|
| T1 | `bootstrap.md` — add language detection + write `rules/language-stack.md` | Medium |
| T2 | `rules/language-stack.md` — Python template | Small |
| T3 | `rules/language-stack.md` — TypeScript template | Small |
| T4 | `agents/engineer/CLAUDE.md` — add language diagnostics step to Phase 4 | Tiny |
| T5 | `agents/reviewer/CLAUDE.md` — add language diagnostics + anti-pattern instruction to Phase B | Tiny |

No new agents. No new hooks (optional addition). Bootstrap owns the language context; agents consume it.

---

## Open Questions Before Implementation

1. **Multi-stack projects** (e.g., Python FastAPI + TypeScript Next.js): Should `rules/language-stack.md` have separate sections per language, or generate two files? Proposed: one file with `## Backend (Python)` and `## Frontend (TypeScript)` sections.

2. **Framework detection depth**: Should bootstrap detect Fastify vs Express vs NestJS and generate framework-specific rules? Or keep it to language-level only (TypeScript)? Proposed: language-level v1, framework-specific v2.

3. **Custom anti-patterns**: Should users be able to add project-specific anti-patterns to `rules/language-stack.md`? Proposed: yes — bootstrap generates a `## Project-Specific Rules` section at the bottom with a comment.

4. **Bootstrap `--update` behavior**: Should re-running bootstrap overwrite `rules/language-stack.md` (wiping custom additions) or merge? Proposed: regenerate the auto-detected sections, preserve the `## Project-Specific Rules` section.
