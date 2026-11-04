---
tags:
  - -scope/implementation
---

# 14. Print the inventory file name by default and persist the OrbStack inventory too

Date: 2026-11-04

## Status

Accepted

## Context

`binv` printed the inventory YAML on standard output, so callers that need a file wrote `--inventoryfile=<(binvv)`. A process substitution is a pipe that can be read only once: `floatys` reads the inventory once per group name and again for its revert probe, so only the first group resolved and the later ones were treated as VM names. `perun` and `floatys` work better with a file path than with raw YAML. Only the vmpooler provider wrote its inventory to a file (`inventory.yaml` with a `groups.yaml` loaded by Bolt's yaml plugin, ADR 13); OrbStack printed an inline inventory and kept no file.

An earlier version of this change added `--path` and kept the YAML as the default. The decision below replaces it: the file name is what callers need almost every time, and the YAML is the exception.

## Decision

Therefore, I decided that `binv`, `binv --provider=orbstack` and `binvv` generate the inventory as usual and then print only the path of the provider's `inventory.yaml` on standard output (the "Inventory written to" line stays on standard error), so `--inventoryfile="$(binvv)"` gives a regular file that can be read any number of times. `--stdout` prints the inventory YAML instead, for quick troubleshooting. `--path` does not exist.

To make that true for OrbStack too, the OrbStack provider now persists `~/.config/bolt_dynamic_inventory/orbstack/inventory.yaml` and a `groups.yaml` beside it, built by the same `Groups` class as vmpooler, so `global` and `ungrouped` are always present and `-g` groups persist. OrbStack groups now come from `groups.yaml` through the yaml plugin instead of being embedded.

## Consequences

- **Breaking:** `<(binvv)` now hands the caller a file that holds a path, not YAML. Callers change to `"$(binvv)"`; use `--stdout` where YAML is wanted.
- Every tool can take a real file; the "pipe read once" class of bug goes away.
- OrbStack users get the persistent groups vmpooler users already had; an empty custom group is now kept in the file.
- Running `binv` for OrbStack now writes files under `~/.config`, as vmpooler already did.

## Related Topics

- [13. Persist VMPooler groups in a global groups.yaml loaded by Bolt](0013-persist-vmpooler-groups-in-a-global-groups-yaml-loaded-by-bolt.md)
- [15. List vmpooler snapshots as id and date, newest last](0015-list-vmpooler-snapshots-as-id-and-date-newest-last.md)
- [How to keep groups in a persistent groups.yaml](../howto_how_to_keep_groups_in_a_persistent_groups_yaml.md)
