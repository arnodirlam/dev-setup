---
name: repo-collab
description: Prepare or update repository issues, feature proposals, pull requests, and review follow-ups for upstream and team contributions using existing project conventions and concise, human communication.
---

# Repository Collaboration

## Inspect first

- Read contribution guidance, issue/PR templates, and related issues, discussions, and PRs before proposing work. Check current project behavior and whether it is intentional or already addressed.
- Before changing tests or docs, inspect nearby examples, fixtures, and coverage. Match their style, organization, and verbosity; extend existing coverage where it fits instead of adding redundant test files or cases.
- Before adding code comments, inspect their frequency and style in nearby code and match those conventions.
- Check expected output rather than assuming existing fixtures are correct. Distinguish a newly exposed flaw from an intended behavior change.
- Match documentation for new options to neighboring options, including examples and level of detail.

## Shared writing guidance

- Separate bugs from preferences and feature proposals. Use concrete input and actual output to show the problem; for proposals, explain the desired behavior and why it helps.
- Use concise before/after code examples where they clarify the change. Prefer default options; state any non-default options needed to reproduce it.
- Keep independent changes separate. Link related issues and PRs without duplicating their full discussion.
- Include concise examples in issue and review comments where they clarify the behavior or reasoning.
- Use natural, friendly prose. Respect collaborators' time without canned praise, demands, or excessive deference.
- Use "I" where appropriate in comments to make them personal, especially when explaining decisions or observations. Do not use em dashes.
- Describe the final scope for someone without conversation context. Remove abandoned approaches, stale descriptions, and statements about unrelated things the change does not do.
- Prefer explicit wording such as "test covering this bug" over ambiguous uses of "regression". Call a bug a regression only when evidence shows previously working behavior broke.
- Before changing a project, issue, or PR description authored by someone else, propose exact before/after replacements with enough unchanged context to locate each edit. Group them by project, issue, or PR. Prefer small wording changes; explain necessary broader rewrites. Refine the proposal with the user, then apply approved edits. If findings require a material change of plan, bring that decision back to the user.

## Author issues and proposals

- For planning issues, including internal tracker tickets, describe the problem and desired outcome. Follow the supplied template. Otherwise, use Context, Status Quo, Problem, Suggested Outcome, Implementation Approach, and Relevant Links as a flexible structure. Include only useful parts; use headings for larger issues and paragraphs for smaller ones.
- Context explains why the issue matters; Status Quo describes current behavior; Problem explains where that behavior falls short. Combine these where separate sections would repeat the same information.
- Suggested Outcome describes the desired behavior or capability. Use concrete examples where they clarify what would solve the problem, without prescribing the implementation.
- Implementation Approach is optional. Include a useful starting point or approach worth discussing, clearly marked as a suggestion rather than a requirement. Do not turn an already implemented solution into requirements: omit chosen libraries, tools, exact configuration values, and implementation-specific exclusions from requirements unless the user explicitly makes them requirements. Reserve settled implementation decisions for the PR or an explicitly requested technical proposal.
- Link sources near the claims they support; use Relevant Links for broader background and explain each link's relevance. Include open questions when they affect scope or the desired outcome.
- When maintainer interest or design direction is uncertain, frame the issue as a proposal and offer a PR if welcome. An experiment can inform the discussion without committing the maintainer to an approach.
- For unresolved design tradeoffs, lay out the viable options and their consequences for the maintainer to choose before treating an approach as settled. If you have a preference, state it at the end, after the options and question. Keep this conversational and personal.
- Propose experimental implementations, and wait for confirmation before building them. Keep them isolated and out of the PR until the maintainer agrees on the direction. Use the findings to explain the options, distinguishing demonstrated behavior from remaining uncertainties.

## Review project and issue coherence

- Read the project description and all issues in the requested scope. Compare them with supplied requirements and decisions, and with each other.
- Look for conflicting terminology or behavior, duplicated scope, missing work, and issues that exceed agreed requirements.
- Point to the specific project or issue text behind each finding. Distinguish confirmed mismatches from questions that need a product or project decision.
- A request to review authorizes investigation and findings. Before changing someone else's descriptions, follow the exact-edit proposal guidance above.

## Author ADRs and decision proposals

- Follow the repository's ADR template. For a Michael Nygard-style ADR, use Title, Status, Context, Decision, and Consequences.
- Write for peers evaluating the decision and engineers who may later need to understand why the codebase looks this way. Keep each sentence useful to one or both readers.
- When an options table is used, let it carry the pros and cons. Use surrounding prose to explain the weighting and trade-offs without repeating the table.
- Preserve concrete facts such as numbers, vendors, risks, and rejected options. Do not invent rationale; flag claims that need evidence, for example with `[needs source]`.
- Make the chosen option, reasons, consequences, rejected alternatives, and conditions that could invalidate the decision clear where they are known and relevant.
- When asked to sharpen an existing ADR, improve clarity without adding claims or rationale. Identify missing information instead of filling gaps by inference.

## Prepare PRs

- Lead with the problem and resulting behavior. In PRs and technical proposals, explain design choices, tradeoffs, and meaningful limitations; omit implementation details readily visible in the diff.
- Run appropriate validation, but omit routine success reports, test counts, and validation sections unless the project requires them or the evidence resolves a substantive concern. Disclose failures and relevant verification gaps.
- For an unsolicited feature PR, a brief "Feel free to close this PR if it isn't wanted" can be appropriate; do not add it mechanically to every contribution.

## Review PRs

- Read the PR description, related issue, project guidance, and affected code and callers before judging the diff. Verify whether the reported behavior is introduced or exposed by the change.
- Make each finding actionable: explain the scenario and consequence, and state the change or decision needed.
- Distinguish correctness problems, design concerns, optional suggestions, and questions. State which changes block approval and why; do not present personal preference as a project requirement.
- Check whether tests and fixtures meaningfully cover the behavior, and disclose relevant verification gaps.
- Keep feedback within the PR's scope. Suggest follow-up work for unrelated concerns.
- Read the author's explanations and reassess against the agreed direction. Explain newly discovered requirements rather than silently moving the goalposts.

## Respond to review feedback

- Read the review and inspect affected code, then propose a numbered action list covering code changes, draft replies, and threads to leave untouched. Refine it with the user before changing code or posting replies, then execute the agreed batch after confirmation. If new findings require a material change of plan, bring that decision back to the user.
- When the action list includes edits to descriptions authored by someone else, include the exact replacements and surrounding context in that list so the user can approve the combined batch.
- Answer straightforward review questions directly before describing changes made in response. Put any brief change note last, e.g. "Added a code comment to make this clear."
- Do not resolve review threads started by others. Leave them open for their authors to decide when their concerns are resolved.

## Publish and follow up

- Creating a draft or experimental branch does not itself authorize posting an issue, comment, or PR. Follow the user's requested scope and existing authorization.
- For PRs, link the related issue and allow maintainer edits where supported. Verify that permission on the resulting PR.
- Review the title, description, examples, and links against the final diff before publishing or updating them.
- When an experiment reveals a design question, add a concise follow-up with the branch, actual behavior, and the question. Keep the original proposal readable; avoid narrating routine work.
