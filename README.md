# BoltDynamicInventory

A Bolt inventory generator for VMs on various providers including orbstack and vmpooler.

## Prerequisites

### System Dependencies

- **Ruby** (version 2.7 or later)
- **nmap** (required for VMPooler connectivity filtering). For example, `brew install nmap`
- **floaty** (required for VMPooler). For example, `gem install floaty`.
- **bolt**

## Usage

### Quick Start

This `bolt_dynamic_inventory` gem queries either VMPooler or Orbstack and generates a Bolt inventory. It can be used in 2 ways:

- **as a gem**. For more information see [How to use as a gem](./docs/how_to/how_to_use_as_a_gem.md).
- **as a bolt dynamic inventory plugin**. For more information see [How to use as a bolt dynamic plugin](./docs/how_to/how_to_use_as_a_bolt_dynamic_plugin.md).

This repository also explains [How to create a basic dynamic inventory plugin](./docs/how_to/how_to_create_a_basic_bolt_inventory_plugin.md).

## References

For a complete listing of various how-to guides and design decisions, see the [documentation](./docs/README.md). The following list is a good place to start.

**Getting Started**

- [How to setup the environment](howto_how_to_setup_the_environment.md)
- [How to use as a gem](howto_how_to_use_as_a_gem.md)
- [How to use as a bolt dynamic plugin](howto_how_to_use_as_a_bolt_dynamic_plugin.md)
- [How to use the `role` fact](howto_how_to_use_the_role_fact.md)
- [How to create a basic dynamic inventory plugin](howto_how_to_create_a_basic_dynamic_inventory_plugin.md)

**Provider Guides**

- [How to create and remove orbstack VMs from the command-line](howto_how_to_create_and_remove_orbstack_vms_from_the_command_line.md)
- [How to setup windows credentials for vmpooler](howto_how_to_setup_windows_credentials_for_vmpooler.md)
- [How to Test VMPooler Inventory Features](howto_how_to_test_vmpooler_inventory_features.md)
- [How to keep groups in a persistent groups.yaml](docs/howto_how_to_keep_groups_in_a_persistent_groups_yaml.md)

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
* [ADR-0011](docs/adr/0011-name-vmpooler-targets-by-fqdn-with-the-short-name-as-an-alias.md) - Name VMPooler targets by FQDN with the short name as an alias
* [ADR-0012](docs/adr/0012-list-vmpooler-snapshot-ids-in-target-vars.md) - List VMPooler snapshot ids in target vars
* [ADR-0013](docs/adr/0013-persist-vmpooler-groups-in-a-global-and-a-local-groups-yaml.md) - Persist VMPooler groups in a global and a local groups.yaml
<!-- adrlogstop -->

### How-To Guides

<!-- howtolog -->
* [How to create a basic dynamic inventory plugin](docs/howto_how_to_create_a_basic_dynamic_inventory_plugin.md)
* [How to create and remove orbstack VMs from the command-line](docs/howto_how_to_create_and_remove_orbstack_vms_from_the_command_line.md)
* [How to keep groups in a persistent groups.yaml](docs/howto_how_to_keep_groups_in_a_persistent_groups_yaml.md)
* [How to setup the environment](docs/howto_how_to_setup_the_environment.md)
* [How to setup windows credentials for vmpooler](docs/howto_how_to_setup_windows_credentials_for_vmpooler.md)
* [How to Test VMPooler Inventory Features](docs/howto_how_to_test_vmpooler_inventory_features.md)
* [How to use as a bolt dynamic plugin](docs/howto_how_to_use_as_a_bolt_dynamic_plugin.md)
* [How to use as a gem](docs/howto_how_to_use_as_a_gem.md)
* [How to use the `role` fact](docs/howto_how_to_use_the_role_fact.md)
<!-- howtologstop -->
