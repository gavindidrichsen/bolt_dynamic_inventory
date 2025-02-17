# How to setup the environment

## Description

Before doing any of the included `how-to's`, some or all of the following must be setup depending on which provider you plan to use.

## Provider-Specific Setup

### Orbstack Provider

* Install [orbstack](https://docs.orbstack.dev)
* Create Ubuntu 22.04 amd64 orbstack machines with names like:
  * `agent01`
  * `agent02`
  * `agent03`
  * `compiler01`
  * `compiler02`

For more information on how to do the above from the command-line see [Create and Remove Orbstack VMs from the command-line](how_to_create_and_remove_orbstack_vms_from_cli.md).

### VMPooler Provider

Install and configure `floaty`:

```bash
gem install floaty

# Create floaty config
mkdir -p ~/.vmfloaty
cat << 'EOL' > ~/.vmfloaty/config.yml
url: https://vmpooler.delivery.puppetlabs.net/api/v1
user: your_username
token: your_token
EOL
```

Create a 'secrets' directory:

```bash
# Create SSH config directory for VMPooler
mkdir -p ~/.secrets/bolt/windows
```

Export the windows password as an environment variable making sure to inject the correct password for `<REPLACEME>`:

```bash
export WINDOWS_PASSWORD='<REPLACEME>'
```

Then either create an **SSH credential** file:

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

or a **winrm credential** file:

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
# Set appropriate permissions
chmod 600 ~/.secrets/bolt/windows/credentials.yaml
```

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

### Install rbenv and ruby

Install [rbenv](https://github.com/rbenv/rbenv), and then install a ruby version, e.g.,`rbenv install 3.2.5`

### Configure bundle

**NOTE**: If you already know how to configure bundler and have a preferred way of configuring your ruby environment, then skip this section.

Otherwise, isolate your ruby environment so that you don't accidentally corrupt your system.  One way to do this isolation is by setting the following envionment variables:

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

### Install the latest bolt and pdk

See installation guides for [bolt](https://www.puppet.com/docs/bolt/latest/bolt_installing) and for [pdk](https://www.puppet.com/docs/pdk/3.x/pdk_install).
