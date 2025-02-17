# 6. Extend the Plugin to Handle Not Only Orbstack but VMPooler as Well

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
