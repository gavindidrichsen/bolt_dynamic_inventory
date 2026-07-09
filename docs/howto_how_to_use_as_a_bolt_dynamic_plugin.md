# How to use as a bolt dynamic plugin

## Description

The following shows how to use the [bolt_dynamic_inventory](https://github.com/gavindidrichsen/bolt_dynamic_inventory) as a [bolt dynamic inventory plugin](https://www.puppet.com/docs/bolt/latest/writing_plugins.html#reference-plugins) for multiple providers, including orbstack and vmpooler.

For more information see [How to create a basic dynamic inventory plugin](./how_to_create_a_basic_bolt_inventory_plugin.md).

## Pre-requisites

First, refer to the [Environment Setup Guide](how_to_setup_environment.md) and then configure [orbstack](https://docs.orbstack.dev) and [VMPooler](https://vmpooler.com/).

**Important for VMPooler users:** Ensure `nmap` is installed on your system for VM connectivity filtering (see Environment Setup Guide for installation instructions).

If you are going to be using the vmpooler provider, you will need to also follow [How to setup windows credentials for vmpooler](how_to_setup_windows_credentials_for_vmpooler.md)

## Usage

First, include the `bolt_dynamic_inventory` module in your `bolt-project.yaml` and install it:

```bash
# create a bolt-project.yaml that loads the 'bolt_dynamic_inventory' as a bolt plugin
cat << 'EOL' > bolt-project.yaml
---
name: usage
modules:
  - git: https://github.com/gavindidrichsen/bolt_dynamic_inventory.git
    ref: main
EOL

# install the new module
bolt module install
```

Then create an inventory file according to the following sections.

### Orbstack Provider (Default)

The following will dynamically show all orbstack VMs:

```bash
# create a basic bolt inventory file that loads the plugin
cat << 'EOL' > inventory.yaml
version: 2
_plugin: bolt_dynamic_inventory
provider: orbstack
EOL

# output the inventory of orbstack VMs
bolt inventory show --targets=all
```

By adding a `group_patterns` section, then the bolt inventory will also include dynamic groups based on a regex pattern:

```bash
# update your bolt inventory to contain group/regex configuration, e.g.,
cat << 'EOL' > inventory.yaml
version: 2
_plugin: bolt_dynamic_inventory
provider: orbstack
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

The following will dynamically show all vmpooler VMs and in addition create 2 default groups: "windows" and "linux".

```bash
# create a basic bolt inventory file that loads the plugin
cat << 'EOL' > inventory.yaml
version: 2
_plugin: bolt_dynamic_inventory
provider: vmpooler
EOL

# output the inventory of vmpooler VMs
bolt inventory show --targets=all
bolt inventory show --targets=windows
bolt inventory show --targets=linux
```

By adding a `group_patterns` section, then the bolt inventory will also include dynamic groups based on a regex pattern.  For example, given a couple vmpooler VMs that begin with "tender" and "normal", then the following will include them in a new group called `agent`:

```bash
# create a basic bolt inventory file that loads the plugin
cat << 'EOL' > inventory.yaml
version: 2
_plugin: bolt_dynamic_inventory
provider: vmpooler
group_patterns:
- group: agent
  pattern: "(tender|normal)"
EOL

bolt inventory show --targets=agent
```
