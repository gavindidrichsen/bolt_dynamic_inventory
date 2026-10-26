---
tags:
  - -scope/implementation
---

# 11. Name VMPooler targets by FQDN with the short name as an alias

Date: 2026-10-26

## Status

Accepted

## Context

Bolt target names were the short VMPooler hostname (`high-machine`) with the FQDN only in `uri`. `peadm::install` takes the PE certname from the Bolt target name and only compares it with the hostname the node reports, so a short name gave a short console certificate and the warning `Target name / hostname mismatch`. This surfaced while installing PE for a certificate investigation.

## Decision

Therefore, I decided to emit the FQDN as the target `name` and keep the short name as an `alias`:

```yaml
- name: high-machine.delivery.puppetlabs.net
  alias: high-machine
  uri: high-machine.delivery.puppetlabs.net
```

- Groups (`linux`, `windows`, `unavailable` and regex groups) list the target `name`, so they list FQDNs
- Regex group patterns still match the short name, so existing `--groups` patterns keep working
- The Orbstack provider is unchanged: its names are not resolvable hostnames

## Consequences

- `peadm::install` sets the certname to the long hostname, and the mismatch warning disappears
- `bolt --targets` accepts either the FQDN or the short alias
- Plan parameters that name a target (for example peadm `primary_host`) should use the FQDN, because that is what the plan sees as the name
- Anything that matched on the old short `name` of a VMPooler target (scripts, saved `inventory.yaml` files) must be regenerated

## Related Topics

- [[0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns|ADR-0004]]: Regex groups, which still match the short name
- [[0006-extend-the-plugin-to-handle-not-only-orbstack-but-vmpooler-as-well|ADR-0006]]: The VMPooler provider
