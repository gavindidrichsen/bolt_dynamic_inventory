# How to setup windows credentials for vmpooler

## Description

This guide explains how to setup the windows credentials file for vmpooler.  You can choose either `ssh` or `winrm`

## Context

The `bolt_dynamic_inventory` gem (or plugin) will produce an inventory something like that in the [appendix](#sample-vmpoller-bolt-inventory).  Notice in particular that the windows group contains a `config` section that references a "secrets" file `~/.secrets/bolt/windows/credentials.yaml`, e.g,

```yaml
groups:
- name: windows
  config:
    _plugin: yaml
    filepath: "~/.secrets/bolt/windows/credentials.yaml"
  facts:
    role: windows
```

Unless this credentials file is created an configured with valid credentials, bolt will not be able to connect to the vmpooler windows machines.

## Usage

Export the following environment variables making sure to replace `<WINDOWS_PASSWORD>`:

```bash
# export the actual windows password
export WINDOWS_PASSWORD=<WINDOWS_PASSWORD>

# create SSH config directory for the credential files
mkdir -p ~/.secrets/bolt/windows
```

The create the `~/.secrets/bolt/windows/credentials.yaml` to use either `ssh` or `winrm`.

To use `ssh`, then do the following:

```bash
# create an SSH windows credentials config file
cat << EOL > ~/.secrets/bolt/windows/credentials.yaml
---
# See <https://www.puppet.com/docs/bolt/latest/bolt_transports_reference.html#ssh>
transport: ssh
ssh:
  user: Administrator
  password: ${WINDOWS_PASSWORD}
  encryption-algorithms: 
    - aes128-ctr
    - aes192-ctr
    - aes256-ctr
    - aes128-gcm@openssh.com
    - aes256-gcm@openssh.com
    - chacha20-poly1305@openssh.com
  host-key-check: false
  ssl: false
EOL
```

To use `winrm` do the following:

```bash
cat << EOL > ~/.secrets/bolt/windows/credentials.yaml
---
# See <https://www.puppet.com/docs/bolt/latest/bolt_transports_reference.html#ssh>
transport: winrm
winrm:
  user: Administrator
  password: ${WINDOWS_PASSWORD}
  ssl: false
EOL
```

```bash
# run a simple command via bolt, e.g.,
/opt/puppetlabs/bin/bolt --verbose command run ipconfig --targets=all
```

## Appendix

### Sample vmpoller bolt inventory

```bash
➜  bolt_dynamic_inventory git:(development) ✗ bundle exec binv --provider=vmpooler                              
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
    _plugin: yaml
    filepath: "~/.secrets/bolt/windows/credentials.yaml"
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
➜  bolt_dynamic_inventory git:(development) ✗ 
```
