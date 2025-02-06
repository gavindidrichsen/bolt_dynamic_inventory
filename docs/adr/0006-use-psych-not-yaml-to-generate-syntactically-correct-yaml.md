# 6. Use psych not yaml to generate syntactically correct yaml

Date: 2025-02-03

## Status

Accepted

## Context

When generating YAML output for Bolt inventory files, we encountered issues with the standard Ruby `YAML.dump` method producing output that failed `yamllint` validation. The primary issues were:

1. Inconsistent indentation in nested structures
2. Improper formatting of arrays (using flow style instead of block style)
3. Limited control over the output format

These issues led to YAML files that, while technically valid, did not meet the strict formatting requirements of tools like `yamllint` and could be difficult to read and maintain.

## Decision

We decided to use the Psych library directly instead of the higher-level YAML interface. Specifically:

1. Replace `YAML.dump` with `Psych.dump`
2. Configure Psych with explicit formatting options:

   ```ruby
   Psych.dump(data,
             indentation: 2,
             line_width: -1,
             block_style: true,
             out: $stdout)
   ```

Psych is actually the underlying engine that Ruby's YAML module uses, but accessing it directly provides more fine-grained control over the output format.

## Consequences

### Positive

1. Generated YAML files consistently pass `yamllint` validation
2. Better control over formatting through Psych's additional options
3. More readable output with proper indentation and block-style arrays
4. Consistent with YAML 1.2 specification requirements

### Negative

1. Direct dependency on Psych instead of the more abstract YAML interface
2. Slightly more verbose code when specifying formatting options
3. Need to maintain knowledge of Psych-specific options and behaviors

### Neutral

1. No performance impact as Psych was already being used under the hood
2. No changes required to the actual data structures being serialized
