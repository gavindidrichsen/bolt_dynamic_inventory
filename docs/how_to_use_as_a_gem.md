# How to use as a gem

## Description

The following shows how to use the [bolt_dynamic_inventory](https://github.com/gavindidrichsen/bolt_dynamic_inventory) as a gem to generate a bolt inventory for multiple providers, including `orbstack` and `vmpooler`.

## Prerequisites

For VMPooler provider, ensure `nmap` is installed on your system for VM connectivity filtering:

**macOS:** `brew install nmap`  
**Ubuntu/Debian:** `sudo apt-get install nmap`  
**RHEL/CentOS:** `sudo yum install nmap` or `sudo dnf install nmap`

## Usage

### Install system wide as a gem

```bash
git clone https://github.com/gavindidrichsen/bolt_dynamic_inventory.git
cd bolt_dynamic_inventory
gem build bolt_dynamic_inventory.gemspec
gem install *.gem
rbenv rehash
rbenv which binv
```

### Generate inventories

```bash
# List orbstack VMs (defaults to "--provider=orbstack")
binv                                                                # list all VMs
binv --groups "agent:^agent,compiler:^compiler"                     # add custom regex groups

# List vmpooler VMs (automatically filters out destroyed/unreachable VMs)
binv --provider=vmpooler                                            # list all VMs grouping windows and linux
binv --provider=vmpooler --groups "agent:tender|normal"             # add custom regex groups

# verify the inventory dynamically
bolt --inventoryfile=<(binv) inventory show

# verify a simple command across your VMs, e.g.,
bolt command run "hostname" --inventoryfile=<(binv) --targets=all
```

**COOL TIP**: Create a simple dynamic inventory with an alias, e.g.,

If you've added the `bundle_dynamic_inventory` to your system viat a `gem install bundle_dynamic_inventory...`, then your should be able to use the `binv` command anywhere on your system.  For example, I created the following aliases so that I could quickly run bolt commands against either vmpooler or orbstack:

```bash
# create an alias that always runs the inventory
alias boldv='bolt --inventoryfile=<(binv --provider=vmpooler)'
alias boldo='bolt --inventoryfile=<(binv)'

# run any bolt command with bold...
boldo command run "hostname" --targets=all
```

## Appendix

### Install with bundler

Refer to the [Environment Setup Guide](how_to_setup_environment.md) and then configure [direnv](https://direnv.net), [rbenv](https://github.com/rbenv/rbenv), ruby, [orbstack](https://docs.orbstack.dev), and [vmpooler](https://github.com/puppetlabs/vmpooler/tree/main).

If you are going to be using the vmpooler provider, you will need to also follow [How to setup windows credentials for vmpooler](how_to_setup_windows_credentials_for_vmpooler.md)

If you wish to install this gem system-wide, then see [Install system wide as a gem](#install-system-wide-as-a-gem); otherwise continue on to install with bundler.

First, setup your `Gemfile` to pull in the `bolt_dynamic_inventory` gem:

```bash
# ensure current environment is clean
rm -rf vendor Gemfile Gemfile.lock

# create a Gemfile that loads 'bolt_dynamic_inventory' as a gem
cat << 'EOL' > Gemfile
source 'https://rubygems.org'

gem 'bolt_dynamic_inventory', git: 'https://github.com/gavindidrichsen/bolt_dynamic_inventory.git', branch: 'main'
EOL

# install the gem and verify
bundle install
```

### Sample output

Orbstack output:

```bash
➜  develop-the-bolt-dynamic-plugin git:(development) ✗ bundle exec binv --provider=orbstack 
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

* `bundle exec binv --groups "agent:agen*,compiler:comp*"`

```bash
➜  dump git:(development) ✗ bundle exec binv --provider=orbstack --groups "agent:agen*,compiler:comp*"
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

Vmpooler output:

```bash
➜  bolt_dynamic_inventory git:(development) ✗ bundle exec binv --provider=vmpooler --groups "agent:tender|normal"
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
    transport: winrm
    winrm:
      user: Administrator
      password:
        _plugin: env_var
        var: VMPOOLER_WINDOWS_PASSWORD
      ssl: false
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
➜  bolt_dynamic_inventory git:(development) ✗ 
```
