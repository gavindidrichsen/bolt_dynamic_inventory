# How to keep groups in a persistent groups.yaml

## Description

This guide shows how to create inventory groups for VMPooler VMs once and have them stay across refreshes, for example `2agents` and `3agents` for the agents wired to two PE primaries. See [ADR-0013](adr/0013-persist-vmpooler-groups-in-a-global-groups-yaml-loaded-by-bolt.md) for why it works this way.

## Prerequisites

- The `bolt_dynamic_inventory` gem installed and the `vmpooler` provider working (`binv --provider=vmpooler`, or the `binvv` alias).

## Usage

```bash
# create groups; they are written to ~/.config/bolt_dynamic_inventory/vmpooler/groups.yaml
binvv --refresh -g "1prim:^high,2agents:^(kind|unborn)" > inventory.yaml

# later runs need no -g: the groups come from the file
binvv --refresh > inventory.yaml

# replace a group that already exists
binvv -g "2agents:^(kind|unborn|usual)" --force > inventory.yaml

# check a group
bolt inventory show --targets 2agents
```

The groups live only in `~/.config/bolt_dynamic_inventory/vmpooler/groups.yaml`; `inventory.yaml` loads that file with Bolt's `yaml` plugin, so the same groups work from any project. To change a group by hand, edit its `targets` there; `binvv --refresh` keeps `global` current and drops VMs that no longer exist.

What to expect on each run:

- `inventory.yaml` is rewritten, and `global` lists every VM, always.
- A target that no longer exists is dropped from the other groups (an emptied group is kept). On a terminal it asks first; otherwise it says what it dropped on stderr.
- VMs in no group are listed on stderr.

## Troubleshooting

- **`Group 'x' already exists`**: `-g` does not overwrite; add `--force`.
- **A new VM is missing from a group**: groups keep their stored targets. Add it to the file, or re-create the group with `--force`.
