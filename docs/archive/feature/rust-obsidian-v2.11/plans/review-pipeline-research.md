# Review Pipeline Research: Multi-Agent Code Review and QA Patterns

Date: 2026-03-30

---

## 1. Batch Review vs Atomic Review

### What the evidence says

The overwhelming consensus from both industry practice and empirical research is that **atomic (small, focused) reviews outperform batch reviews** for defect detection.

**SmartBear/Cisco study** (2,500 reviews, 3.2M LOC, 10 months):
- Reviewers detect defects most effectively at **200-400 LOC per review**. Beyond 400 LOC, detection drops significantly.
- Optimal inspection rate is **under 300 LOC/hour**. At 500+ LOC/hour, reviewers miss a significant percentage of defects.
- Defect detection **plummets after 60-90 minutes** of continuous review.
- Average was 32 defects per 1,000 LOC across the study; 61% of reviews found no defects.

**Google's engineering culture** is built around small, incremental diffs. The rationale: smaller changes are easier to understand, faster to review, safer to merge, and simpler to revert.

**DORA metrics research** reinforces this: reducing batch size of changes improves both throughput AND stability. Smaller changes move faster through delivery and are easier to recover from on failure.

### Implication for multi-agent pipelines

Each task should be reviewed individually (atomic), not batched. A batch review of 5 tasks forces the reviewer agent into the equivalent of a 1000+ LOC review, which research shows degrades detection quality. Atomic reviews keep each review within the effective 200-400 LOC window.

---

## 2. AI Agent Orchestration Patterns for Review/QA

### Generator-Critic pattern (dominant)

The most common pattern across all major frameworks is **Generator-Critic** (also called Generator-Verifier, Evaluator-Optimizer, or Reflection Loop):

- **One agent generates** output (code, plan, content)
- **A separate agent critiques** it against specific criteria
- Optionally, a **refinement loop** iterates until quality threshold or iteration cap

This pattern appears in:

| Framework | Implementation |
|-----------|---------------|
| **Google ADK** | Generator, Critic, and Refiner as three sequential agents. Supports `escalate=True` for early exit when quality threshold is met. |
| **CrewAI** | Role-based crews; a "reviewer" role can be assigned to an agent in a sequential or hierarchical process. |
| **AutoGen/AG2** | GroupChat with selector; agents debate and refine through multi-turn conversation. |
| **LangGraph** | Graph nodes with conditional edges; a reviewer node can loop back to generator or pass through. |
| **Microsoft Agent Framework** | Orchestrator-worker with evaluator-optimizer loop. Requires clear acceptance criteria and iteration cap. |
| **Anthropic patterns** | Lead agent dispatches to subagents; subagents can be paired with reviewers. |

### Key architectural principle

**Reliability comes from decentralization and specialization.** A reviewer agent that has no stake in defending the original output catches errors that self-review misses. This is the AI equivalent of "no one reviews their own code."

### Worker-reviewer pairing vs centralized reviewer

Two models exist:

1. **Paired model**: Each worker agent has a dedicated reviewer agent. Used in CrewAI's sequential process and Google ADK's Generator-Critic pattern. Pros: focused review, clear accountability. Cons: more agent invocations, higher cost.

2. **Centralized reviewer**: A single reviewer agent examines all outputs. Used in orchestrator-worker patterns (Microsoft, Anthropic). Pros: consistent standards, lower overhead. Cons: bottleneck, context overload if batched.

The research suggests the **paired model with atomic reviews** is most effective for quality, while the **centralized model** works when the reviewer has clear, narrow acceptance criteria (like a linter or type-checker).

---

## 3. Code Review Effectiveness Research

### Key empirical findings

| Finding | Source |
|---------|--------|
| 200-400 LOC is the optimal review size | SmartBear/Cisco (2006) |
| Detection rate drops at >500 LOC/hr inspection speed | SmartBear/Cisco (2006) |
| Detection degrades after 60-90 min continuous review | SmartBear/Cisco (2006) |
| Optimal number of reviewers is **2** | Porter et al. |
| Reviewer **expertise** is the strongest predictor of effectiveness | Porter et al. |
| Formal inspections: 60-65% defect discovery rate | Capers Jones (12,000 projects) |
| Informal inspections: <50% defect discovery rate | Capers Jones |
| Most forms of testing: ~30% defect discovery rate | Capers Jones |

### What this means for AI reviewers

- AI reviewers don't fatigue like humans, but they DO suffer from **context window dilution**. A 400 LOC review uses far less context than a 2000 LOC batch review, leaving more capacity for reasoning.
- The "2 reviewers" finding maps well to multi-agent systems: one domain-specific reviewer (e.g., security, architecture) and one general-purpose reviewer (e.g., correctness, style).
- The expertise finding suggests specialized reviewer agents outperform generalist ones. A "security reviewer" prompt will catch more security issues than a "general reviewer" prompt.

---

## 4. Pipeline Throughput vs Quality Trade-offs

### DORA's central finding: speed and quality are NOT trade-offs

DORA's research across thousands of teams consistently shows that **elite performers excel at both speed and stability**. The four key metrics:

- **Throughput**: Deployment frequency, change lead time
- **Stability**: Change failure rate, time to restore service

Teams that ship faster also tend to have lower failure rates. The mechanism is **small batch sizes**: smaller changes are easier to review, test, deploy, and roll back.

### AI-specific finding (DORA 2025)

The 2025 DORA Report found that **AI adoption improves throughput but increases delivery instability**. Teams need seven critical capabilities before AI tools deliver full value. This directly applies to AI-agent pipelines: adding AI workers without corresponding review infrastructure increases defect rates.

### Practical implication

For a multi-agent pipeline:
- **Do not skip review to go faster.** The DORA data shows this is a false economy.
- **Keep review scope small** (per-task, not per-batch) to maintain both speed and quality.
- **Invest in review infrastructure** (clear criteria, specialized reviewers) before scaling agent throughput.

---

## 5. Structural Enforcement Patterns

### GitHub / CI/CD quality gates

Production CI/CD systems enforce quality through layered gates:

| Gate | Mechanism | What it prevents |
|------|-----------|-----------------|
| **Required reviewers** | Branch protection: minimum N approving reviews | Unreviewed code reaching main |
| **Code owners** | CODEOWNERS file + required code owner review | Changes to critical paths without domain expert sign-off |
| **Required status checks** | CI must pass (build, test, lint, security scan) | Broken or non-compliant code merging |
| **Dismiss stale reviews** | Auto-dismiss approval when new commits are pushed | Approval of code that changed after review |
| **Up-to-date branch** | Require branch is current with base before merge | Merge conflicts and integration issues |
| **Force push protection** | Prevent history rewriting on protected branches | Lost commits and audit trail destruction |
| **Environment protection** | Required reviewers for deployment to prod | Unauthorized deployments |

### Mapping to multi-agent pipelines

These patterns translate directly:

| CI/CD Pattern | Multi-Agent Equivalent |
|--------------|----------------------|
| Required reviewers | Mandatory reviewer agent dispatch after each engineer agent |
| Required status checks | Automated verification step (tests pass, lint clean, typecheck clean) |
| Code owners | Specialized reviewer agents for specific file patterns or domains |
| Dismiss stale reviews | Re-review if engineer agent modifies code after initial review |
| Iteration cap | Maximum review-fix cycles before escalation (prevents infinite loops) |

### Microsoft's evaluator-optimizer safeguards

Microsoft's guidance specifically calls out:
- **Clear acceptance criteria** for the reviewer agent (not vague "review this code")
- **Iteration cap** to prevent infinite refinement loops
- **Fallback behavior**: escalate to human or return best result with quality warning

---

## Summary of Recommendations for Multi-Agent Pipelines

1. **Review atomically, not in batches.** Each task gets its own review cycle. This aligns with the 200-400 LOC finding, DORA small-batch principles, and all major framework patterns.

2. **Use the Generator-Critic pattern.** Pair each engineer agent's output with a dedicated reviewer agent. The reviewer should have no context about the generation process to ensure independence.

3. **Specialize reviewers.** Instead of one general reviewer, use focused review passes (correctness, security, architecture adherence, duplication). This matches the finding that reviewer expertise is the strongest predictor of effectiveness.

4. **Enforce structural gates.** Every task must pass: (a) reviewer agent approval, (b) automated checks (tests, lint, typecheck). No task proceeds without both.

5. **Cap iteration loops.** Set a maximum of 2-3 review-fix cycles per task. If not resolved, escalate (to human or to a different approach). This prevents infinite loops and aligns with Microsoft's evaluator-optimizer guidance.

6. **Small batch sizes improve BOTH speed and quality.** This is the DORA finding. Do not sacrifice review depth for pipeline throughput.

---

## References

- [SmartBear/Cisco Code Review Study](https://static0.smartbear.co/support/media/resources/cc/book/code-review-cisco-case-study.pdf)
- [SmartBear 11 Best Practices for Peer Code Review](http://viewer.media.bitpipe.com/1253203751_753/1284482743_310/11_Best_Practices_for_Peer_Code_Review.pdf)
- [Mike Conley - SmartBear, Cisco, and the Largest Study on Code Review Ever](https://mikeconley.ca/blog/2009/09/14/smart-bear-cisco-and-the-largest-study-on-code-review-ever/)
- [DORA Metrics - Software Delivery Performance](https://dora.dev/guides/dora-metrics/)
- [Graphite - Empirically Supported Code Review Best Practices](https://graphite.com/blog/code-review-best-practices)
- [Google ADK - Developer's Guide to Multi-Agent Patterns](https://developers.googleblog.com/developers-guide-to-multi-agent-patterns-in-adk/)
- [Google ADK - Multi-Agent Systems Documentation](https://google.github.io/adk-docs/agents/multi-agents/)
- [Microsoft Azure - AI Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [InfoQ - Google's Eight Essential Multi-Agent Design Patterns](https://www.infoq.com/news/2026/01/multi-agent-design-patterns/)
- [DataCamp - CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen)
- [GitHub Docs - Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule)
- [Graphite - Mandatory Pull Request Checks](https://graphite.com/guides/mandatory-pull-request-checks-and-requirements-in-github)
- [Jellyfish - Peer Code Review Best Practices](https://jellyfish.co/library/developer-productivity/peer-code-review-best-practices/)
- [DevOps.com - Improve Efficiency with Smaller Code Reviews](https://devops.com/improve-efficiency-with-smaller-code-reviews/)
- [Virtuoso QA - Multi-Agent Testing Systems](https://www.virtuosoqa.com/post/multi-agent-testing-systems-cooperative-ai-validate-complex-applications)
- [AWS - Scaling Content Review with Multi-Agent Workflow](https://aws.amazon.com/blogs/machine-learning/scaling-content-review-operations-with-multi-agent-workflow/)
- [Code Review Effectiveness - IET Software (Jureczko, 2020)](https://ietresearch.onlinelibrary.wiley.com/doi/full/10.1049/iet-sen.2020.0134)
