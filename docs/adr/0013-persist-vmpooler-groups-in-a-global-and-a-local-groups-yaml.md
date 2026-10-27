---
tags:
  - -scope/implementation
---

# 13. Persist VMPooler groups in a global and a local groups.yaml

Date: 2026-10-27

## Status

Accepted

## Context

`binvv -g "name:regex"` only builds groups for that one run, and the output is a single `inventory.yaml`. A test setup needs groups that stay put (for example `2agents` for the agents wired to one PE primary and `3agents` for another) while VMs come and go, and a project sometimes needs its own groups on top.

Bolt's `yaml` plugin can supply groups from a file, but a missing file is an error and two files that define the same group name fail with "Tried to redefine group". It cannot do "use it if it exists" or "local overrides global", so the merge has to happen where the inventory is generated.

## Decision

Therefore, I decided to keep two optional files and merge them in the VMPooler provider:

- **Global**: `~/.config/bolt_dynamic_inventory/vmpooler/groups.yaml`.
- **Local**: `groups.yaml` in the current directory. A local group replaces a global group of the same name; a missing file is skipped.
- **Format**: one named block per group, with the regex that created it and the targets it holds.

```yaml
groups:
- name: global
  targets: [a.delivery.puppetlabs.net, b.delivery.puppetlabs.net]
- name: 2agents
  pattern: "^(a|b)"
  targets: [a.delivery.puppetlabs.net, b.delivery.puppetlabs.net]
```

- **`-g`** writes groups to the global file. It does not overwrite an existing name unless `--force` is given.
- **`global`** always lists every VM of the current run, so it is rewritten on every run.
- **Other groups** keep the targets they hold. A target that is no longer in `global` is dropped from them, after asking `[yN]` on a terminal, or with a notice on stderr when there is none.
- **A VM in no group** (once any group exists) is named on stderr.

## Consequences

- Groups survive a refresh, so `bolt inventory show --targets 2agents` stays stable while the pool changes.
- A group's targets are no longer recomputed from its regex on every run; the regex is a record of how the group began. Changing membership means editing the file or using `-g ... --force`.
- An empty VM list (a failed `floaty` call) never prunes anything.
- Supersedes the per-run regex groups of [ADR-0004](0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) for the VMPooler provider; orbstack keeps them.
