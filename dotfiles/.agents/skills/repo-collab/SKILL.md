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

## Author issues and proposals

- For planning issues, including internal tracker tickets, describe the problem, desired outcome, and observable acceptance criteria. Follow the supplied template. Do not turn an already implemented solution into requirements: omit chosen libraries, tools, exact configuration values, and implementation-specific exclusions unless the user explicitly makes them requirements.
- Keep acceptance criteria concrete without prescribing the solution, e.g. "CLI commands for formatting" rather than "Just recipes using Prettier". Reserve implementation decisions for the PR or an explicitly requested technical proposal.
- When maintainer interest or design direction is uncertain, frame the issue as a proposal and offer a PR if welcome. An experiment can inform the discussion without committing the maintainer to an approach.
- For unresolved design tradeoffs, lay out the viable options and their consequences for the maintainer to choose before treating an approach as settled. If you have a preference, state it at the end, after the options and question. Keep this conversational and personal.
- Propose experimental implementations, and wait for confirmation before building them. Keep them isolated and out of the PR until the maintainer agrees on the direction. Use the findings to explain the options, distinguishing demonstrated behavior from remaining uncertainties.

## Prepare PRs

- Lead with the problem and resulting behavior. In PRs and technical proposals, explain design choices, tradeoffs, and meaningful limitations; omit implementation details readily visible in the diff.
- Run appropriate validation, but omit routine success reports, test counts, and validation sections unless the project requires them or the evidence resolves a substantive concern. Disclose failures and relevant verification gaps.
- For an unsolicited feature PR, a brief "Feel free to close this PR if it isn't wanted" can be appropriate; do not add it mechanically to every contribution.

## Respond to review feedback

- Read the review and inspect affected code, then propose a numbered action list covering code changes, draft replies, and threads to leave untouched. Refine it with the user before changing code or posting replies, then execute the agreed batch after confirmation. If new findings require a material change of plan, bring that decision back to the user.
- Answer straightforward review questions directly before describing changes made in response. Put any brief change note last, e.g. "Added a code comment to make this clear."
- Do not resolve review threads started by others. Leave them open for their authors to decide when their concerns are resolved.

## Publish and follow up

- Creating a draft or experimental branch does not itself authorize posting an issue, comment, or PR. Follow the user's requested scope and existing authorization.
- For PRs, link the related issue and allow maintainer edits where supported. Verify that permission on the resulting PR.
- Review the title, description, examples, and links against the final diff before publishing or updating them.
- When an experiment reveals a design question, add a concise follow-up with the branch, actual behavior, and the question. Keep the original proposal readable; avoid narrating routine work.
