---
tags:
  - -scope/implementation
---

# 13. Persist VMPooler groups in a global groups.yaml loaded by Bolt

Date: 2026-10-27

## Status

Accepted

## Context

`binvv -g "name:regex"` only built groups for that one run, and they were embedded in `inventory.yaml`. A test setup needs groups that stay put (for example `2agents` for the agents wired to one PE primary and `3agents` for another) while VMs come and go.

Bolt's `yaml` plugin can load groups from a file, but a missing file is an error and two groups with the same name fail with "Tried to redefine group".

## Decision

Therefore, I decided to keep the groups in one file, `~/.config/bolt_dynamic_inventory/vmpooler/groups.yaml`, and have `inventory.yaml` load it with the yaml plugin:

```yaml
groups:
- name: windows
  ...
- name: linux
  ...
- _plugin: yaml
  filepath: "~/.config/bolt_dynamic_inventory/vmpooler/groups.yaml"
```

- `inventory.yaml` keeps only the targets and the `windows`, `linux` and `unavailable` groups.
- The groups file is a plain YAML list of groups, because the plugin returns the file as the list of groups. An older file with a top-level `groups:` key is still read and is rewritten as a list.
- The groups file is written before `inventory.yaml`, on every run, so it always exists and the plugin never fails on a missing file.
- `-g` creates groups in the file and does not overwrite an existing name unless `--force`. The names `global`, `windows`, `linux` and `unavailable` are refused, as they would be duplicates.
- `global` is rewritten on every run to list the current VMs. Other groups keep their targets; a target no longer in `global` is dropped (asking `[yN]` on a terminal, otherwise with a stderr notice). An emptied group is kept.
- The file holds only valid Bolt group keys (`name`, `targets`, `facts`). A `pattern` key made Bolt warn "unexpected key(s) pattern", so the regex is not stored and the file has no header comment; `-g` uses the regex once to pick targets.

## Consequences

- Groups survive a refresh, so `bolt inventory show --targets 2agents` stays stable while the pool changes.
- A group's targets are no longer recomputed from its regex; the regex only records how the group began.
- **A local `groups.yaml` layered over the global one is dropped.** The first design merged both inside the gem, so a local group could replace a global one. Loading through the yaml plugin means Bolt reads the file itself, and two files that define the same group name fail, so a local override cannot work; a missing local file would fail too. Use a different group name, or a project-specific inventory.
- An empty VM list (a failed `floaty` call) never prunes anything.
- Supersedes the per-run regex groups of [ADR-0004](0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) for the VMPooler provider; orbstack keeps them.
