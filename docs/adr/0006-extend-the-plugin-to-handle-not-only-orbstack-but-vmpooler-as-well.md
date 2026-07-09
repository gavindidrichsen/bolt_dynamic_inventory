# 6. Extend the plugin to handle not only orbstack but vmpooler as well

Date: 2025-02-17

## Status

Accepted

## Context

The bolt_dynamic_inventory plugin was initially designed to work exclusively with Orbstack VMs. However, there was a need to support VMPooler VMs as well, since both types of VMs are commonly used in development and testing environments. Supporting both providers in a single plugin would provide a consistent interface and reduce code duplication.

## Decision

Therefore, I decided to:

1. Add a provider abstraction to support multiple VM providers
2. Create separate provider classes for Orbstack and VMPooler
3. Add a '--provider' command-line option to specify which provider to use
4. Implement VMPooler-specific features:
   * Use `floaty list --active --json` for efficient VM discovery
   * Add windows/linux group separation based on VM type
   * Configure appropriate SSH settings for each group
5. Maintain consistent features across providers:
   * Dynamic group creation based on regex patterns
   * Role facts that match group names
   * Native SSH configuration

## Consequences

The plugin now supports both Orbstack and VMPooler VMs with a consistent interface. Benefits include:

* Users can manage both types of VMs using the same tool and configuration patterns
* Common features like regex-based grouping work identically across providers
* Each provider can implement its own optimal way of discovering and configuring VMs
* The provider abstraction makes it easy to add support for additional VM providers in the future

**NOTE**: The provider must be specified either in the inventory configuration or via the --provider command-line option.

**Update (2026-07-09)**: The VMPooler provider now queries both ABS and vmpooler services to discover all active VMs (see [[0008-query-both-abs-and-vmpooler-services-to-find-all-active-vms|ADR-0008]]), caches results with smart TTL-based invalidation (see [[0009-cache-vm-data-with-smart-ttl-based-invalidation|ADR-0009]]), and surfaces unreachable VMs in an `unavailable` group (see [[0010-surface-unavailable-vms-in-dedicated-group-instead-of-silently-dropping|ADR-0010]]).
