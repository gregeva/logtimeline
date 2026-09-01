# LogTimeLine Classification Reference

This page is the canonical reference for ltl's success/failure classification and the event-ledger property. It mirrors the content of `ltl --explain classification`.

For a long-form explanation directly from the terminal, run `ltl --explain classification`. For which formats classify and how a format declares its rules, run `ltl --help formats`. For the index of available `--explain` topics, run `ltl --explain`.

---

## What it is

Every line ltl includes is classified as a success, a failure, or neither, under rules that belong to the log format that recognised the line. For an access log the rule reads the HTTP status family: 1xx/2xx/3xx are successes and 4xx/5xx are failures. For a diagnostics log (an application or script log) the default rule reads the log level: ERROR, FATAL and CRITICAL are failures, and nothing is declared a success — an INFO line is not evidence that an operation succeeded, only that something was logged. A line the rules say nothing about is *unclassified*: it is neither counted as a success nor as a failure. The run summary shows the totals as `SUCCESS CLASSIFIED` and `FAILURE CLASSIFIED` beneath `LINES INCLUDED`, each with its share of all classified lines; the classification sub-section of `-V format-detection` adds how many lines were unclassified and what share of the included lines they are. A format may also decline to classify altogether (a garbage-collection log, say), in which case no success/failure figure can be produced from it and any consumer says so.

## The event-ledger property

Whether a success/failure figure means anything depends less on the rules than on the log. An *event ledger* is a format with maximum coverage of the operations it describes: every operation of that kind produces exactly one line, so a count over its lines is a count over everything that happened. An access log is an event ledger for requests; a garbage-collection log is one for pauses. A diagnostics log is not: it records what a component chose to write, at whatever level it chose, and says nothing about the operations that produced no line.

This is the coverage argument of the Google SRE Workbook chapter on implementing SLOs (<https://sre.google/workbook/implementing-slos/>): a service-level indicator is a ratio of good events to all events, and the denominator is only honest when the source sees all events. The success percentage — successes over classified lines — is therefore trustworthy at face value only over an event ledger. Each format declares whether it is one, the property is reported per file on `-V format-detection` (`event_ledger`), and consumers that compute a ratio read it to decide whether to show one.

## Operational use

What a diagnostics log can legitimately tell you: how many failure-level lines there were, when they clustered, and which messages produced them — the `errRate` column, and the per-message failure counts in the MESSAGES CSV. What it cannot tell you: a success rate, an availability, or any ratio whose denominator is "all operations", because most operations never wrote a line. The unclassified share is the warning sign: on a diagnostics log it is usually most of the file. On an event ledger the same share is a data-quality figure — lines that carried a status the rules do not cover — and a low value means the ratio can be trusted. The classification is also actionable: `-if`/`-ef` and `-is`/`-es` filter on failures and successes, `-hf`/`-hs` highlight them within the full population, and excluding both (`-ef -es`) leaves exactly the unclassified remainder for inspection.

## Example

```
ltl access.log                         # run summary: SUCCESS CLASSIFIED / FAILURE CLASSIFIED rows with their shares
ltl -V format-detection access.log    # classification sub-section: successes, failures, unclassified share, event_ledger_files
ltl -o -bs 60 access.log               # MESSAGES CSV: successes and failures per message key
```

## How ltl computes this

Classification runs as each line is recognised, so it costs nothing to re-derive later: each format's rules are compiled once at startup into its recognition step, and the outcome is accumulated per time bucket (`errRate` reads the bucket's failure count, normalised to the `-ru` rate unit as before) and per message key (the `successes` and `failures` columns of `-o` CSV, which survive `-g` consolidation). If the detected format changes part-way through a file, lines after the change are classified under the new format's rules, the file's event-ledger property follows the new format, a note names the line and both formats, and `-V format-detection` lists the change. Lines already classified are not revisited. The rules themselves are documented per format under `ltl --help formats`, which also shows how a format declares them.

## See also

`ltl --help formats` (which formats classify, and how a declaration is written), `-lf`, `-V format-detection`, `-ru`.
