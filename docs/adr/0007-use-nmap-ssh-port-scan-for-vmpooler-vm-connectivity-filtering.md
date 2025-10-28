# 7. Use nmap SSH port scan for VMPooler VM connectivity filtering

Date: 2025-10-28

## Status

Accepted

## Context

VMPooler VM output from `floaty list --active --json` cannot distinguish between alive and destroyed VMs. The API returns all VMs that have been allocated, regardless of their current connectivity state. This creates issues when generating Bolt inventory as it includes unreachable hosts that will cause execution failures.

Using floaty itself to get detailed information about each VM would require individual API calls per VM, creating significant overhead and performance issues when dealing with many VMs.

We need an efficient way to filter the VM list to only include hosts that are actually reachable for Bolt operations.

## Decision

We will use `nmap` with SSH port scanning to perform parallel connectivity checks on all VMPooler VMs. The specific approach:

1. **Use `nmap -Pn -p 22` for all VMs** - This works for both Linux and Windows hosts
2. **Skip ICMP ping checks (`-Pn`)** - Windows servers typically block ICMP, causing false negatives
3. **Check SSH port 22 only** - All VMPooler VMs (Linux and Windows) have SSH enabled
4. **Parse "Nmap scan report" entries** - Presence of scan report indicates host is reachable, regardless of port state
5. **Handle DNS resolution failures gracefully** - Unreachable hosts won't have scan reports

We initially considered using RDP port 3389 for Windows detection, but found that SSH port 22 is universally available and provides a simpler, unified approach.

## Consequences

### Positive

- **Fast parallel scanning** - nmap can check multiple hosts simultaneously
- **Reliable Windows detection** - `-Pn` flag bypasses ping issues common with Windows
- **No additional API overhead** - Single nmap command replaces multiple floaty API calls  
- **Universal compatibility** - SSH port 22 works for both Linux and Windows VMs
- **Graceful failure handling** - DNS resolution failures are handled cleanly

### Negative

- **External dependency** - Requires nmap to be installed on the system
- **Additional network traffic** - Performs port scans on all VMs
- **Potential security considerations** - Port scanning might trigger security monitoring
- **Slight execution delay** - Adds network scanning time to inventory generation

### Neutral

- **SSH requirement assumption** - Relies on all VMPooler VMs having SSH enabled (current standard)
- **Port state independence** - Works whether SSH is open or closed, only checks host reachability
