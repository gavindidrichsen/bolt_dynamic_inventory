# OrbstackBoltInventory

A Bolt inventory generator for Orbstack VMs.

## Usage

This `orbstack_bolt_inventory` gem queries Orbstack and generates a Bolt inventory and can be used in 2 ways:

* **as a gem**.  For more information see [How to use the orbstack_bolt_inventory as a gem](./docs/how_to/how_to_use_orbstack_bolt_inventory_as_a_gem.md).
* **as a bolt dynamic inventory plugin**.  For more information see [How to use the orbstack_bolt_inventory as a bolt dynamic plugin](./docs/how_to/how_to_use_orbstack_bolt_inventory_as_a_bolt_dynamic_plugin.md).

This repository also explains [How to create a basic dynamic inventory plugin](./docs/how_to/how_to_create_a_basic_bolt_inventory_plugin.md).  Other various how-to guides are beneath the [How To Guide Directory](./docs/how_to/).

### Architecture and Design Decisions

The project's architecture is documented through Architecture Decision Records (ADRs):

<!-- adrlog -->

* [ADR-0001](docs/adr/0001-extend-this-gem-to-be-a-bolt-inventory-dynamic-plugin-also.md) - Extend this gem to be a bolt inventory dynamic plugin also
* [ADR-0002](docs/adr/0002-configure-bolt-inventory-with-native-ssh-to-keep-things-simple.md) - Configure bolt inventory with native ssh to keep things simple
* [ADR-0003](docs/adr/0003-gather-inventory-metadata-via-the-orb-cli-to-keep-things-simple.md) - Gather inventory metadata via the 'orb' cli to keep things simple
* [ADR-0004](docs/adr/0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) - Create dynamic inventory groups based on hostname regex patterns
* [ADR-0005](docs/adr/0005-create-group-role-fact-for-each-group-and-equal-to-the-group-name.md) - Create group 'role' fact for each group and equal to the group name

<!-- adrlogstop -->
