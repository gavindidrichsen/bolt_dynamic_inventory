# Development Guide: Orbstack Inventory Module

This guide explains how to set up your development environment and test both the Puppet module and Ruby gem components of the Orbstack inventory plugin.

## Prerequisites

* Ruby (version in `.ruby-version`)
* direnv installed
* Bundler
* Puppet Development Kit (PDK)
* Orbstack installed and running

## Tutorial: Initial Setup

```bash
# setup ruby environment
rbenv local 3.2.5

# configure bundler
mkdir -p .bundle
cat > .bundle/config <<EOF
---
BUNDLE_PATH: "vendor/bundle"
BUNDLE_BIN: "vendor/bin"
BUNDLE_GEMFILE: "Gemfile"
EOF

# Create .envrc
cat > .envrc <<EOF
eval "$(rbenv init -)"
export PATH="$PWD/vendor/bin:$PATH"
export GEM_HOME="vendor/bundle"
export BUNDLE_BIN="vendor/bin"
EOF

# Allow direnv
direnv allow
```

## How-To Guides

### Test the Gem

```bash
# verify orbstack VMs
orb list

# install dependencies:
bundle install

# run tests:
bundle exec rake spec
bundle exec rubocop

# output bolt inventory and visually inspect
bundle exec orby
```

### Test the Puppet Module Plugin

```bash
# verify inventory.yaml
bolt inventory show
bolt command run 'whoami' --targets all
```

## Reference

### Project Structure

```bash
.
├── .bundle/          # Bundler configuration
├── modules/          # Puppet modules
│   └── orbstack_bolt_inventory/
├── .envrc           # direnv configuration
├── .ruby-version    # Ruby version specification
├── Gemfile          # Gem dependencies
└── inventory.yaml   # Generated inventory
```

### Key Files

* `Gemfile`: Contains minimal dependencies and points to the local gem

  ```ruby
  source 'https://rubygems.org'
  gem 'orbstack_bolt_inventory', path: 'modules/orbstack_bolt_inventory'
  gem "bolt", "~> 4.0"
  ```

* `.bundle/config`: Standard bundler configuration
* `inventory.yaml`: Plugin configuration file that loads the plugin beneath `modules/orbstack_bolt_inventory`

## Troubleshooting

### Common Issues

## Additional Resources

* [Orbstack Documentation](https://docs.orbstack.dev/)
* [Puppet Bolt Documentation](https://puppet.com/docs/bolt/)
* [Ruby Gems Guide](https://guides.rubygems.org/)
