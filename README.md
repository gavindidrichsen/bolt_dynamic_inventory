# BoltDynamicInventory

A Bolt inventory generator for VMs on various providers including orbstack and vmpooler.

## Prerequisites

### System Dependencies

- **Ruby** (version 2.7 or later)
- **nmap** (required for VMPooler connectivity filtering).  For example, `brew install nmap`
- **floaty** (required for VMPooler).  For example, `gem install floaty`.
- **bolt**

## Usage

This `bolt_dynamic_inventory` gem queries either VMPooler or Orbstack and generates a Bolt inventory.  It can be used in 2 ways:

- **as a gem**.  For more information see [How to use as a gem](./docs/how_to/how_to_use_as_a_gem.md).
- **as a bolt dynamic inventory plugin**.  For more information see [How to use as a bolt dynamic plugin](./docs/how_to/how_to_use_as_a_bolt_dynamic_plugin.md).

This repository also explains [How to create a basic dynamic inventory plugin](./docs/how_to/how_to_create_a_basic_bolt_inventory_plugin.md).

For a listing of various how-to guides and design decisions, see the [documentation](./docs/README.md).

### Design Decisions

<!-- adrlog -->
* [ADR-0001](docs/adr/0001-extend-this-gem-to-be-a-bolt-inventory-dynamic-plugin-also.md) - Extend this gem to be a bolt inventory dynamic plugin also
* [ADR-0002](docs/adr/0002-configure-bolt-inventory-with-native-ssh-to-keep-things-simple.md) - Configure bolt inventory with native ssh to keep things simple
* [ADR-0003](docs/adr/0003-gather-inventory-metadata-via-the-cli-to-keep-things-simple.md) - Gather inventory metadata via the cli to keep things simple
* [ADR-0004](docs/adr/0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) - Create dynamic inventory groups based on hostname regex patterns
* [ADR-0005](docs/adr/0005-add-role-fact-that-matches-the-group-name-making-puppet-switching-easier.md) - Add 'role' fact that matches the group name making puppet switching easier
* [ADR-0006](docs/adr/0006-extend-the-plugin-to-handle-not-only-orbstack-but-vmpooler-as-well.md) - Extend the plugin to handle not only orbstack but vmpooler as well
* [ADR-0007](docs/adr/0007-use-nmap-ssh-port-scan-for-vmpooler-vm-connectivity-filtering.md) - Use nmap SSH port scan for VMPooler VM connectivity filtering
* [ADR-0008](docs/adr/0008-query-both-abs-and-vmpooler-services-to-find-all-active-vms.md) - Query both ABS and vmpooler services to find all active VMs
* [ADR-0009](docs/adr/0009-cache-vm-data-with-smart-ttl-based-invalidation.md) - Cache VM data with smart TTL-based invalidation
* [ADR-0010](docs/adr/0010-surface-unavailable-vms-in-a-dedicated-group-instead-of-silently-dropping.md) - Surface unavailable VMs in a dedicated group instead of silently dropping
<!-- adrlogstop -->
