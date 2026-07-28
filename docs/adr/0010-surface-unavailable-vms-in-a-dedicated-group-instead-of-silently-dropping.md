---
tags:
  - -scope/implementation
---

<!--
# Common Guidelines
**Orientation — capture the knowledge behind the problem (read this first):**

- This document is almost always written mid-investigation — while fixing a bug, a broken build, or a failing test. **The problem is the lens, not the subject.** Solving it is the author's day-job; it is not what this document is for.
- The document's enduring value is the **domain knowledge that the problem revealed** — how the system (e.g. Bolt, Puppet, Puppet Enterprise) actually works. Make that the centre of gravity.
- Before writing, answer for yourself: *What does this problem and its solution verify about the domain? What is now understood better about how this system behaves, because of this issue?* Let those answers drive the content.
- Keep the triggering problem to a brief motivating context (a sentence or two: "this surfaced while fixing X"). Spend the document on the mental model, mechanism, and transferable insight that outlive the specific incident.
- Litmus test: if the specific problem vanished tomorrow, the document should still be worth reading as an account of how the domain works.

**Style Guidelines (Strict):**

- Treat this document as a template to be filled, not redesigned.
- Replace placeholder text completely; do not leave generic filler.
- Keep wording concise, specific, and scoped to this document's topic.
- Use bulleted lists with `-` instead of numbered lists for easy reordering.
- Create headings without numbers (e.g., `### Install Package` not `### Step 1: Install Package`).
- Keep headings descriptive so steps can be rearranged without renumbering.

**Heading Rules:**
- All `###` and lower subheadings must be concise, descriptive titles (3-7 words).
- Placeholder headings (e.g., `### Concept 1`, `### Change 1`) must be replaced with topic-specific titles before completion.
- Use `####` subheadings for subsections instead of bold text with numbers.

**Linking Rules:**
- Every reference in Related Topics must be a real link (no placeholder bullets).
- **Code**: Link to GitHub with a **permalink** — a commit-SHA-pinned URL with line numbers, NOT a `blob/main` branch URL: [`filename:line`](https://github.com/org/repo/blob/<commit-sha>/path/file.rb#L123). Use the full 40-char SHA (or at least the abbreviated one). Permalinks are mandatory because branch URLs silently drift to the wrong lines as the file changes; a SHA pin always points at the code as it was when you wrote about it. (On GitHub press `y` to convert a branch URL to a permalink.)
- **Commits**: Link to the actual commit: [`short-sha`](https://github.com/org/repo/commit/full-sha). In PR descriptions, each change section must include a commit link so reviewers can navigate directly to the diff.
- **Docs**: Link to official documentation pages.
- **Local**: Link to local docs with Obsidian-style wiki links: `[[doc-filename]]` or `[[doc-filename|display text]]`. Use the filename without the `.md` extension. Wiki links resolve by filename, so they survive file moves within the vault.

**Code Evidence Requirement (required when code is referenced):**
- For each major section,
  - include BOTH a source link to real code (with line numbers), and a short "Code Sample" block that clarifies intent.
- The "Code Sample" may be:
  - A minimal real excerpt, or
  - A simplified pseudocode version with brief comments.
- The sample must explain behavior, not just repeat syntax.
- Keep samples small and focused (about 5-20 lines).
- Add 1-3 bullets under each sample explaining:
  - what the code is doing,
  - why it matters in this document,
  - and any important caveat/assumption.
- Never fabricate APIs or behavior; if code cannot be verified, explicitly state that and omit the sample.

**Diagrams (use Mermaid where it earns its place):**
- Reach for a Mermaid diagram when a picture explains structure or flow faster than prose would — for example: how components fit together, a sequence of steps or messages, a state transition, or a before/after of a change.
- Do NOT add a diagram just to have one. If the prose is already clear, or the relationship is trivial (two or three linear steps), skip it — a needless diagram is worse than none.
- Prefer one focused diagram over a single sprawling one; split distinct ideas into separate diagrams. If a diagram would otherwise grow wide (many parallel subgraphs/branches, or several loosely-related stages), first check whether splitting it into two or more smaller diagrams reads more clearly than one large one — prefer that split over cramming everything into a single diagram.
- Use a fenced ` ```mermaid ` block. Keep node labels short and the diagram readable without zooming.
- **Orient top-to-bottom for flowcharts and state diagrams**: use `flowchart TD` (or `TB`) and `stateDiagram-v2` default direction, not `flowchart LR`. Rendered width grows with the diagram in a top-to-bottom layout, so the reader scrolls vertically (natural) instead of horizontally (requires scrolling the page sideways, which most viewers handle poorly). Only use `LR` when the content is inherently a short horizontal sequence (2-4 nodes) that reads awkwardly stacked vertically — a rare exception, not the default. This does NOT apply to `sequenceDiagram` — participants are naturally laid out left-to-right with time flowing down, so that convention stays as-is.
- If a flowchart has several parallel branches (e.g. multiple subgraphs or sibling paths), stack them as sequential top-to-bottom sections rather than side-by-side columns, even if that makes the diagram taller — taller is scrollable in place, wider is not. If stacking makes the single diagram feel overloaded, split it instead (see above).
- Always keep the surrounding prose self-sufficient: the diagram should reinforce the explanation, not be the only place a key point is made (it may not render on every surface).

**File Setup Formatting Rule (required for how-to steps):**
- Do not use heredoc-style file creation commands such as `cat > file <<'EOF'` in instructional steps.
- For each file, present setup as:
  - `Create <path/filename>` (short purpose sentence), then
  - one fenced code block containing the file contents.
- Include the filename as the first line in the code block (for example, `# hosts.yaml`).
- Keep command blocks for executable commands only (for example, directory setup, `bundle install`, and test execution).

# Template-Specific Guidelines

**Additional Linking Rules:**
- **Related ADRs**: Link to other ADRs: [[0001-title|ADR-0001]].
-->

# 10. Surface unavailable VMs in a dedicated group instead of silently dropping

Date: 2026-07-09

## Status

Accepted

## Context

The vmpooler provider uses nmap to check VM reachability (see [[0007-use-nmap-ssh-port-scan-for-vmpooler-vm-connectivity-filtering|ADR-0007]]). Previously, VMs that failed the nmap check were silently excluded from the inventory. This made it difficult to diagnose connectivity issues — a VM could be allocated and expected to be in the inventory, but its absence gave no indication of why.

Silent drops are particularly confusing when VMs are still running but temporarily unreachable (network glitches, DNS propagation delays, or VMs still booting). The user sees fewer VMs than expected and has no signal about what happened.

## Decision

Therefore, I decided to place unreachable VMs into a dedicated `unavailable` group instead of dropping them:

```ruby
# lib/bolt_dynamic_inventory/provider/vmpooler/inventory.rb — generate_inventory
def generate_inventory(alive_vms, unavailable_vms)
  # ... targets and groups built from alive_vms ...
  groups << unavailable_group(unavailable_names) unless unavailable_names.empty?
  # ...
end

def unavailable_group(targets)
  {
    'name' => 'unavailable',
    'facts' => { 'role' => 'unavailable' },
    'targets' => targets
  }
end
```

- VMs failing nmap appear in the `unavailable` group with a `role: unavailable` fact
- The group is only added when there are actually unavailable VMs
- Unavailable VMs still appear in the top-level `targets` list with their full metadata (type, ttl)
- No transport config is set on the `unavailable` group — attempting to connect via Bolt will fail with a clear transport error rather than a silent omission

## Consequences

- Users can see at a glance which VMs are allocated but unreachable, making connectivity debugging straightforward
- Bolt plans can explicitly handle unavailable targets (e.g., skip them, wait and retry, or alert)
- The `unavailable` group name is reserved — it cannot be used as a regex group pattern name
- `binv` emits a yellow warning to stderr when unavailable VMs are present, so the user is immediately alerted without disrupting stdout (which remains valid YAML)
- The inventory output is slightly larger when VMs are unreachable, but this is a worthwhile trade for visibility

## Related Topics

- [[0007-use-nmap-ssh-port-scan-for-vmpooler-vm-connectivity-filtering|ADR-0007]]: The nmap scan that determines availability
- [[0005-add-role-fact-that-matches-the-group-name-making-puppet-switching-easier|ADR-0005]]: The `role` fact convention reused here
