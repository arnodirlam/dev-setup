# Batch templates

Use an Updates section for both straightforward updates and migrations. Keep one description for the final batch scope, with release or migration links beside each dependency. Library/version labels may be bold; bold descriptive text identifies adaptations that caused code changes, including configuration, tests, and formatter output. A dependent version bump alone does not count as a migration.

## Updates

```markdown
## Updates

Changes that required/caused code changes are bold.

- **Library A old → new:** [relevant fixes/features; project impact]. [Release notes](url)

- **Library B old → new** · [Release notes](url) · [Migration guide](url)

  - [Other relevant release changes, grouped briefly.]
  - **[Required API adaptation and its purpose.]**
  - **[Formatter-driven changes to affected templates.]**
  - **[Required test adaptation.]**
```

Use one sub-bullet per migration or code change. Describe purpose and outcome concisely; keep detailed implementation explanations out of the update list. Include only applicable items and source links.

## Optional sections

```markdown
## Open questions

- [Unresolved decision, compatibility concern, warning/audit finding, failing check, or verification gap.]

## Follow-ups

- [Issue/PR or stable batch name]: [deferred work, benefit, and dependency on this update].

## Related batches

- [Issue/PR or stable batch name]: [depends on / blocks / independent].
```

Mention excluded, unused, or deferred work only under Follow-ups or Related batches. Omit empty sections and routine passing-check reports. Include the warning and audit comparison required by SKILL.md.
