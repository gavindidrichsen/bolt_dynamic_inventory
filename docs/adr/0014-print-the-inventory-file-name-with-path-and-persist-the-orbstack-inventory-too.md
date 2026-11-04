---
tags:
  - -scope/implementation
---

# 14. Print the inventory file name with --path and persist the OrbStack inventory too

Date: 2026-11-04

## Status

Accepted

## Context

`binv` prints the inventory YAML on standard output, so callers that need a file wrote `--inventoryfile=<(binvv)`. A process substitution is a pipe that can be read only once: `floatys` reads the inventory once per group name and again for its revert probe, so only the first group resolved and the later ones were treated as VM names. Only the vmpooler provider wrote its inventory to a file (`inventory.yaml` with a `groups.yaml` loaded by Bolt's yaml plugin, ADR 13); OrbStack printed an inline inventory and kept no file.

## Decision

Therefore, I decided to add `binv --path`: it generates the inventory as usual, then prints only the path of the provider's `inventory.yaml` on standard output (the "Inventory written to" line stays on standard error). It works for every provider, so `binv --path`, `binv --provider=orbstack --path` and `binvv --path` all return a regular file that can be read any number of times: `--inventoryfile=$(binvv --path)`.

To make that true for OrbStack too, the OrbStack provider now persists `~/.config/bolt_dynamic_inventory/orbstack/inventory.yaml` and a `groups.yaml` beside it, built by the same `Groups` class as vmpooler, so `global` and `ungrouped` are always present and `-g` groups persist. The default output without `--path` is unchanged, except that OrbStack groups now come from `groups.yaml` through the yaml plugin instead of being embedded.

## Consequences

- Every tool can take a real file; `floatys` also copes with a pipe now, but the file is the robust form.
- OrbStack users get the persistent groups vmpooler users already had; an empty custom group is now kept in the file.
- Running `binv` for OrbStack now writes files under `~/.config`, as vmpooler already did.

## Related Topics

- [13. Persist VMPooler groups in a global groups.yaml loaded by Bolt](0013-persist-vmpooler-groups-in-a-global-groups-yaml-loaded-by-bolt.md)
- [How to keep groups in a persistent groups.yaml](../howto_how_to_keep_groups_in_a_persistent_groups_yaml.md)
