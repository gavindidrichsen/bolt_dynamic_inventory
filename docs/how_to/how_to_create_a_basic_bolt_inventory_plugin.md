# How to create a basic dynamic inventory plugin

## Description

The following shows how to create a bare-bones bolt inventory plugin with only 5 files:

* `bolt-project.yaml​`
* `inventory.yaml​`
* `modules/basic_plugin/bolt-plugin.json​`
* `modules/basic_plugin/tasks/resolve_reference.json​`
* `modules/basic_plugin/tasks/resolve_reference.rb`

## Pre-requisites

First, refer to the [Environment Setup Guide](how_to_setup_environment.md) and then accordingly configure [orbstack](https://docs.orbstack.dev).

## Usage

Create `bolt-project.yaml​` to initialize a new bolt project:

```bash
# create a new directory
mkdir my_plugin
cd my_plugin

# initialize this as a bolt project
cat << 'EOL' > bolt-project.yaml
---
name: usage
modules: []
EOL

# verify bolt is working as expected
bolt command run "hostname" --targets=localhost
```

Create `inventory.yaml​` pointing to your (non-existant) `basic_plugin`:

```bash
# create an inventory.yaml referencing the "basic_plugin"
cat << 'EOL' > inventory.yaml
version: 2
_plugin: basic_plugin
EOL

# the following should fail because no plugin yet!
bolt inventory show
```

Create the `modules/basic_plugin/bolt-plugin.json​` metadata file:

```bash
# create the 'basic_plugin' module directory
mkdir -p modules/basic_plugin

# initialize this as a bolt "plugin"
cat << 'EOL' > modules/basic_plugin/bolt_plugin.json
{
  "name": "basic_plugin",
  "version": "0.1.0",
  "description": "A Bolt dynamic inventory plugin for Orbstack VMs",
  "tasks": {
    "resolve_reference": "tasks/resolve_reference.rb"
  }
}
EOL
```

Create the `resolve_reference` task required by the plugin.  In other words,

* create the `modules/basic_plugin/tasks/resolve_reference.json​` task metadata.
* create the `modules/basic_plugin/tasks/resolve_reference.rb` with hardcoded bolt inventory yaml for simplicity.

```bash
# create the 'resolve_reference' task
mkdir -p modules/basic_plugin/tasks

# first, the metadata:
cat << 'EOL' > modules/basic_plugin/tasks/resolve_reference.json
{
  "description": "Resolve targets for Orbstack inventory",
  "input_method": "stdin",
  "parameters": {}
}
EOL

# second, the resolve_referenc.rb
cat << 'EOL' > modules/basic_plugin/tasks/resolve_reference.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'

# load STDIN and 'magic' variables like '_boltdir'
input = JSON.parse(STDIN.read)
inventory_file = File.join(input['_boltdir'], 'modules', 'basic_plugin', 'tasks', 'inventory.yaml')

# Load inventory from YAML file
yaml_data = File.read(inventory_file)
hash = YAML.load(yaml_data)

# wrap in 'value' key as expected by Bolt plugins
result = { 'value' => hash }
puts result.to_json
EOL

# third, the raw inventory yaml
cat << 'EOL' > modules/basic_plugin/tasks/inventory.yaml
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
EOL
```

```bash
bolt inventory show
bolt command run "hostname" --targets=all
bolt command run "hostname" --targets=agent
```

## Appendix

### Basic Use Output

```bash
➜  my_plugin git:(development) bolt inventory show
Targets
  agent01
  agent02
  agent03
  compiler01
  compiler02

Inventory source
  /Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/repositories/gavindidrichsen/control-repo/site-modules/bigbird/dump/my_plugin/inventory.yaml

Target count
  5 total, 5 from inventory, 0 adhoc

Additional information
  Use the '--targets', '--query', or '--rerun' option to view specific targets
  Use the '--detail' option to view target configuration and data
➜  my_plugin git:(development) bolt command run "hostname" --targets=all
Started on agent01...
Started on agent03...
Started on compiler02...
Started on compiler01...
Started on agent02...
Finished on agent02:
  agent02
Finished on compiler01:
  compiler01
Finished on agent03:
  agent03
Finished on compiler02:
  compiler02
Finished on agent01:
  agent01
Successful on 5 targets: agent01,agent02,agent03,compiler01,compiler02
Ran on 5 targets in 11.03 sec
➜  my_plugin git:(development) 
```
