# How to Develop the Orbstack Inventory Module

This guide explains how to verify and test both the Puppet module and the Ruby gem components of the Orbstack inventory plugin.

## Prerequisites

- Ruby (version specified in `.ruby-version`)
- Bundler
- Puppet Development Kit (PDK)
- Orbstack installed and running

## Verifying the Puppet Module

1. Change to the module directory:

   ```bash
   cd modules/orbstack_bolt_inventory
   ```

2. Run PDK validation:

   ```bash
   pdk validate
   ```

3. Run unit tests:

   ```bash
   pdk test unit
   ```

4. Run acceptance tests (if available):

   ```bash
   pdk test acceptance
   ```

## Verifying the Ruby Gem

1. Change to the gem directory:

   ```bash
   cd gems/orbstack_inventory
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Run the test suite:

   ```bash
   bundle exec rake spec
   ```

4. Run RuboCop for code style checks:

   ```bash
   bundle exec rubocop
   ```

## Manual Testing

1. Ensure Orbstack is running:

   ```bash
   orbstack list
   ```

2. Test the inventory plugin with Bolt:

   ```bash
   bolt inventory show --targets orbstack
   ```

3. Verify connectivity:

   ```bash
   bolt command run 'whoami' --targets orbstack
   ```

## Development Workflow

1. Make changes to either the module or gem code
2. Run the appropriate tests as described above
3. Update documentation if necessary
4. Create a pull request with your changes

## Troubleshooting

- If gem tests fail, check that all dependencies are properly installed
- For module test failures, ensure PDK is up to date
- Verify Orbstack is running and accessible
- Check the bolt-debug.log file for detailed error messages

## Additional Resources

- [Orbstack Documentation](https://docs.orbstack.dev/)
- [Puppet Bolt Documentation](https://puppet.com/docs/bolt/)
- [Ruby Gems Documentation](https://guides.rubygems.org/)

## Appendix

### Raw Outputs for use above...

```bash 
➜  how-to-develop-the-module git:(development) ✗ meta git update

*** the following repositories have been added to .meta but are not currently cloned locally:
*** {
  'modules/orbstack_bolt_inventory': 'https://github.com/gavindidrichsen-puppetlabs/orbstack_bolt_inventory.git'
}
*** type 'meta git update' to correct.

/Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/modules/orbstack_bolt_inventory:
Cloning into 'modules/orbstack_bolt_inventory'...
remote: Enumerating objects: 105, done.
remote: Counting objects: 100% (105/105), done.
remote: Compressing objects: 100% (82/82), done.
remote: Total 105 (delta 26), reused 88 (delta 16), pack-reused 0 (from 0)
Receiving objects: 100% (105/105), 36.38 KiB | 1.65 MiB/s, done.
Resolving deltas: 100% (26/26), done.
/Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/modules/orbstack_bolt_inventory ✓


# verify bolt inventory is working
➜  how-to-develop-the-module git:(development) bolt inventory show
Targets
  22-04-ruby
  agent01
  agent02
  agent99
  compiler01
  compiler02
  gitea
  ruby

Inventory source
  /Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/inventory.yaml

Target count
  8 total, 8 from inventory, 0 adhoc

Additional information
  Use the '--targets', '--query', or '--rerun' option to view specific targets
  Use the '--detail' option to view target configuration and data


# ensure the gem works too!
➜  how-to-develop-the-module git:(development) rbc -r 3.2.5
+ message 'setting local ruby version to 3.2.5'
+ set +x
====> setting local ruby version to 3.2.5
+ rbenv local 3.2.5
+ message 'creating .bundle/config'
+ set +x
====> creating .bundle/config
+ mkdir -p .bundle
+ echo ---
+ echo 'BUNDLE_PATH: "vendor/bundle"'
+ echo 'BUNDLE_BIN: "vendor/bin"'
+ echo 'BUNDLE_GEMFILE: "Gemfile"'
+ '[' false = true ']'
+ message 'creatiing the .envrc file adding rbenv and ruby configurations'
+ set +x
====> creatiing the .envrc file adding rbenv and ruby configurations
+ echo 'eval "$(rbenv init -)"'
+ echo 'export PATH="$PWD/vendor/bin:$PATH"'
+ echo 'export GEM_HOME="vendor/bundle"'
+ echo 'export BUNDLE_BIN="vendor/bin"'
+ message 'automatically direnv allowing and reloading the .envrc file'
+ set +x
====> automatically direnv allowing and reloading the .envrc file
+ direnv allow
+ direnv reload
+ set +x
direnv: loading ~/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/.envrc
direnv: export +BUNDLE_BIN +GEM_HOME +RBENV_SHELL ~PATH
➜  how-to-develop-the-module git:(development) git check-ignore -v *
doc/how-tos/how-to-develop-the-module/.gitignore:8:bolt-debug.log       bolt-debug.log
➜  how-to-develop-the-module git:(development) ls -la
total 72
drwxr-xr-x@ 13 gavin.didrichsen  staff   416 Jan 20 13:21 .
drwxr-xr-x@  3 gavin.didrichsen  staff    96 Jan 20 13:17 ..
drwxr-xr-x@  3 gavin.didrichsen  staff    96 Jan 20 13:21 .bundle
-rw-r--r--@  1 gavin.didrichsen  staff   122 Jan 20 13:21 .envrc
-rw-r--r--@  1 gavin.didrichsen  staff   141 Jan 20 13:19 .gitignore
-rw-r--r--@  1 gavin.didrichsen  staff   139 Jan 20 13:19 .meta
-rw-r--r--@  1 gavin.didrichsen  staff     6 Jan 20 13:21 .ruby-version
-rw-r--r--@  1 gavin.didrichsen  staff   123 Jan 20 13:20 Gemfile
-rw-r--r--@  1 gavin.didrichsen  staff  1882 Jan 20 13:17 README.md
-rw-r--r--@  1 gavin.didrichsen  staff  1724 Jan 20 13:21 bolt-debug.log
-rw-r--r--@  1 gavin.didrichsen  staff    52 Jan 20 13:20 bolt-project.yaml
-rw-r--r--@  1 gavin.didrichsen  staff   180 Jan 20 13:20 inventory.yaml
drwxr-xr-x@  3 gavin.didrichsen  staff    96 Jan 20 13:20 modules
➜  how-to-develop-the-module git:(development) git add --force .bundle
➜  how-to-develop-the-module git:(development) ✗ git add --force .envrc
➜  how-to-develop-the-module git:(development) ✗ git add --force .ruby-version 
➜  how-to-develop-the-module git:(development) ✗ cat Gemfile 
source 'https://rubygems.org'

gem 'orbstack_bolt_inventory', path: 'modules/orbstack_bolt_inventory'
gem "bolt", "~> 4.0"
➜  how-to-develop-the-module git:(development) windsurf Gemfile 
➜  how-to-develop-the-module git:(development) bundle config
Settings are listed in order of priority. The top value will be used.
bin
Set for your local app (/Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/.bundle/config): "vendor/bin"
Set via BUNDLE_BIN: "vendor/bin"

gemfile
Set for your local app (/Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/.bundle/config): "Gemfile"
Set via BUNDLE_GEMFILE: "/Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/Gemfile"

path
Set for your local app (/Users/gavin.didrichsen/@REFERENCES/github/app/development/tools/puppet/@products/bolt/inventories/orbstack_inventory_USAGE/modules/orbstack_bolt_inventory/doc/how-tos/how-to-develop-the-module/.bundle/config): "vendor/bundle"

➜  how-to-develop-the-module git:(development) bundle install
Resolving dependencies...
Fetching gem metadata from https://rubygems.org/.
Fetching yaml 0.4.0
Fetching json 2.9.1
Installing yaml 0.4.0
Installing json 2.9.1 with native extensions
Bundle complete! 1 Gemfile dependency, 4 gems now installed.
Bundled gems are installed into `./vendor/bundle`


# and the command works perfectly
➜  how-to-develop-the-module git:(development) bundle exec orby
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
- name: 22-04-ruby
  uri: 22-04-ruby@orb
- name: agent01
  uri: agent01@orb
- name: agent02
  uri: agent02@orb
- name: agent99
  uri: agent99@orb
- name: compiler01
  uri: compiler01@orb
- name: compiler02
  uri: compiler02@orb
- name: gitea
  uri: gitea@orb
- name: ruby
  uri: ruby@orb
➜  how-to-develop-the-module git:(development) 
```
