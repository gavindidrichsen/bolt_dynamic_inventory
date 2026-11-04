---
tags:
  - -scope/implementation
---

# 16. Answer from the cache and check the VMs only on --refresh

Date: 2026-11-04

## Status

Accepted

## Context

Every `binv --provider=vmpooler` run asked floaty for the VM list when the cache had expired or a VM's lifetime had run out, and always ran `nmap` on every VM to see which answer on port 22. That took about 20 seconds even when nothing had changed, which is too slow for `--inventoryfile="$(binvv)"`, a command people put in front of every `floatys`, `perun` and `bolt` call.

## Decision

Therefore, I decided that a plain `binvv` (and `binvv --stdout`) answers from the cache and makes no network call: no `floaty`, no `nmap`. Only `binvv --refresh`, or a first run with no cache, asks floaty for the VMs and checks them, and it stores each VM's result as a `reachable` flag in `cache.json`. Later runs build the `windows`, `linux` and `unavailable` groups from those flags; a VM in a cache written before the flag existed counts as reachable. A cache past its expiry is still used, with one line on standard error saying to run `binv --refresh`.

## Consequences

- A plain `binvv` takes about half a second (measured 0.4 to 0.6 s on 19 VMs; a refresh took 22 s).
- The inventory can be out of date until someone runs `binvv --refresh`: new VMs, released VMs and new snapshot ids do not appear, and a VM whose lifetime ran out stays listed. `floatys snapshot` already prints a reminder to refresh.
- Snapshot dates (ADR 15) are re-read from the floatys ledger on every run, so a new date shows at once, but a new snapshot id still needs a refresh.
- Whether the `unavailable` group is still wanted is open: it now reflects the last refresh only.

## Related Topics

- [9. Cache VM data with smart TTL-based invalidation](0009-cache-vm-data-with-smart-ttl-based-invalidation.md)
- [10. Surface unavailable VMs in a dedicated group instead of silently dropping](0010-surface-unavailable-vms-in-a-dedicated-group-instead-of-silently-dropping.md)
- [14. Print the inventory file name by default and persist the OrbStack inventory too](0014-print-the-inventory-file-name-by-default-and-persist-the-orbstack-inventory-too.md)
