# How to setup a basic dynamic inventory plugin

## Description

The following shows how to create a bare-bones bolt inventory plugin.  The inventory is hardcoded in this example but could just as easily proxy out to something else to generate the required inventory.

## Pre-requisites

First, refer to the [Environment Setup Guide](setup_environment.md) and then accordingly configure [orbstack](https://docs.orbstack.dev).

## Basic Use

Initialize a new bolt project:

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

Create an inventory file pointing to your (non-existant) `basic_plugin`:

```bash
# create an inventory.yaml referencing the "basic_plugin"
cat << 'EOL' > inventory.yaml
version: 2
_plugin: basic_plugin
EOL

# the following should fail because no plugin yet!
bolt inventory show
```

Create the `bolt_plugin.json` metadata file:

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

* create `resolve_reference.json`, which is the task metadata.
* create `resolve_reference.rb` hardcoding valid yaml inventory content. 

```bash
# create the 'resolve_reference' task
mkdir -p modules/basic_plugin/tasks

# first the metadata:
cat << 'EOL' > modules/basic_plugin/tasks/resolve_reference.json
{
  "description": "Resolve targets for Orbstack inventory",
  "input_method": "stdin",
  "parameters": {}
}
EOL

# then the resolve_referenc.rb
cat << 'EOL' > modules/basic_plugin/tasks/resolve_reference.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'

# Load inventory.yaml
yaml_data = """
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
"""

# convert YAML to a Ruby hash
hash = YAML.load(yaml_data)

# wrap in 'value' key as expected by Bolt pluginis
result = { 'value' => hash }
puts result.to_json
EOL
```

Validate the new plugin

```bash
bolt inventory show
bolt command run "hostname" --targets=all
```

## Appendix

### Basic Use Output

```bash
  dump git:(development) mkdir my_plugin
cd my_plugin

➜  my_plugin git:(development) cat << 'EOL' > bolt-project.yaml
---
name: usage
modules: []
EOL


➜  my_plugin git:(development) bolt command run "hostname" --targets=localhost
Started on localhost...
Finished on localhost:
  EMEA-Didrichsen
Successful on 1 target: localhost
Ran on 1 target in 0.02 sec


➜  my_plugin git:(development) cat << 'EOL' > inventory.yaml
version: 2
_plugin: basic_plugin
EOL


➜  my_plugin git:(development) bolt inventory show
Unknown plugin: 'basic_plugin'



➜  my_plugin git:(development) mkdir -p modules/basic_plugin
➜  my_plugin git:(development) cat << 'EOL' > modules/basic_plugin/bolt_plugin.json
{
  "name": "basic_plugin",
  "version": "0.1.0",
  "description": "A Bolt dynamic inventory plugin for Orbstack VMs",
  "tasks": {
    "resolve_reference": "tasks/resolve_reference.rb"
  }
}
EOL
➜  my_plugin git:(development) mkdir -p modules/basic_plugin/tasks


➜  my_plugin git:(development) cat << 'EOL' > modules/basic_plugin/tasks/resolve_reference.json
{
  "description": "Resolve targets for Orbstack inventory",
  "input_method": "stdin",
  "parameters": {}
}
EOL
...
...
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
