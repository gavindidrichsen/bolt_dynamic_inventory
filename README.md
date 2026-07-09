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
