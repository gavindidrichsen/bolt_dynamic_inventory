# BoltDynamicInventory

A Bolt inventory generator for Orbstack VMs.

## Usage

This `bolt_dynamic_inventory` gem queries either VMPooler or Orbstack and generates a Bolt inventory.  It can be used in 2 ways:

* **as a gem**.  For more information see [How to use as a gem](./docs/how_to/how_to_use_as_a_gem.md).
* **as a bolt dynamic inventory plugin**.  For more information see [How to use as a bolt dynamic plugin](./docs/how_to/how_to_use_as_a_bolt_dynamic_plugin.md).

This repository also explains [How to create a basic dynamic inventory plugin](./docs/how_to/how_to_create_a_basic_bolt_inventory_plugin.md).  Other various how-to guides are beneath the [How To Guide Directory](./docs/how_to/).

### Architecture and Design Decisions

The project's architecture is documented through Architecture Decision Records (ADRs):

<!-- adrlog -->

* [ADR-0001](docs/adr/0001-extend-this-gem-to-be-a-bolt-inventory-dynamic-plugin-also.md) - Extend this gem to be a bolt inventory dynamic plugin also
* [ADR-0002](docs/adr/0002-configure-bolt-inventory-with-native-ssh-to-keep-things-simple.md) - Configure bolt inventory with native ssh to keep things simple
* [ADR-0003](docs/adr/0003-gather-inventory-metadata-via-the-orb-cli-to-keep-things-simple.md) - Gather inventory metadata via the 'orb' cli to keep things simple
* [ADR-0004](docs/adr/0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) - Create dynamic inventory groups based on hostname regex patterns
* [ADR-0005](docs/adr/0005-add-role-fact-that-matches-the-group-name-making-puppet-switching-easier.md) - Add 'role' fact that matches the group name making puppet switching easier
* [ADR-0006](docs/adr/0006-extend-the-plugin-to-handle-not-only-orbstack-but-vmpooler-as-well.md) - Extend the plugin to handle not only orbstack but vmpooler as well

<!-- adrlogstop -->
