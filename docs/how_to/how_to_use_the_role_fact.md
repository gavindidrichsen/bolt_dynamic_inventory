# How to use the `role` fact

## Description

The following shows how to use the `role` fact which is a feature of the [orbstack_bolt_inventory](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory) plugin.

The following is an example `inventory.yaml` with 2 groups of targets `agent` and `compiler`.  Notice:

* Each group contains not only a list of `targets` but also a special `facts`.  
* The `role` fact is the same value as the `group`.

```bash
➜  adding_facts git:(development) orby -g "agent:agent0*,compiler:compil*"
---
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
- name: agent02
  uri: agent02@orb
- name: agent03
  uri: agent03@orb
- name: compiler01
  uri: compiler01@orb
- name: compiler02
  uri: compiler02@orb
groups:
- name: agent
  facts:
    role: agent
  targets:
  - agent01
  - agent02
  - agent03
- name: compiler
  facts:
    role: compiler
  targets:
  - compiler01
  - compiler02
➜  adding_facts git:(development) 
```

## Pre-requisites

First, refer to the [Environment Setup Guide](how_to_setup_environment.md) and then accordingly configure [direnv](https://direnv.net) and [orbstack](https://docs.orbstack.dev). Also, ensure `bolt` is installed on your system e.g., `/opt/puppetlabs/bolt`.

Finally, include the following modules in your `bolt-project.yaml`:

* `orbstack_bolt_inventory`
* `puppetlabs-motd`, which configures the message for today

```bash
# create a bolt-project.yaml that loads the 'orbstack_bolt_inventory' as a bolt plugin
cat << 'EOL' > bolt-project.yaml
---
name: usage
modules:
  - git: https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git
    ref: main
  - puppetlabs-motd
EOL

# install the new module
/opt/puppetlabs/bin/bolt module install

# configure dynamic groups 'agent' and 'compiler'; each target will also have it's own 'role' fact, in other words
# agent01 will have a $facts.role = 'agent'
cat << 'EOL' > inventory .yaml
version: 2
_plugin: orbstack_bolt_inventory
group_patterns:
- group: agent
  regex: "^agent"
- group: compiler
  regex: "^compiler"
EOL
```

## Scenario 1: Basic Use

Run the `class { 'motd': ... }` against will add a new `/etc/motd` containing the `$facts.role` for each target

```bash
# create a new `usage::sayhello` plan
mkdir -p plans
cat << 'EOL' > plans/sayhello.pp
plan usage::sayhello (
  TargetSpec $targets = 'localhost'
) {
  apply_prep($targets)
  apply($targets) {
    class { 'motd':
      content => "WELCOME!  I'm an [${facts['role']}\n",
    }
  }
}
EOL

# run the plan
/opt/puppetlabs/bin/bolt plan run usage::sayhello --targets=all --verbose

/opt/puppetlabs/bin/bolt command run "cat /etc/motd" --targets=all --verbose
```

See sample output in [Scenario 1 Output](#scenario-1-output).

## Scenario 2: Configuring Regex Groups

Configure bolt to dynamically configure bolt inventory groups based on regex patterns:

```bash
# clean-up any existing setup
rm -f inventory.yaml

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
bundle exec bolt inventory show --targets=agent
bundle exec bolt inventory show --targets=compiler
```

See sample output in [Scenario 2 Output](#scenario-2-output).

## Clean up

Remove the orbstack VMs either manually or via command-line.  For more information see [Create and Remove Orbstack VMs from the command-line](how_to_create_and_remove_orbstack_vms_from_cli.md).

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
  /Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/docs/develop-the-bolt-dynamic-plugin/inventory.yaml

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
➜  developing_the_plugin git:(development) ✗ bundle exec bolt inventory show --targets=agent
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
➜  developing_the_plugin git:(development) ✗ bundle exec bolt inventory show --targets=compiler
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
