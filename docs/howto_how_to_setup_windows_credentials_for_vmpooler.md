# How to setup windows credentials for vmpooler

## Description

This guide explains how to setup Windows credentials for vmpooler using an environment variable.

## Context

For bolt to connect to a vmpooler windows server over `winrm`, the `inventory.yaml` must include configuration similar to the following:

```yaml
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
```

As long as the `VMPOOLER_WINDOWS_PASSWORD` environment variable is set to a valid password, then bolt will connect to the windows server(s). For more information, see the sample `inventory.yaml` produced by the `bolt_dynamic_inventory` gem in the [appendix](#sample-vmpoller-bolt-inventory).

## Usage

Export the following environment variable, making sure to replace `<WINDOWS_PASSWORD>` with your actual Windows password:

```bash
export VMPOOLER_WINDOWS_PASSWORD=<WINDOWS_PASSWORD>

# output a vmpooler inventory file
bundle exec binv --provider=vmpooler

# run a simple command via bolt, e.g.,
/opt/puppetlabs/bin/bolt command run ipconfig --verbose --inventoryfile=<(bundle exec binv --provider=vmpooler) --targets=windows
```

## Appendix

### Sample vmpoller bolt inventory

```bash
➜  bolt_dynamic_inventory git:(development) ✗ bundle exec binv --provider=vmpooler
---
targets:
- name: onetime-algebra.delivery.puppetlabs.net
  alias: onetime-algebra
  uri: onetime-algebra.delivery.puppetlabs.net
- name: stiff-boulevard.delivery.puppetlabs.net
  alias: stiff-boulevard
  uri: stiff-boulevard.delivery.puppetlabs.net
- name: tender-punditry.delivery.puppetlabs.net
  alias: tender-punditry
  uri: tender-punditry.delivery.puppetlabs.net
- name: normal-meddling.delivery.puppetlabs.net
  alias: normal-meddling
  uri: normal-meddling.delivery.puppetlabs.net
- name: unimposing-poll.delivery.puppetlabs.net
  alias: unimposing-poll
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
  - onetime-algebra.delivery.puppetlabs.net
  - stiff-boulevard.delivery.puppetlabs.net
  - unimposing-poll.delivery.puppetlabs.net
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
  - tender-punditry.delivery.puppetlabs.net
  - normal-meddling.delivery.puppetlabs.net
➜  bolt_dynamic_inventory git:(development) ✗
```
