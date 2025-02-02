# OrbstackBoltInventory

A Bolt inventory generator for Orbstack VMs.

## Overview

This `orbstack_bolt_inventory` gem queries Orbstack and generates a Bolt inventory. It provides two interfaces:

* `orby`: A command-line executable that outputs the bolt inventory to stdout
* `orbstack_bolt_inventory`: A [bolt dynamic inventory plugin](https://www.puppet.com/docs/bolt/latest/writing_plugins.html#reference-plugins)

## Tutorials

The following assume you have already created some orbstack VMs.

### Setup command-line

1. Install the gem by adding to your Gemfile:

   ```ruby
   gem 'orbstack_bolt_inventory', git: 'https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git', branch: 'main'
   ```

2. Generate your first inventory:

   ```bash
   bundle exec orby > inventory.yaml
   ```

3. Verify the inventory works:

   ```bash
   bolt inventory show
   ```

### Set up Bolt Dynamic Inventory Plugin

1. Add to your `bolt-project.yaml`:

   ```yaml
   name: bigbird
   modules:
     - git: https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git
       ref: main
   ```

2. Install the module with `bolt module install`

3. Create basic `inventory.yaml`:

   ```yaml
   version: 2
   _plugin: orbstack_bolt_inventory
   ```

4. Verify the inventory works:

   ```bash
   bolt inventory show
   ```

## How-To Guides

### Create Dynamic Inventory Groups via Command Line

To generate an inventory with specific group patterns:

```bash
bundle exec orby -g "agents:agent*","compilers:compiler*"
```

### Create Dynamic Inventory Groups in inventory.yaml

1. Create an `inventory.yaml` with group patterns:

   ```yaml
   version: 2
   _plugin: orbstack_inventory
   group_patterns:
     - group: agents
       regex: "^agent"
     - group: compilers
       regex: "^compiler"
   ```

2. Verify the groups:

   ```bash
   bolt group show
   bolt command run "hostname" --targets=agents
   bolt command run "hostname" --targets=compilers
   ```

### Development Guide

For development instructions, see [how-to-develop-the-module](./docs/how-tos/how-to-develop-the-module/README.md)

## Reference

### Configuration Options

The default configuration uses:

* Transport: SSH
* Native SSH: enabled
* Login Shell: bash
* TTY: false
* Host Key Check: disabled
* Run As: root
* Default Port: 32222

### Sample Output Format

```yaml
config:
  transport: ssh
  ssh:
    native-ssh: true
    load-config: true
    login-shell: bash
    tty: false
    host-key-check: false
    run-as: root
    user: root
    port: 32222
targets:
- name: agent01
  uri: agent01@orb
groups:
- name: agents
  targets:
  - agent01
```

## Explanation

### Architecture and Design Decisions

The project's architecture is documented through Architecture Decision Records (ADRs):

<!-- adrlog -->

* [ADR-0001](docs/adr/0001-extend-this-gem-to-be-a-bolt-inventory-dynamic-plugin-also.md) - Extend this gem to be a bolt inventory dynamic plugin also
* [ADR-0002](docs/adr/0002-configure-bolt-inventory-with-native-ssh-to-keep-things-simple.md) - Configure bolt inventory with native ssh to keep things simple
* [ADR-0003](docs/adr/0003-gather-inventory-metadata-via-the-orb-cli-to-keep-things-simple.md) - Gather inventory metadata via the 'orb' cli to keep things simple
* [ADR-0004](docs/adr/0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) - Create dynamic inventory groups based on hostname regex patterns
* [ADR-0005](docs/adr/0005-create-group-role-fact-for-each-group-and-equal-to-the-group-name.md) - Create group 'role' fact for each group and equal to the group name

<!-- adrlogstop -->

### Key Concepts

* **Dynamic Groups**: Groups are created based on regex patterns matching target names
* **Native SSH**: Used for simplicity and compatibility with standard SSH configurations
* **Dual Interface**: Provides both CLI tool (`orby`) and Bolt plugin interface for flexibility

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
