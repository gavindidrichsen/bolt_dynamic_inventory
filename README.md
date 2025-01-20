# OrbstackBoltInventory

A Bolt inventory generator for Orbstack containers.

## Description

This `orbstack_bolt_inventory` gem queries Orbstack for VMs and generates a Bolt inventory. It uses native SSH for connecting to the VMs and supports dynamic group creation based on target name patterns. It is modeled after the "Reference" plugins described in the bolt documentation [here](https://www.puppet.com/docs/bolt/latest/writing_plugins.html#reference-plugins).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'orbstack_bolt_inventory', git: 'https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git', branch: 'main'
```

And then execute:

```bash
bundle install
```

## Getting Started

To generate a basic inventory.yaml file for all your Orbstack containers:

```bash
bundle exec orby > inventory.yaml
```

This will create an inventory.yaml file in your current directory with all your Orbstack containers. For more information see [Sample outputs](#sample-outputs).

## How-to Guides

### Dynamic Groups

To generate an inventory with specific group patterns, pass in the `-g` flag followed by a comma-separated list of "GROUP:REGEX" definitions.  For example, the following will produce 2 bolt inventory groups `agents` and `compilers` as long as the regex patterns `agent*` and `compiler*` match existing orbstack VMs.

```bash
bundle exec orby -g "agents:agent*","compilers:compiler*"
```

The generated inventory.yaml can be used with Bolt for targeting specific groups of containers.  For more information see [Sample outputs](#sample-outputs).

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

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OrbstackBoltInventory project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory/blob/master/CODE_OF_CONDUCT.md).
