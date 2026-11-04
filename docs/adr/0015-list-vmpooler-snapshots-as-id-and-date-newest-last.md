---
tags:
  - -scope/implementation
---

# 15. List vmpooler snapshots as id and date, newest last

Date: 2026-11-04

## Status

Accepted

## Context

ADR 12 listed vmpooler snapshot ids in each target's vars. vmpooler returns ids only, in no reliable order (newest first on one VM, newest last on another), and no call returns a time, so neither a person nor `floatys revert` could tell which snapshot was newest. `floatys` keeps a ledger (`~/.config/floaty/snapshots.json`) of when it made, or first saw, each id.

## Decision

Therefore, I decided that `vars.snapshots` lists each snapshot as `id:date` (UTC, for example `tz0pi6kk4y0a2sz20edbn8g4k6gw0xv8:2026-11-02T12:59:39Z`), oldest first, so the newest is the last. The dates come from the floatys ledger when the inventory is generated, not from vmpooler. An id the ledger does not know is `id:unknown` and is listed first, because everything `floatys` makes is recorded, so an unknown id predates it or was made elsewhere. With no ledger, every id is `id:unknown`.

## Consequences

- A person can see when each snapshot was taken, and a script can take the last element.
- The ledger is still the only record of times; this does not replace it, and the dates are the ledger's (the time of first sighting for an id `floatys` did not make).
- A consumer that read `vars.snapshots` as bare ids must now split each entry on its first colon.
- The inventory is regenerated from the cache, so the dates are as fresh as the last `binv` run.

## Related Topics

- [12. List vmpooler snapshot ids in target vars](0012-list-vmpooler-snapshot-ids-in-target-vars.md)
- [14. Print the inventory file name by default and persist the OrbStack inventory too](0014-print-the-inventory-file-name-by-default-and-persist-the-orbstack-inventory-too.md)
