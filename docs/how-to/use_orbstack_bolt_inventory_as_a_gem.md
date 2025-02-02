# How to use the orbstack_bolt_inventory as a gem

## Description

The following shows how to use the [orbstack_bolt_inventory](https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory) as a gem.

## Pre-requisites

First, refer to the [Environment Setup Guide](setup_environment.md) and then accordingly configure [direnv](https://direnv.net), [rbenv](https://github.com/rbenv/rbenv), ruby, and [orbstack](https://docs.orbstack.dev).

Second, isolate your ruby environment so that you don't accidentally corrupt your system.  One way to do this is to set the `BUNDLE_*`, `GEM_*`, and `GEMRC` environment variables as below; this keeps all gem installation local to the current working directory.

```bash
# isolate the ruby environment by setting the following environment variables for bundle and gem installations
cat << 'EOL' > .envrc
# Configure Bundler paths  
export BUNDLE_PATH="${PWD}/vendor/bundle"           # Store gems locally  
export BUNDLE_GEMFILE="${PWD}/Gemfile"              # Use project-specific Gemfile  
export BUNDLE_BIN="${PWD}/vendor/bin"               # Store installed binaries  

# Configure RubyGems paths  
export GEM_HOME="${PWD}/vendor/gems"                # Local gem installation directory  
export GEM_PATH="${PWD}/vendor/gems"                # Lookup path for gems  
export GEMRC="${PWD}/.gemrc"                        # Custom gem configuration  

# Update PATH to include local binaries  
export PATH="${BUNDLE_BIN}:${GEM_HOME}/bin:$PATH"   # Ensure executables are found  

# Suppress Bolt gem installation warning  
export BOLT_GEM=true                                # Acknowledge Bolt is installed as a gem  

EOL

# 'allow' the environmental variables to be set and verify
direnv allow
echo "${BUNDLE_GEMFILE}"
```

Finally, setup your `Gemfile` to pull in the `orbstack_bolt_inventory` plugin:

```bash
# ensure current environment is clean
rm -rf vendor Gemfile Gemfile.lock

# create a Gemfile that loads 'orbstack_bolt_inventory' as a gem
cat << 'EOL' > Gemfile
source 'https://rubygems.org'

gem 'orbstack_bolt_inventory', git: 'https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git', branch: 'main'
gem "bolt", "~> 4.0"
EOL

# install the gem and verify
bundle install
bundle info orbstack_bolt_inventory
```

## Scenario 1: Basic Use

Output to stdout the bolt inventory for all orbstack VMs.

```bash
# use the gem executable to output to stout a working orbstack inventory
bundle exec orby
```

See sample output in [Scenario 1 Output](#scenario-1-output).

## Scenario 2: Configuring Regix Groups

Output to stdout the bolt inventory for all orbstack VMs and include dynamic groups based on regex patterns:  `bundle exec orby -g "NAME:REGEX,NAME2:REGEX2"`.  

For example:

```bash
# generate an inventory with 2 regex groups
bundle exec orby -g "agent:agent0*,compiler:compiler0*"
```

See sample output in [Scenario 2 Output](#scenario-2-output).

## Clean up

Remove the orbstack VMs either manually or via command-line.  For more information see [Create and Remove Orbstack VMs from the command-line](create_and_remove_orbstack_vms_from_cli.md).

## Appendix

### Scenario 1 Output

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

### Scenario 2 Output

The output above should contain the following group listing:

```bash
➜  developing_the_plugin git:(development) ✗ bundle exec orby -g "agent:agen*,compiler:comp*"
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
  targets:
  - agent01
  - agent02
  - agent03
- name: compiler
  targets:
  - compiler01
  - compiler02
➜  developing_the_plugin git:(development) ✗
```
