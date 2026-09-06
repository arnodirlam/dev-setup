# Batch templates

## Straightforward updates

```markdown
## Updates
- [Library] [old → new]: [relevant fixes/features; project impact].
  [Release notes](url)

## Open questions
- [Unresolved decision, compatibility concern, failing check, or verification gap].

## Related batches
- [Issue/PR]: [depends on / blocks / independent].
```

## Non-straightforward updates

```markdown
## Update
[Library/group] [old → new]. [Reason for separate batch.]

## Changes
- [Upstream change → required adaptation].
- [New capability → simplification/improvement adopted].

[Release notes](url) · [Migration guide](url)

## Open questions
- [Unresolved decision, compatibility concern, failing check, or verification gap].

## Follow-ups
- [Issue/PR]: [improvement deferred and why].

## Related batches
- [Issue/PR]: [depends on / blocks / independent].
```

Add Follow-ups to a straightforward batch when it enables separately scoped improvements.
