# 3. Gather inventory metadata via the cli to keep things simple

Date: 2025-01-10

## Status

Accepted

## Context

When I discovered orbstack and in particular how easy and fast it was to create VMs, I immediately wanted to start using bolt to provision my orbstack VMs.  Initially, I manually created the `inventory.yaml` but soon after created a ruby script to automatically generate the same `inventory.yaml`.  Anytime I added or removed an orbstack VM I ran this script to generate an up-to-date bolt inventory.  Since bolt plugins are useful for many tasks, including dynamic inventories, I decided to refactor my ruby script into a dynamic inventory plugin.  One easy way to access the orbstack VM metadata is through the `orb` CLI.

Other VM providers like vmpooler also have useful CLI commands for accessing VM metadata.

## Decision

Therefore, I decided to keep the implementation simple by using the CLI to access VM metadata.  For orbstack VMs I use the `orb` cli; for vmpooler, the `floaty`.

## Consequences

The simplest approach here means that we have a working plugin that can be refactored at a later date, if required.
