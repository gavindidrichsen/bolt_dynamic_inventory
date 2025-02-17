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
  - git: https://github.com/gavindidrichsen/bolt_dynamic_inventory.git
    ref: main
  - puppetlabs-motd
EOL

# install the modules
/opt/puppetlabs/bin/bolt module install

# configure dynamic groups 'agent' and 'compiler', which will also configure the 'facts.role` for each group
cat << 'EOL' > inventory.yaml
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
      content => "WELCOME!  I'm an [${facts['role']}]\n",
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

```bash
# run the plan injecting the 'role' fact
➜  motd git:(development) ✗ /opt/puppetlabs/bin/bolt plan run usage::sayhello --targets=all --verbose   

Starting: plan usage::sayhello
Starting: install puppet and gather facts on agent01, agent02, agent03, compiler01, compiler02
Finished: install puppet and gather facts with 0 failures in 18.31 sec
Starting: apply catalog on agent01, agent02, agent03, compiler01, compiler02
Started on agent01...
Started on compiler01...
Started on compiler02...
Started on agent03...
Started on agent02...
Finished on agent03:
  Notice: /Stage[main]/Motd/File[/etc/motd]/content: content changed '{sha256}be552f81523dafa5f25c08706bc113b38ee7e8a83d9cef7da9691e1bdcd161a5' to '{sha256}b780a8deba7b8bed7c62e15d62ce82710d1098e38267c862f2e2d4de75299dca'
  changed: 1, failed: 0, unchanged: 0 skipped: 0, noop: 0
Finished on agent01:
  Notice: /Stage[main]/Motd/File[/etc/motd]/content: content changed '{sha256}be552f81523dafa5f25c08706bc113b38ee7e8a83d9cef7da9691e1bdcd161a5' to '{sha256}b780a8deba7b8bed7c62e15d62ce82710d1098e38267c862f2e2d4de75299dca'
  changed: 1, failed: 0, unchanged: 0 skipped: 0, noop: 0
Finished on compiler01:
  Notice: /Stage[main]/Motd/File[/etc/motd]/content: content changed '{sha256}416f4f846bc7ad3289e8315772871a5a6525a1e227330f790510dce383d5864f' to '{sha256}850ebe36b81c3fe5279a5cf5f5a33db893ed9435d238f8f9636c53be7f97cc81'
  changed: 1, failed: 0, unchanged: 0 skipped: 0, noop: 0
Finished on compiler02:
  Notice: /Stage[main]/Motd/File[/etc/motd]/content: content changed '{sha256}416f4f846bc7ad3289e8315772871a5a6525a1e227330f790510dce383d5864f' to '{sha256}850ebe36b81c3fe5279a5cf5f5a33db893ed9435d238f8f9636c53be7f97cc81'
  changed: 1, failed: 0, unchanged: 0 skipped: 0, noop: 0
Finished on agent02:
  Notice: /Stage[main]/Motd/File[/etc/motd]/content: content changed '{sha256}be552f81523dafa5f25c08706bc113b38ee7e8a83d9cef7da9691e1bdcd161a5' to '{sha256}b780a8deba7b8bed7c62e15d62ce82710d1098e38267c862f2e2d4de75299dca'
  changed: 1, failed: 0, unchanged: 0 skipped: 0, noop: 0
Finished: apply catalog with 0 failures in 11.18 sec
Finished: plan usage::sayhello in 29.5 sec
Plan completed successfully with no result
➜  motd git:(development) ✗ 

# verify the expected content
➜  motd git:(development) ✗ /opt/puppetlabs/bin/bolt command run "cat /etc/motd" --targets=all --verbose
Started on agent01...
Started on agent03...
Started on compiler01...
Started on compiler02...
Started on agent02...
Finished on agent03:
  WELCOME!  I'm an [agent]
Finished on agent02:
  WELCOME!  I'm an [agent]
Finished on compiler01:
  WELCOME!  I'm an [compiler]
Finished on compiler02:
  WELCOME!  I'm an [compiler]
Finished on agent01:
  WELCOME!  I'm an [agent]
Successful on 5 targets: agent01,agent02,agent03,compiler01,compiler02
Ran on 5 targets in 1.85 sec
➜  motd git:(development) ✗ 
```
