# 4. Create dynamic inventory groups based on hostname regex patterns

Date: 2025-01-19

## Status

Accepted

## Context

The bolt_dynamic_inventory plugin needed a way to dynamically create groups based on target name patterns. This would allow users to organize their targets into logical groups without hardcoding the group assignments in the plugin code.

## Decision

Therefore, I decided to:

1. Add a `group_patterns` configuration option to the inventory plugin
1. Allow users to specify patterns in their inventory.yaml like:

```yaml
_plugin: bolt_dynamic_inventory
group_patterns:
  - group: agents
    regex: "^agent"
  - group: compilers
    regex: "^compiler"
```

## Consequences

The bolt_dynamic_inventory plugin now supports dynamic group creation based on target name patterns. This allows users to group their targets into logical groups based on their names.  **NOTE**:

* if `group_patterns` is empty, then no groups are created.
* if a group's regex pattern fails to match any targets, then that group is skipped.
