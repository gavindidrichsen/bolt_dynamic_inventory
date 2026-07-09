# bolt_dynamic_inventory

## Getting Started

* [How to setup the environment](howto_how_to_setup_the_environment.md)
* [How to use as a gem](howto_how_to_use_as_a_gem.md)
* [How to use as a bolt dynamic plugin](howto_how_to_use_as_a_bolt_dynamic_plugin.md)

## Usage

* [How to use the `role` fact](howto_how_to_use_the_role_fact.md)
* [How to create a basic dynamic inventory plugin](howto_how_to_create_a_basic_dynamic_inventory_plugin.md)

## Provider Guides

### OrbStack

* [How to create and remove orbstack VMs from the command-line](howto_how_to_create_and_remove_orbstack_vms_from_the_command_line.md)

### VMPooler

* [How to setup windows credentials for vmpooler](howto_how_to_setup_windows_credentials_for_vmpooler.md)
* [How to Test VMPooler Inventory Features](howto_how_to_test_vmpooler_inventory_features.md)

## Design Decisions

<!-- adrlog -->
* [ADR-0001](adr/0001-extend-this-gem-to-be-a-bolt-inventory-dynamic-plugin-also.md) - Extend this gem to be a bolt inventory dynamic plugin also
* [ADR-0002](adr/0002-configure-bolt-inventory-with-native-ssh-to-keep-things-simple.md) - Configure bolt inventory with native ssh to keep things simple
* [ADR-0003](adr/0003-gather-inventory-metadata-via-the-cli-to-keep-things-simple.md) - Gather inventory metadata via the cli to keep things simple
* [ADR-0004](adr/0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) - Create dynamic inventory groups based on hostname regex patterns
* [ADR-0005](adr/0005-add-role-fact-that-matches-the-group-name-making-puppet-switching-easier.md) - Add 'role' fact that matches the group name making puppet switching easier
* [ADR-0006](adr/0006-extend-the-plugin-to-handle-not-only-orbstack-but-vmpooler-as-well.md) - Extend the plugin to handle not only orbstack but vmpooler as well
* [ADR-0007](adr/0007-use-nmap-ssh-port-scan-for-vmpooler-vm-connectivity-filtering.md) - Use nmap SSH port scan for VMPooler VM connectivity filtering
* [ADR-0008](adr/0008-query-both-abs-and-vmpooler-services-to-find-all-active-vms.md) - Query both ABS and vmpooler services to find all active VMs
* [ADR-0009](adr/0009-cache-vm-data-with-smart-ttl-based-invalidation.md) - Cache VM data with smart TTL-based invalidation
* [ADR-0010](adr/0010-surface-unavailable-vms-in-a-dedicated-group-instead-of-silently-dropping.md) - Surface unavailable VMs in a dedicated group instead of silently dropping
<!-- adrlogstop -->
