# How to use the orbstack_bolt_inventory as a gem

## Description

The following shows how to use the [orbstack_bolt_inventory](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory) as a gem.

## Pre-requisites

First, refer to the [Environment Setup Guide](how_to_setup_environment.md) and then accordingly configure [direnv](https://direnv.net), [rbenv](https://github.com/rbenv/rbenv), ruby, and [orbstack](https://docs.orbstack.dev).

Then setup your `Gemfile` to pull in the `orbstack_bolt_inventory` gem:

```bash
# ensure current environment is clean
rm -rf vendor Gemfile Gemfile.lock

# create a Gemfile that loads 'orbstack_bolt_inventory' as a gem
cat << 'EOL' > Gemfile
source 'https://rubygems.org'

gem 'orbstack_bolt_inventory', git: 'https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git', branch: 'main'
EOL

# install the gem and verify
bundle install
bundle info orbstack_bolt_inventory
```

## Usage

There are 2 ways to use the gem:

```bash
# Either produce a bolt inventory listing of all orbstack VMs
bundle exec orby

# Or produce an inventory with groups of targets based on a regex
bundle exec orby -g "NAME:REGEX,NAME2:REGEX2"
```

Refer to the sample output in appendix below.

## Appendix

### Sample output

* `bundle exec orby`:

```bash
➜  develop-the-bolt-dynamic-plugin git:(development) ✗ bundle exec orby
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
➜  develop-the-bolt-dynamic-plugin git:(development) ✗ 
```

* `bundle exec orby -g "agent:agen*,compiler:comp*"`

```bash
➜  dump git:(development) ✗ bundle exec orby -g "agent:agen*,compiler:comp*"
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
- name: nixos
  uri: nixos@orb
- name: sneaky-new-one
  uri: sneaky-new-one@orb
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
➜  dump git:(development) ✗ 
```
