# Create and Remove Orbstack VMs from the command-line

## Description

The following shows how to both add and remove orbstack VMs from the command-line.

## Pre-requisites

Ensure the following are installed and configured:

* [orbstack](https://docs.orbstack.dev)

## Usage

### Create orbstack VMs

Before proceeding, make sure to create 5 Ubuntu 22.04 amd64 orbstack machines in orbstack as follows `agent01`, `agent02`, `agent03`, `compiler01`, and `compiler02`.  Do this manually or 


```bash
# create 3 'agent0*' machines
for i in {1..3}; do
  orbctl create --arch amd64 ubuntu:22.04 agent0$i
done

# create 2 'compiler0*' machines
for i in {1..2}; do
  orbctl create --arch amd64 ubuntu:22.04 compiler0$i
done

# verify all machines are present
orbctl list
```

### Remove orbstack VMs

Before proceeding, make sure to create 5 Ubuntu 22.04 amd64 orbstack machines in orbstack as follows `agent01`, `agent02`, `agent03`, `compiler01`, and `compiler02`.  Do this manually or 


```bash
# create 3 'agent0*' machines
for i in {1..3}; do
  orbctl create --arch amd64 ubuntu:22.04 agent0$i
done

# create 2 'compiler0*' machines
for i in {1..2}; do
  orbctl create --arch amd64 ubuntu:22.04 compiler0$i
done

# verify all machines are present
orbctl list
```
