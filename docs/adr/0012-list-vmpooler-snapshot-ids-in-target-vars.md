---
tags:
  - -scope/implementation
---

# 12. List VMPooler snapshot ids in target vars

Date: 2026-10-27

## Status

Accepted

## Context

`floaty snapshot` and `floaty revert` let a set of VMPooler VMs be rolled back to a known state, for example a PE primary with its agents already connected. Nothing in the generated inventory showed which VMs had a snapshot, so a script could not tell which targets it was able to revert. The snapshot ids are already in the JSON that `floaty list --active --json --service vmpooler` returns, under a `snapshots` key that only appears for VMs that have one.

## Decision

Therefore, I decided to copy that list into each target's `vars` as `snapshots`, only when the VM has at least one:

```yaml
- name: high-machine.delivery.puppetlabs.net
  alias: high-machine
  uri: high-machine.delivery.puppetlabs.net
  vars:
    type: redhat-8-x86_64
    ttl: 2026-11-02 13:12
    snapshots:
    - uvz1nea1iadu1hbfgitvjfm8d1w0p10h
```

- VMs without a snapshot have no `snapshots` key, so `vars.snapshots` is a direct test for "has a snapshot"
- The list is read from the vmpooler service only; ABS entries are enriched with it in the same way as `ttl` (see [[0008-query-both-abs-and-vmpooler-services-to-find-all-active-vms|ADR-0008]])
- The Orbstack provider is unchanged

## Consequences

- A snapshot taken after the inventory was cached does not appear until `binv --provider=vmpooler --refresh`, because the cache is only invalidated by VM expiry or age (see [[0009-cache-vm-data-with-smart-ttl-based-invalidation|ADR-0009]])
- Snapshot ids are opaque strings that `floaty revert HOST ID --service vmpooler` accepts
- No extra calls to the pooler are made

## Related Topics

- [[0008-query-both-abs-and-vmpooler-services-to-find-all-active-vms|ADR-0008]]: Where the vmpooler JSON comes from
- [[0009-cache-vm-data-with-smart-ttl-based-invalidation|ADR-0009]]: Why a snapshot can be missing until a refresh
- [[0011-name-vmpooler-targets-by-fqdn-with-the-short-name-as-an-alias|ADR-0011]]: Target naming
