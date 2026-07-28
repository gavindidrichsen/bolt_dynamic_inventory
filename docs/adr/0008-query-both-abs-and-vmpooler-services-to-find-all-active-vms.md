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

# 8. Query both ABS and vmpooler services to find all active VMs

Date: 2026-07-09

## Status

Accepted

## Context

The vmpooler provider originally used only `floaty list --active --json` (which queries the ABS service) to discover VMs. This missed VMs that were still running on vmpooler but no longer tracked by ABS. This was discovered when VMs known to be running did not appear in `binv` output.

The root cause is that ABS and vmpooler have independent lifecycles. ABS tracks jobs by user — `floaty` fetches the entire ABS queue (`GET /api/v2/status/queue`) and filters client-side by `request.job.user`. When ABS reaps a job (its ABS lifecycle ends), the job disappears from the queue even though the underlying VMs may still be running on vmpooler (their vmpooler lifetime has not yet expired). Querying vmpooler directly (`GET /token/<token>`) returns all VMs still alive under a given token, regardless of whether ABS still tracks them. This means a user's vmpooler VMs can outlive their ABS job records, making them invisible to an ABS-only query.

## Decision

Therefore, I decided to query both services and merge the results:

- Query ABS via `floaty list --active --json` for VMs in `filled` or `allocated` state
- Query the vmpooler service via `floaty list --active --json --service vmpooler` for all VMs with their runtime metadata
- Merge the two lists by hostname: ABS VMs are enriched with `ttl` data from the vmpooler service when the same hostname appears in both; vmpooler-only VMs are appended to the list

```ruby
# lib/bolt_dynamic_inventory/provider/vmpooler/inventory.rb — merge_vm_lists
def merge_vm_lists(abs_vms, vmpooler_vms)
  vmpooler_by_host = vmpooler_vms.each_with_object({}) { |vm, h| h[vm['hostname']] = vm }

  merged = abs_vms.map do |abs_vm|
    vmpooler_vm = vmpooler_by_host.delete(abs_vm['hostname'])
    if vmpooler_vm && vmpooler_vm['ttl']
      abs_vm.merge('ttl' => vmpooler_vm['ttl'])
    else
      abs_vm
    end
  end

  merged.concat(vmpooler_by_host.values)
end
```

- ABS VMs are processed first; matching vmpooler entries are consumed (deleted from the lookup hash) to avoid duplicates
- The `ttl` field from vmpooler enriches ABS VMs so every target shows its reap time
- Any vmpooler VMs not matched to an ABS entry are appended — these are the previously-missing VMs

## Consequences

- All active VMs now appear in the Bolt inventory regardless of which service provisioned them
- The inventory output includes a `ttl` field per target showing when the VM will be reaped, calculated from vmpooler's `lifetime` and `running` fields
- Two `floaty` calls are made instead of one, adding a small amount of latency (mitigated by [[0009-cache-vm-data-with-smart-ttl-based-invalidation|ADR-0009]] caching)
- If either service is unavailable, the command fails — there is no graceful fallback to partial results

## Related Topics

- [[0006-extend-the-plugin-to-handle-not-only-orbstack-but-vmpooler-as-well|ADR-0006]]: Original vmpooler provider decision
- [[0003-gather-inventory-metadata-via-the-cli-to-keep-things-simple|ADR-0003]]: CLI-based metadata gathering approach
- [`e7d3e28`](https://github.com/gavindidrichsen/bolt_dynamic_inventory/commit/e7d3e28d14d4b418277810b9c231b7c61814a4bc): Commit implementing the dual-service query and merge
