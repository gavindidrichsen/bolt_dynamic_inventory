# How to use the orbstack_bolt_inventory as a bolt dynamic plugin

## Description

The following shows how to use the [orbstack_bolt_inventory](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory) as a [bolt dynamic inventory plugin](https://www.puppet.com/docs/bolt/latest/writing_plugins.html#reference-plugins). The plugin supports two providers:

* `orbstack` for Orbstack VMs, which is the default
* `vmpooler` for VMPooler VMs

For more information see [How to create a basic dynamic inventory plugin](./how_to_create_a_basic_bolt_inventory_plugin.md).

## Pre-requisites

First, refer to the [Environment Setup Guide](how_to_setup_environment.md) and then configure [orbstack](https://docs.orbstack.dev) and [VMPooler](https://vmpooler.com/).

Finally, include the `orbstack_bolt_inventory` module in your `bolt-project.yaml` and install it:

```bash
# create a bolt-project.yaml that loads the 'orbstack_bolt_inventory' as a bolt plugin
cat << 'EOL' > bolt-project.yaml
---
name: usage
modules:
  - git: https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git
    ref: main
EOL

# install the new module
bolt module install
```

## Usage

### Orbstack Provider (Default)

The following will dynamically show all orbstack VMs:

```bash
# create a basic bolt inventory file that loads the plugin
cat << 'EOL' > inventory.yaml
version: 2
_plugin: orbstack_bolt_inventory
EOL

# output the inventory of orbstack VMs
bolt inventory show --targets=all
```

By adding a `group_patterns` section, then the bolt inventory will also include dynamic groups based on a regex pattern:

```bash
# update your bolt inventory to contain group/regex configuration, e.g.,
cat << 'EOL' > inventory.yaml
version: 2
_plugin: orbstack_bolt_inventory
group_patterns:
- group: agent
  regex: "^agent"
- group: compiler
  regex: "^compiler"
EOL

# show the machines in particular groups
bolt inventory show --targets=agent
bolt inventory show --targets=compiler
```

### VMPooler Provider

The following will dynamically show all orbstack VMs.  Two new groups have been added by default along with "all": "windows" and "linux".

```bash
# create a basic bolt inventory file that loads the plugin
cat << 'EOL' > inventory.yaml
version: 2
_plugin: orbstack_bolt_inventory
provider: vmpooler
EOL

# output the inventory of orbstack VMs
bolt inventory show --targets=all
bolt inventory show --targets=windows
bolt inventory show --targets=linux
```

By adding a `group_patterns` section, then the bolt inventory will also include dynamic groups based on a regex pattern.  For example, give a couple vmpooler VMs that begin with "tender" and "normal", then

```bash
# create a basic bolt inventory file that loads the plugin
cat << 'EOL' > inventory.yaml
version: 2
_plugin: orbstack_bolt_inventory
provider: vmpooler
group_patterns:
- group: agent
  pattern: "tender|normal"
EOL

bundle inventory show --targets=agent
```
