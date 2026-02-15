# Hierarchical Message Roll-Up Grouping — Requirements

**GitHub Issue:** #97
**Status:** Requirements Definition
**Depends on:** #96 (fuzzy message consolidation)

## Problem Statement

### Current Behavior

ltl's summary table presents a flat list of messages sorted by occurrence or impact. Each message pattern is an independent entry with its own statistics. There is no concept of message families or parent-child relationships between related messages.

### Why This Is a Problem

Users analyzing log data often need to understand the composition of activity at multiple levels of granularity:

- "How many total API calls hit the `/api/v2/` family?" (parent level)
- "What percentage were `/api/v2/profile` vs `/api/v2/profile/update`?" (child level)
- "This endpoint family accounts for 80% of all latency — which specific endpoint is the hotspot?" (drill-down)

A flat list forces users to mentally aggregate related entries, which is impractical when there are dozens or hundreds of variations within a family.

### Relationship to #96

Issue #96 (fuzzy message consolidation) builds the core engine: n-gram indexing, similarity scoring, character-level alignment, canonical form generation, and statistics merging. It operates in two phases:

- **Pattern discovery** (expensive, batch): pairwise comparison, alignment, canonical pattern creation
- **Pattern matching** (cheap, continuous): incoming messages matched against known patterns at line processing time

In #96, both phases result in **consolidation** — original entries are merged into the canonical form and discarded. The goal is noise reduction and memory savings.

This feature (#97) uses the **same two-phase engine** but with a different outcome: original entries are **preserved** as children under a parent group. Incoming messages that match a known pattern during Phase 2 are routed into a child entry under the parent cluster rather than merged into the parent's aggregate. The goal is organization and insight, not reduction.

Both features can compose:
- **Consolidation within children**: truly redundant child entries (same pattern, different UUIDs) can be consolidated using #96's engine, reducing noise within a group
- **Hierarchy on top**: the reduced set is organized into families with aggregate parent stats
- Consolidation within children uses the same two-phase approach — discovery patterns within a group, then cheap matching for subsequent entries

## Goals

1. **Hierarchical view** — group similar messages into parent-child relationships where the parent shows a generalized canonical form with aggregate statistics
2. **Preserve detail** — child entries retain their individual statistics and are visible in the output
3. **Reuse #96 engine** — same two-phase processing (discovery + matching), canonical form generation, and stats aggregation; no duplicate machinery
4. **Optional feature** — enabled via `--group-detail`; flat view remains the default
5. **Composable with #96** — consolidation and hierarchy can operate together; consolidation reduces children, hierarchy organizes the result

## Non-Goals

- **Building a separate similarity engine** — this feature depends entirely on #96's engine
- **Nested hierarchy** — only one level of parent-child grouping; not recursive/tree-structured
- **Interactive drill-down** — ltl is a batch output tool; hierarchy is displayed in full, not navigated interactively

## Design Decisions

### DD-01: Same Engine, Different Routing

**Decision:** Hierarchical grouping uses the same n-gram indexing, similarity scoring, character-level alignment, and canonical form generation as #96. The difference is how matched messages are routed:

| | #96 Consolidation | #97 Hierarchical |
|---|---|---|
| Pattern discovery | Batch: pairwise comparison + alignment | Same |
| Pattern matching | Continuous: incoming messages matched at line processing time | Same |
| Match routing | Merged into parent aggregate, original discarded | Stored as child entry under parent, original preserved |
| Parent stats | Replace originals | Roll-up aggregates alongside children |
| Memory impact | Reduces (frees merged entries) | Increases (adds parent layer, preserves children) |
| Purpose | Noise reduction, memory relief | Organization, insight |

### DD-02: Single Level of Hierarchy

**Decision:** One parent level with flat children underneath. No nesting.

**Rationale:** Multiple nesting levels add significant display complexity and cognitive load. A single roll-up level covers the primary use case (message families) without over-engineering. If deeper nesting proves necessary, it can be considered as a future enhancement.

### DD-03: Data Structure Compatibility

**Decision:** The cluster model from #96 naturally supports hierarchy through its `children` hash. The data structure is already designed with #97 in mind:

- `children` hash holds original entries with their individual statistics
- `is_consolidated` flag distinguishes consolidated groups from unconsolidated entries
- `canonical` field holds the generalized display form for the parent
- `pattern` field (compiled regex) enables cheap incoming message matching

When #96 operates alone: `children` is empty or absent (originals are discarded).
When #97 is active: `children` is populated and preserved (originals are kept).
When both compose: children within a group may themselves be consolidated (child-level `is_consolidated` flag), reducing noise while preserving the hierarchical structure.

### DD-04: Observability Interaction with #96

**Decision:** #96 defines a consolidated message indicator (visual prefix character in summary table, boolean in CSV). When #97 is active:

- **Parent rows** are inherently consolidated — they always show the indicator
- **Child rows** show the indicator only if they themselves have been consolidated (composing with #96 within the group)
- **Unconsolidated child rows** do not show the indicator — they represent original, individual messages

This maintains consistent semantics: the indicator always means "this row represents a merged group of similar messages."

## Display

Exact output format TBD during implementation planning. Conceptual model:

```
  Parent: GET /api/v2/* (15,000 hits, avg 245ms)
    ├── GET /api/v2/profile (12,000 hits, avg 180ms)
    ├── GET /api/v2/profile/update (2,500 hits, avg 520ms)
    └── GET /api/v2/settings (500 hits, avg 95ms)
```

Key display questions to resolve:
- How to visually distinguish parent rows from child rows in the summary table
- Whether parent and child rows use the same column layout or a condensed form
- How `-n` (top N) interacts with hierarchy — top N parents? Top N total entries?
- Sorting: by parent aggregate, or mixed parent-child sorting?

## Configuration

| Option | Type | Description |
|--------|------|-------------|
| `--group-detail` | Flag | Enables hierarchical grouping display with child entries visible under parent groups. Implies `--group-similar` (#96) — automatically enables the similarity engine if not explicitly specified. |
| Similarity threshold | Inherited from #96 | Same threshold controls grouping granularity for both consolidation and hierarchy. |

## Open Questions

1. **Display format**: Exact rendering of parent vs child rows in summary table
2. **Interaction with `-n`**: Does top-N count parents, children, or both?
3. **Sorting behavior**: Sort by parent aggregates? Allow sorting within groups?
4. **CSV output**: How to represent hierarchy in CSV format — additional column for group ID? Separate parent/child rows?
5. **Composition UX**: When both `--group-similar` and `--group-detail` are specified explicitly, does `--group-detail` show children that have themselves been consolidated? (Likely yes — the indicators distinguish them.)
