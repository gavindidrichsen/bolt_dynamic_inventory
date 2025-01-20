# 1. Extend this gem to be a bolt inventory dynamic plugin also

Date: 2025-01-09

## Status

Accepted

## Context

Bolt plugins are very useful for enhancing bolt functionality, particularly around inventory control.  For example, a number of existing plugins exist to create dynamic inventory for Azure or AWS.  These kinds of plugins are known as [reference plugins](https://www.puppet.com/docs/bolt/latest/writing_plugins#reference-plugins).  While the implementation of a dynamic reference inventory plugin could live directly in the `tasks/resolve_reference.rb`, this is not good practice as it makes it difficult to test the logic.  Also, it hides the underlying bolt `inventory.yaml` that is generated making it very difficult to troubleshoot.  Further, this code is useful not only for a bolt dynamic inventory plugin but also for command-line.  I might just want to generate a raw `inventory.yaml` for my orbstack and not use the dynamic plug in feature.

One way to make the above possible is to make this code not only a gem for use in pure ruby, but also capable of acting as a bolt reference dynamic plugin.


## Decision

Therefore, I decided to extend this gem to be also a bolt dynamic inventory reference plugin.

## Consequences

Everything is easier now, testing, debugging.
