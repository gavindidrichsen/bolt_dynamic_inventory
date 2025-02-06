# How to use the orbstack_bolt_inventory as a bolt dynamic plugin

## Description

The following shows how to use the [orbstack_bolt_inventory](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory) as a bolt dynamic inventory plugin.

## Pre-requisites

First, refer to the [Environment Setup Guide](setup_environment.md) and then accordingly configure [orbstack](https://docs.orbstack.dev).

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

## Scenario 1: Basic Use

Configure bolt to dynamically show all orbstack VMs:

```bash
# create a basic bolt inventory file that loads the plugin
cat << 'EOL' > inventory.yaml
version: 2
_plugin: orbstack_bolt_inventory
EOL

# output the inventory of orbstack VMs
bolt inventory show --targets=all
```

See sample output in [Scenario 1 Output](#scenario-1-output).

## Scenario 2: Configuring Regex Groups

Configure bolt to dynamically configure bolt inventory groups based on regex patterns:

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

See sample output in [Scenario 2 Output](#scenario-2-output).

## Clean up

Remove the orbstack VMs either manually or via command-line.  For more information see [Create and Remove Orbstack VMs from the command-line](create_and_remove_orbstack_vms_from_cli.md).

## Appendix

### Scenario 1 Output

```bash
# verify the plugin
➜  develop-the-bolt-dynamic-plugin git:(development) ✗ bundle exec bolt inventory show
Targets
  agent01
  agent02
  agent03
  compiler01
  compiler02

Inventory source
  /Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/docs/how-to/develop-the-bolt-dynamic-plugin/inventory.yaml

Target count
  5 total, 5 from inventory, 0 adhoc

Additional information
  Use the '--targets', '--query', or '--rerun' option to view specific targets
  Use the '--detail' option to view target configuration and data
➜  develop-the-bolt-dynamic-plugin git:(development) ✗ 
```

### Scenario 2 Output

The output above should contain the following group listing:

```bash
➜  developing_the_plugin git:(development) ✗ bolt inventory show --targets=agent
Targets
  agent01
  agent02
  agent03
...
...
Target count
  3 total, 3 from inventory, 0 adhoc

Additional information
  Use the '--detail' option to view target configuration and data
➜  developing_the_plugin git:(development) ✗ bolt inventory show --targets=compiler
Targets
  compiler01
  compiler02
...
...
Target count
  2 total, 2 from inventory, 0 adhoc

Additional information
  Use the '--detail' option to view target configuration and data
➜  developing_the_plugin git:(development) ✗ 
```
