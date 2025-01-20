# OrbstackBoltInventory

A Bolt inventory generator for Orbstack VMs.

## Description

This `orbstack_bolt_inventory` gem queries Orbstack and generates a Bolt inventory.  It also contains 2 "skins" or presentations of the output:

* `orby`, a command-line executable, outputs the bolt inventory to stdout.  
* `orbstack_bolt_inventory`  as a [bolt dynamic inventory plugin](https://www.puppet.com/docs/bolt/latest/writing_plugins.html#reference-plugins).

## Getting Started

### Using `orbstack_bolt_inventory` as a gem

* add the following to your Gemfile:

```ruby
gem 'orbstack_bolt_inventory', git: 'https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git', branch: 'main'
```

* generate an `inventory.yaml`

```bash
# either
bundle exec orby
# or
bundle exec orby > inventory.yaml
```

For more information see [Sample outputs](#sample-outputs).

### Using `orbstack_bolt_inventory` as a bolt dynamic inventory plugin

* add the `orbstack_bolt_inventory` module to your `bolt-project.yaml`, something like:

```yaml
  # bolt-project.yaml
  ---
  name: bigbird
  modules:
    - git: https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git
      ref: main
```

* create a basic `inventory.yaml` at the root of your bolt project:

```yaml
# inventory.yaml
version: 2
_plugin: orbstack_bolt_inventory
```

* verify your inventory

```bash
bolt inventory show
```

## How-to Guides

### How to create dynamic inventory groups

#### On the command-line

To generate an inventory with specific group patterns, pass in the `-g` flag followed by a comma-separated list of `"GROUP:REGEX"` definitions.  For example, generate an `inventory.yaml` that includes 2 dynamic groups `agents` and `compilers`:

```bash
bundle exec orby -g "agents:agent*","compilers:compiler*"
```

For more information see [Sample outputs](#sample-outputs).

#### Within the `inventory.yaml`

To dynamically create groups based on target name patterns, add a `group_patterns` section to your `inventory.yaml`.  For example, the following will create 2 groups "agents" and "compilers" if VMs exist matching these patterns:

```yaml
version: 2
_plugin: orbstack_inventory
group_patterns:  # Optional: define groups based on target name patterns
  - group: agents
    regex: "^agent"
  - group: compilers
    regex: "^compiler"
```

Verify the groups:

```bash
bolt group show
bolt command run "hostname" --targets=agents
bolt command run "hostname" --targets=compilers
```

## Explanations

### Sample outputs

Given the following orbstack VMs:

```bash
➜  tester git:(development) orb list
NAME        STATE    DISTRO  VERSION  ARCH
----        -----    ------  -------  ----
agent01     running  ubuntu  jammy    amd64
agent02     running  ubuntu  jammy    amd64
agent99     running  ubuntu  jammy    amd64
compiler01  running  ubuntu  jammy    amd64
compiler02  running  ubuntu  jammy    amd64
➜  tester git:(development) 
```

Then a basic bolt `inventory.yaml` can be created as follows:

```bash
➜  tester git:(development) bundle exec orby
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
- name: agent99
  uri: agent99@orb
- name: compiler01
  uri: compiler01@orb
- name: compiler02
  uri: compiler02@orb
➜  tester git:(development) 
```

Further, an inventory with dynamic inventory groups can be created as follows:

```bash
➜  tester git:(development) bundle exec orby -g "agents:agent*","compilers:compiler*"
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
- name: agent99
  uri: agent99@orb
- name: compiler01
  uri: compiler01@orb
- name: compiler02
  uri: compiler02@orb
groups:
- name: agents
  targets:
  - agent01
  - agent02
  - agent99
- name: compilers
  targets:
  - compiler01
  - compiler02
➜  tester git:(development)
```

### Design Decisions

<!-- adrlog -->

* [ADR-0001](doc/adr/0001-extend-this-gem-to-be-a-bolt-inventory-dynamic-plugin-also.md) - Extend this gem to be a bolt inventory dynamic plugin also
* [ADR-0002](doc/adr/0002-configure-bolt-inventory-with-native-ssh-to-keep-things-simple.md) - Configure bolt inventory with native ssh to keep things simple
* [ADR-0003](doc/adr/0003-gather-inventory-metadata-via-the-orb-cli-to-keep-things-simple.md) - Gather inventory metadata via the 'orb' cli to keep things simple
* [ADR-0004](doc/adr/0004-create-dynamic-inventory-groups-based-on-hostname-regex-patterns.md) - Create dynamic inventory groups based on hostname regex patterns

<!-- adrlogstop -->

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OrbstackBoltInventory project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory/blob/master/CODE_OF_CONDUCT.md).
