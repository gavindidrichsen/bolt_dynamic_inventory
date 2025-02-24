# How to Test VMPooler Inventory Features

This guide shows you how to manually test the VMPooler inventory features to ensure they work as expected.

## Prerequisites

* Access to VMPooler
* Bolt installed
* The bolt_dynamic_inventory module installed

## Test Scenarios

### 1. Basic Inventory Generation (No VMs)

```bash
# 1. Ensure no VMs are running in VMPooler
bundle exec floaty list --active

# 2. Generate the inventory
binv generate --provider vmpooler
```

Verify:

* Empty targets list
* Windows and Linux groups exist but have no targets
* Group configurations are present and correct

### 2. Basic Inventory Generation (With VMs)

```bash
# 1. Create test VMs:
bundle exec floaty get windows-2019-x86_64
bundle exec floaty get ubuntu-2004-x86_64

# 2. Generate the inventory
binv generate --provider vmpooler
```

Verify:

* All VMs appear in targets list
* Windows VMs are in windows group with correct config
* Linux VMs are in linux group with correct config

### 3. Regex Group Pattern Testing

```bash
# 1. Create test VMs with specific naming patterns:
bundle exec floaty get ubuntu-2004-x86_64 # Will get a name like 'tender-punditry'
bundle exec floaty get ubuntu-2004-x86_64 # Will get a name like 'normal-meddling'

# 2. Generate inventory with group patterns:
binv generate --provider vmpooler --config '{"group_patterns": [{"group": "agent", "pattern": "tender|normal"}]}'
```

Verify:

* Base groups (windows/linux) exist and contain correct VMs
* 'agent' group exists and contains VMs matching the pattern
* Group facts and configurations are correct

## Cleanup

After testing, remember to delete your test VMs:

```bash
bundle exec floaty delete <hostname>
```

## Troubleshooting

* If inventory generation fails, check VMPooler connectivity
* Verify VM hostnames in floaty output match expected patterns
* Check Windows credentials are properly configured if testing Windows VMs
