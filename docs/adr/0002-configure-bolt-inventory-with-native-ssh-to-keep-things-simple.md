# 2. Configure bolt inventory with native ssh to keep things simple

Date: 2025-01-10

## Status

Accepted

## Context

Although there may be a number of ways to configure the SSH connectivity for a bolt dynamic inventory plugin, I want to implement this plugin as simply as possible and at the same time use the same ssh approach as on my terminal.  Troubleshooting is easier: if my command-line cannot ssh to my orbstack VMs, then my plugin won't either.  Fix the command-line and the plugin should work as well.

## Decision

Therefore, I decided to configure the orbstack_inventory plugin to use native ssh.

## Consequences

This is a simple way to get started with a dynamic plugin and to troubleshoot.
