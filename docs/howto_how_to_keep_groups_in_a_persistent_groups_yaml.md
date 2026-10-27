# How to keep groups in a persistent groups.yaml

## Description

This guide shows how to create inventory groups for VMPooler VMs once and have them stay across refreshes, for example `2agents` and `3agents` for the agents wired to two PE primaries. See [ADR-0013](adr/0013-persist-vmpooler-groups-in-a-global-and-a-local-groups-yaml.md) for why it works this way.

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

To change a group by hand, edit the global file, or add a `groups.yaml` next to where you run `binvv`: a group there replaces the global group of the same name.

What to expect on each run:

- `global` lists every VM, always.
- A target that no longer exists is dropped from the other groups. On a terminal it asks first; otherwise it says what it dropped on stderr.
- VMs in no group are listed on stderr.

## Troubleshooting

- **`Group 'x' already exists`**: `-g` does not overwrite; add `--force`.
- **A new VM is missing from a group**: groups keep their stored targets. Add it to the file, or re-create the group with `--force`.
