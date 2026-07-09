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

# 9. Cache VM data with smart TTL-based invalidation

Date: 2026-07-09

## Status

Accepted

## Context

Each `binv --provider=vmpooler` invocation makes two `floaty` API calls (ABS + vmpooler service, see [[0008-query-both-abs-and-vmpooler-services-to-find-all-active-vms|ADR-0008]]) plus an `nmap` scan of all returned VMs. This takes several seconds even for a small VM set. Since VMs are not frequently added or removed, repeating these queries on every invocation wastes time without improving accuracy.

However, a simple time-based TTL cache is not sufficient. If a cached VM's TTL has already passed, the VM has likely been reaped by vmpooler and the cached inventory is stale. The cache must account for this.

## Decision

Therefore, I decided to add a file-based VM cache (`VmCache`) with three invalidation triggers:

- **Manual refresh**: the `--refresh` / `-r` CLI flag bypasses the cache entirely
- **VM expiry**: if any cached VM's `ttl` timestamp has passed, the cache is invalidated (the VM was likely reaped)
- **Age-based TTL**: cache older than 24 hours is discarded regardless of VM state

```ruby
# lib/bolt_dynamic_inventory/provider/vmpooler/inventory.rb — load_vms
def load_vms
  unless @refresh
    cached = @cache.read
    return cached if cached && !@cache.any_vm_expired?(cached)
  end

  vms = fetch_vmpooler_vms
  @cache.write(vms)
  vms
end
```

- `@refresh` skips the cache entirely when `--refresh` is passed
- `@cache.read` returns `nil` if the cache file is missing or older than 24 hours
- `any_vm_expired?` checks each VM's `ttl` against `Time.now` — if any VM has been reaped, we refetch

The cache is stored in `~/.bolt_dynamic_inventory/cache/vmpooler_vms.json` as a JSON payload with a `stored_at` timestamp, the provider name, and the full VM list.

## Consequences

- `binv` returns instantly on repeated calls within the cache window, making it practical for scripts and tab-completion workflows
- Accuracy is maintained: the cache self-invalidates when any VM's TTL expires, so reaped VMs never persist in the inventory
- The `--refresh` flag provides an escape hatch when the user knows the VM set has changed (e.g., immediately after provisioning)
- Cache files accumulate in `~/.bolt_dynamic_inventory/cache/` — there is no automatic cleanup of old cache files from other providers
- The 24-hour default TTL is a conservative fallback; most invalidation in practice comes from the VM expiry check

## Related Topics

- [[0008-query-both-abs-and-vmpooler-services-to-find-all-active-vms|ADR-0008]]: The dual-service query that caching wraps
- [[0007-use-nmap-ssh-port-scan-for-vmpooler-vm-connectivity-filtering|ADR-0007]]: Nmap scanning that caching also avoids repeating
- [`494a1ae`](https://github.com/gavindidrichsen/bolt_dynamic_inventory/commit/494a1ae00ad8dd526d20e0e21f52c310ab8cbb25): Commit implementing the VM cache
