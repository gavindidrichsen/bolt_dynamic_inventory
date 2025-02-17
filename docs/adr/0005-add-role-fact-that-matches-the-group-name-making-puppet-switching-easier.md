# 5. Add 'role' fact that matches the group name making puppet switching easier

Date: 2025-02-02

## Status

Accepted

## Context

I want my bolt inventory.yaml to **not only** have 'groups' defined by regex, **but also** a 'role' fact defined for each of these groups.  The role fact will have the same name as the group name.  The reason this is useful is that bolt does not have to wait for puppet to collect facts on each target before switching on this 'role'.  If I only wait for puppet to return a target's facts, then bolt is effectively blind for the first run.  It cannot switch on particular target facts that it doesn't have.  Since we're creating the bolt inventory and know relevant information about the targets, then I want this always available.  

## Decision

Therefore, I decided to add a `${facts['role']}` for each group where the 'role' value is equal to the group name.  In other words, given a group called `agent` then the `$facts.role = 'group'`.

## Consequences

The consequence is that I'll be able to easily switch configuration based on this group or `'role'`.
