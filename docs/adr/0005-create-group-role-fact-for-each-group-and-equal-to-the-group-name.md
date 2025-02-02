# 5. Create group 'role' fact for each group and equal to the group name

Date: 2025-02-02

## Status

Accepted

## Context

I want my bolt inventory.yaml to

* not only have 'groups' defined by regex,
* but also a 'role' fact defined on each server

In other words, I want the server itself to know it's own 'role'.

## Decision

Therefore, I decided to add a `${facts['role']}` to target in a group.  In other words, given a group called `agent` then the `$facts.role = 'group'`.

## Consequences

The consequence is that I'll be able to easily switch configuration based on this group or `'role'`.
