# How to use the `role` fact

## Description

The following illustrates the `role` fact that is included in the dynamically generated bolt inventory.

One advantags of having this `role` fact is that bolt does not rely on puppet collecting this fact on any of the targets.  In other words, bolt can switch its workflow based on this fact on first execution

This document illustrates one useful way of using this fact.

## Pre-requisites

First, refer to the [Environment Setup Guide](how_to_setup_environment.md) and then accordingly configure [direnv](https://direnv.net) and [orbstack](https://docs.orbstack.dev). Also, ensure `bolt` is installed on your system e.g., `/opt/puppetlabs/bolt`.

## Usage

### Configure a bolt project that includes puppetlabs-motd

Now:

```bash
# create a bolt-project.yaml that loads the 'bolt_dynamic_inventory' and 'puppetlabs-motd' modules
cat << 'EOL' > bolt-project.yaml
---
name: usage
modules:
  - git: https://github.com/gavindidrichsen-puppetlabs/bolt_dynamic_inventory.git
    ref: main
  - puppetlabs-motd
EOL

# install the modules
/opt/puppetlabs/bin/bolt module install

# configure dynamic groups 'agent' and 'compiler', which will also configure the 'facts.role` for each group
cat << 'EOL' > inventory .yaml
version: 2
_plugin: bolt_dynamic_inventory
provider: orbstack
group_patterns:
- group: agent
  regex: "^agent"
- group: compiler
  regex: "^compiler"
EOL
```

## Create a plan that exercises the new 'role' fact

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

# run a command: verify that the '/etc/motd' contains the expected content
/opt/puppetlabs/bin/bolt command run "cat /etc/motd" --targets=all --verbose
```

See sample output in the [appendix](#sample-output).

## Appendix

### Sample output

The following is an example of a bolt inventory group.  Notice that the `name` of the group and the `facts.role` are the same value.

```yaml
groups:
- name: agent
  facts:
    role: agent
  targets:
  - agent01
  - agent02
  - agent03
```

The above group sits within the context of a valid bolt inventory something like the following:

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
