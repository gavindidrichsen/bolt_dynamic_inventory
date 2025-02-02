# How to setup the environment

## Description

Before doing any of the included `how-to's`, some or all of the following must be setup.

### Install orbstack

* Install [orbstack](https://docs.orbstack.dev)
* Create 5 Ubuntu 22.04 amd64 orbstack machines with the following names.
  * `agent01`,
  * `agent02`,
  * `agent03`,
  * `compiler01`, and
  * `compiler02`

For more information on how to do the above from the command-line see [Create and Remove Orbstack VMs from the command-line](create_and_remove_orbstack_vms_from_cli.md).

### Install direnv

For more information see [direnv](https://direnv.net).  This is a useful tool to automatically set environment variables on entry to a directory and then to unset on.  For example:

Then create an `.envrc` file to configure the environment automatically via direnv:

```bash
# set the BOLT_GEM
cat << 'EOL' > .envrc
export HELLO=true
EOL

# 'allow' the environmental variables to be set and verify
direnv allow
echo "${HELLO}"
```

### Install rbenv configure ruby

* Install [rbenv](https://github.com/rbenv/rbenv), and
* Install a ruby version, e.g.,`rbenv install 3.2.5`
