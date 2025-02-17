# How to use the orbstack_bolt_inventory as a gem

## Description

The following shows how to use the [orbstack_bolt_inventory](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory) as a gem. The gem supports two providers:

* `orbstack` for Orbstack VMs, which is the default
* `vmpooler` for VMPooler VMs

## Pre-requisites

Refer to 
1. For Orbstack provider:
   * Refer to the [Environment Setup Guide](how_to_setup_environment.md)
   * Configure [direnv](https://direnv.net), [rbenv](https://github.com/rbenv/rbenv), ruby, and [orbstack](https://docs.orbstack.dev)

2. For VMPooler provider:
   * Ensure `floaty` is installed and configured
   * Configure SSH access to VMPooler VMs

3. Setup your `Gemfile` to pull in the `orbstack_bolt_inventory` gem:

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

### Orbstack Provider (Default)

```bash
# List all Orbstack VMs
bundle exec orby

# Create groups based on regex patterns
bundle exec orby -g "agent:^agent,compiler:^compiler"
```

### VMPooler Provider

```bash
# List all VMPooler VMs (automatically groups into windows/linux)
bundle exec orby --provider=vmpooler

# Create additional groups based on regex patterns
bundle exec orby --provider=vmpooler -g "agent:tender|normal"
```

## Sample Output

### Orbstack Provider

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
  - tender-punditry
  - normal-meddling
```

### VMPooler Provider

```bash
➜  orbstack_bolt_inventory git:(development) ✗ bundle exec orby --provider=vmpooler -g "agent:tender|normal"
---
targets:
- name: onetime-algebra
  uri: onetime-algebra.delivery.puppetlabs.net
- name: stiff-boulevard
  uri: stiff-boulevard.delivery.puppetlabs.net
- name: tender-punditry
  uri: tender-punditry.delivery.puppetlabs.net
- name: normal-meddling
  uri: normal-meddling.delivery.puppetlabs.net
- name: unimposing-poll
  uri: unimposing-poll.delivery.puppetlabs.net
groups:
- name: windows
  config:
    transport: ssh
    ssh:
      _plugin: yaml
      filepath: "~/.secrets/bolt/windows/ssh/vmpooler/windows_credentials.yaml"
  facts:
    role: windows
  targets:
  - onetime-algebra
  - stiff-boulevard
  - unimposing-poll
- name: linux
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
  facts:
    role: linux
  targets:
  - tender-punditry
  - normal-meddling
- name: agent
  facts:
    role: agent
  targets:
  - tender-punditry
  - normal-meddling
➜  orbstack_bolt_inventory git:(development) ✗ 
```
