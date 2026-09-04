# LogTimeLine Analysis Techniques Reference

This page is the canonical reference for ltl's analysis techniques: named investigative moves you make with the tool, rather than explanations of a number it prints. It mirrors the content of `ltl --explain <technique>` for each one.

Where the statistics reference answers *what does this number mean*, this page answers *how do I go and find it*. The techniques are organised in six groups. The groups are not a sequence: where an investigation enters depends on the signal that started it, and the path crosses groups freely. Each group page names the group an analyst typically reaches for next.

For the index of available `--explain` topics, run `ltl --explain`. For any technique from the terminal, run `ltl --explain <technique>`.

---

## Time — `time`

Locating behaviour in time. These are the moves that decide which stretch of the log you are looking at and how finely it is divided.

**When to use it.** Where an investigation enters depends on the signal that started it: a named day, a known error time to work outwards from, or nothing more than a suspicion. From any of those the first move is more often to broaden than to narrow — what was happening before the error, whether the same thing happens every day at the same time, how one day compares with another. Only once that broad look is done is it worth closing the aperture and raising the resolution. Reach for these techniques when you need to establish when, or when a signal you have already attributed to part of the traffic needs to be placed on the clock.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `window-narrowing` | What was happening around this moment? |
| `resolution-zoom` | What is inside that bar? |
| `traffic-load-profiling` | What does the load look like hour to hour and day to day? |

**See also.** [Population](#population--population) — where the question usually goes next, once you know when something happened and want to know which part of the traffic it belongs to. [Comparison](#comparison--comparison), for setting one period against another.

---

## Population — `population`

Attributing a signal to a part of the traffic. These are the moves that answer which calls, which attribute values or which outcomes are producing what you are looking at.

**When to use it.** This is where an investigation usually turns, and it generally comes before the time zoom: knowing whether one endpoint accounts for the occurrences or whether they are spread across the whole population changes what a narrower window will tell you. The moves divide into discovery, which keeps the whole population in view and marks part of it, and isolation, which cuts the population down. Discovery first is the safer order — a highlight leaves every total honest, while an isolation rescales everything that follows it.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `contribution-highlighting` | How much of this is that? |
| `api-isolation` | What does this call look like on its own? |
| `attribute-isolation` | What is this one session, thread, user or query string doing? |
| `rank-then-isolate` | Which message should I be looking at? |
| `outcome-isolation` | Which messages are failing, and is one of them responsible? |
| `remainder` | With the known problem taken out, is what is left healthy? |
| `attribute-surfacing` | Which user, session or query string inside this one call is producing it? |

**See also.** [Shape](#shape--shape) — where the question goes next, once a candidate is in hand and you want to know what its distribution looks like. [Time](#time--time), for placing the same population on the clock.

---

## Shape — `shape`

Tails and modality. These are the moves that read the form of a distribution rather than a single value from it.

**When to use it.** Reach for these when a latency figure is unsatisfying and you need to know what is behind it — whether a few requests became very slow or all of them became slower, whether one call is really two behaviours mashed together, whether something is being cut off at a ceiling. The whole-population views cannot answer any of that: across hundreds of thousands of requests the gaps between modes fill in, and there is no telling whether a peak belongs to one call or to the time range. Every technique here therefore enters through a ranked message table, on a candidate already isolated.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `tail-excursion` | Did a few requests become very slow, or did everything become slower? |
| `bimodal-split` | Is this one behaviour or two mashed together? |
| `shape-comparison` | Does this one thing have the same shape as the population, or its own? |
| `timeout-clustering` | Is something being killed at a ceiling? |

**See also.** [Population](#population--population) — where every technique here starts, since a shape is only readable once a candidate has been picked out. The [histogram](histogram.md) and [heatmap](heatmap.md) references, for the charts these readings are taken from.

---

## Comparison — `comparison`

Setting one body of data against another, whether two periods of the same log or two corpora captured at different times.

**When to use it.** Two questions bring you here. Is this period normal — where the answer comes from folding several periods together so one-off spikes stop looking like the rhythm. And has behaviour changed — where a baseline captured after a go-live is set against current behaviour once users have complained. A third question is comparison down a single column rather than across periods: whether the composition of what is happening is changing while the volume holds steady.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `period-over-period` | Is this period normal, and has behaviour changed since the baseline? |
| `status-composition` | Is the mix changing while the volume holds? |

**See also.** [Time](#time--time) — the folding options these techniques drive are the same ones `traffic-load-profiling` uses, read for a different question. [Correlation](#correlation--correlation), when the two bodies of data are separate files rather than separate periods.

---

## Load — `load`

How much was happening at once. These are the moves that put a quantity rather than a count of lines on the timeline.

**When to use it.** Reach for these when the question is about capacity rather than about a particular call: how many sessions or users were active, whether a pool was sized right, whether a queue was filling. Concurrency is one reading of such a column, not the whole of it — a distinct count is a concurrency measure only where the attribute is held for the duration of the work, and is a population measure otherwise. Any value the log already reports can be drawn the same way once you tell the tool where to find it.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `load-over-time` | How much was in flight, and did it hit a ceiling? |
| `custom-metric` | What does a value the log already reports look like over time? |

**See also.** [Time](#time--time) — a load column is read against the clock, so the bucket width decides what it can show. [Population](#population--population), when the load turns out to come from one part of the traffic.

---

## Correlation — `correlation`

Relating the same system's logs to each other. Where the other groups work within one body of data, these moves ask which part of the input a condition lives in.

**When to use it.** Reach for this when the input is many files rather than one — the same application across a set of nodes, one node across a run of days, or a directory tree you have been handed and have not yet opened. The question is which of them exhibits the condition, and the answer decides which file is worth reading. Because the logs are separated by node, instance or date, a yes or no per file is a statement about a node, an instance or a day.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `cross-log-correlation` | Which of these logs exhibits this condition? |

**See also.** [Population](#population--population) — the criteria that drive this read are the same include, exclude and highlight criteria the population techniques use, applied across files rather than within one. [Comparison](#comparison--comparison), when two corpora are being set against each other rather than surveyed.

---

### Cross-Log Correlation — `cross-log-correlation`

*Which of these logs exhibits this condition?*

**The signal.** The marker column in the run summary's file list. Each file the run processed is listed with a marker ahead of its name:

```text
These file(s) were processed with analysis including results between

[√] node-01/localhost_access_log.2026-05-05.txt  [1]     green tick on a bright-green background
[√] node-02/localhost_access_log.2026-05-05.txt  [1]     plain green tick
[χ] node-03/localhost_access_log.2026-05-05.txt  [1]     red chi
[√] node-04/localhost_access_log.2026-05-05.txt  [1]     green tick on a bright-green background
```

**How to read it.** Every file the run processed is listed, and the marker ahead of its name says what that file contributed. A green tick means the file contributed lines that survived the filters. A green tick on a bright-green background means it also contributed a line the highlight criteria matched — that is the file the condition is actually in. A red chi means the file contributed nothing: it was read, and none of its lines came through.

Read the column, not the names: over a set of node logs it tells you which nodes are affected, over a run of daily files which days, and under `-r` over a directory tree the answer names a folder as readily as a file.

Every include, exclude and highlight criterion the tool has drives the markers, not just a text pattern: a duration threshold answers which files carried requests slower than a minute, a failure filter reduces the run to the files that contain failures, and a bytes threshold answers which of them served the large responses.

*What falsifies the reading.* A red chi is ambiguous on its own. It means the file holds no line matching the criteria — which is a different finding from the file holding no such line at all, because an include filter, a time window or a profile fold may have removed it before the criteria were ever applied. Check the run summary's included-lines count against the lines read before concluding a node is clean. One further caution: where the files come from machines on different time bases, the timeline aligns them by the wall clock each file states, so a correlation across mixed offsets is wrong without being reported as wrong.

**Command.**

```text
ltl -hdmin 60000 node-*/access.2026-05-05.log  # which nodes served a slow request
ltl -hf node-*/access.2026-05-05.log           # which nodes produced failures
ltl -h "/api/v2/checkout" -r logs/             # which file in the tree carries it
ltl -i "OutOfMemory" -r logs/                  # reduce the run to matching files
```

**See also.** [Correlation](#correlation--correlation) (the grouping this belongs to), `contribution-highlighting`, `outcome-isolation`, `api-isolation`. Options: `-i`, `-e`, `-h`, `-hdmin`, `-hdmax`, `-if`, `-ef`, `-is`, `-es`, `-r`.
