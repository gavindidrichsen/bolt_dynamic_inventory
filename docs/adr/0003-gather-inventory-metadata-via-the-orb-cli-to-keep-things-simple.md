# 3. Gather inventory metadata via the 'orb' cli to keep things simple

Date: 2025-01-10

## Status

Accepted

## Context

When I discovered orbstack and in particular how easy and fast it was to create VMs, I immediately wanted to start using bolt to provision my orbstack VMs.  Initially, I manually created the `inventory.yaml` but soon after created a ruby script to automatically generate the same `inventory.yaml`.  Prior to creating this dynamic plugin, I had a ruby script that I used to generate a global `inventory.yaml` file just for orbstack VMs.  Anytime I added or removed an orbstack VM I needed to run this script and this was fine: it saved me the hassle of manually adding or removing bolt inventory targets for orbstack.  

Since bolt plugins are useful for many tasks, including dynamic inventories, I decided to refactor my ruby script into a plugin.  This repository was my first investigation into bolt dynamic inventory plugins.  In effect, I wanted to transform my script into a dynamic inventory for bolt.

## Decision

Therefore, I decided to gather the orbstack VM metadata using the `orb` command-line tool as this is the simplest way to interact with orbstack.

## Consequences

The simplest approach here means that we have a working plugin that can be refactored at a later date, if required.
