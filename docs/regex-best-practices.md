# Regex Best Practices for Log Analysis

Lessons learned from the #96 Fuzzy Message Consolidation prototype and ltl development.

## Pattern Construction

### Always Anchor
Derived patterns must use both `^` and `$` anchors. Without full anchoring, `.+?foo.+?` matches substrings instead of requiring the complete string to match.

```perl
my $regex = qr/^\Q$literal_prefix\E.+?\Q$literal_suffix\E$/;  # correct
my $regex = qr/\Q$literal_prefix\E.+?\Q$literal_suffix\E/;    # wrong — partial matches
```

### Use quotemeta() for Literals
Log messages contain regex metacharacters (`[]`, `()`, `.`, `?`, `*`, `+`). Always escape literal text with `\Q...\E` or `quotemeta()`.

```perl
# Building from mask: keep positions become \Q...\E, variable positions become .+?
my $pattern = '^';
for each segment:
    if (keep)     { $pattern .= '\Q' . $literal_text . '\E'; }
    if (variable) { $pattern .= '.+?'; }
$pattern .= '$';
my $regex = qr/$pattern/;
```

### Use Non-Greedy Quantifiers
Variable regions between literal anchors must use `.+?` (non-greedy), not `.+` (greedy). Greedy matching consumes too much when multiple variable regions exist:

```
Pattern: ^ErrorCode(.+).+Cause(.+)$    # greedy — first .+ swallows everything
Pattern: ^ErrorCode(.+?).+?Cause(.+?)$ # non-greedy — each region minimal
```

### Validate Derived Patterns
Always verify a derived regex matches its source strings before storing it:

```perl
my $regex = derive_regex($reference, $mask);
next unless ($msg_a =~ $regex) && ($msg_b =~ $regex);  # must match both inputs
```

This catches bugs in mask construction or pattern derivation early.

## Performance

### Pattern Count Is the Key Scaling Factor
Matching cost is `O(lines × patterns)`. For a 300K line file with 50 patterns, that's 15M regex evaluations. Bound pattern count with a hard cap.

### Hot-Sort by Match Frequency
In power-law distributions, the top pattern matches 99%+ of messages. Bubbling frequently-matched patterns to the front of the scan list reduces average scan depth:

```perl
# After a match at index $i, bubble toward front
if ($i > 0) {
    @patterns[$i-1, $i] = @patterns[$i, $i-1];
}
```

### Don't Use Alternation for Many Patterns
Combining 50+ patterns into a single `qr/(?:p1)|(?:p2)|...|(?:pN)/` was benchmarked and found to be:
- **No faster** than a simple Perl loop (1.1× at best, sometimes slower)
- **Fragile** — reconstructing pattern source from `qr//` stringification is version-dependent
- **Hard to debug** — which branch matched? Requires checking N capture groups

For N > ~10 patterns, prefer a simple loop or prefix-based dispatch.

### Inline::C Gives ~5-8× for Tight Match Loops
Moving the match loop to C (using `pregexec()` on Perl's compiled `REGEXP*`) eliminates per-iteration interpreter overhead. However, marshalling costs (copying strings from Perl to C arrays) can negate the gains for single-pattern scans. Best used when:
- The same set of strings is matched against multiple patterns
- The string set is already in a C-accessible format

### Profile Before Optimizing
NYTProf revealed that regex matching was only 2.1% of runtime — the actual bottleneck was posting list iteration in the candidate search (88.1%). Always profile with real data before assuming regex is the performance problem.

## Pattern Reconstruction

### Never Reconstruct from qr// Stringification
Perl's `"$qr_object"` produces `(?^flags:pattern_body)` but the exact format varies across Perl versions. Don't strip wrapper syntax to build alternation patterns:

```perl
# BAD — fragile, version-dependent
my $p = "$pattern";
$p =~ s/^\(\?\^[a-z]*://;
$p =~ s/\)$//;

# GOOD — store source alongside compiled regex
push @patterns, {
    pattern => qr/$source/,
    source  => $source,  # keep the original string
};
```

### Store Pattern Source at Creation Time
If you need to inspect, combine, or reconstruct patterns later, always save the pattern source string when you first compile it. This avoids the stringification problem entirely.

## Common Pitfalls in Log Analysis

### Trigrams Are Better Than Regex for Similarity Search
For finding similar log messages, character trigram indexing with Dice coefficient is orders of magnitude faster than regex-based approaches. Regex is for matching against known patterns; trigrams are for discovering unknown similar pairs.

### Cap Message Length Before Indexing
Log messages can be arbitrarily long. Cap at a reasonable length (e.g., 300 chars) before computing trigrams or building patterns. This bounds both memory and comparison cost without losing discriminative power — the structural part of log messages is almost always in the first 200-300 characters.

### Size Filter Before Expensive Comparison
Before computing Dice coefficient or running regex matches, filter candidates by trigram set size. If source has S trigrams and threshold is T%, candidates must have between `S * T / (200 - T)` and `S * (200 - T) / T` trigrams. This rejects impossible matches cheaply.
