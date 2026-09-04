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

**See also.** [Population](#population-population) — where the question usually goes next, once you know when something happened and want to know which part of the traffic it belongs to. [Comparison](#comparison-comparison), for setting one period against another.

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

**See also.** [Shape](#shape-shape) — where the question goes next, once a candidate is in hand and you want to know what its distribution looks like. [Time](#time-time), for placing the same population on the clock.

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

**See also.** [Population](#population-population) — where every technique here starts, since a shape is only readable once a candidate has been picked out. The [histogram](histogram.md) and [heatmap](heatmap.md) references, for the charts these readings are taken from.

---

## Comparison — `comparison`

Setting one body of data against another, whether two periods of the same log or two corpora captured at different times.

**When to use it.** Two questions bring you here. Is this period normal — where the answer comes from folding several periods together so one-off spikes stop looking like the rhythm. And has behaviour changed — where a baseline captured after a go-live is set against current behaviour once users have complained. A third question is comparison down a single column rather than across periods: whether the composition of what is happening is changing while the volume holds steady.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `period-over-period` | Is this period normal, and has behaviour changed since the baseline? |
| `status-composition` | Is the mix changing while the volume holds? |

**See also.** [Time](#time-time) — the folding options these techniques drive are the same ones `traffic-load-profiling` uses, read for a different question. [Correlation](#correlation-correlation), when the two bodies of data are separate files rather than separate periods.

---

## Load — `load`

How much was happening at once. These are the moves that put a quantity rather than a count of lines on the timeline.

**When to use it.** Reach for these when the question is about capacity rather than about a particular call: how many sessions or users were active, whether a pool was sized right, whether a queue was filling. Concurrency is one reading of such a column, not the whole of it — a distinct count is a concurrency measure only where the attribute is held for the duration of the work, and is a population measure otherwise. Any value the log already reports can be drawn the same way once you tell the tool where to find it.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `load-over-time` | How much was in flight, and did it hit a ceiling? |
| `custom-metric` | What does a value the log already reports look like over time? |

**See also.** [Time](#time-time) — a load column is read against the clock, so the bucket width decides what it can show. [Population](#population-population), when the load turns out to come from one part of the traffic.

---

## Correlation — `correlation`

Relating the same system's logs to each other. Where the other groups work within one body of data, these moves ask which part of the input a condition lives in.

**When to use it.** Reach for this when the input is many files rather than one — the same application across a set of nodes, one node across a run of days, or a directory tree you have been handed and have not yet opened. The question is which of them exhibits the condition, and the answer decides which file is worth reading. Because the logs are separated by node, instance or date, a yes or no per file is a statement about a node, an instance or a day.

**Techniques.**

| Technique | The question it answers |
|---|---|
| `cross-log-correlation` | Which of these logs exhibits this condition? |

**See also.** [Population](#population-population) — the criteria that drive this read are the same include, exclude and highlight criteria the population techniques use, applied across files rather than within one. [Comparison](#comparison-comparison), when two corpora are being set against each other rather than surveyed.

---

### Window Narrowing — `window-narrowing`

*What was happening around this moment?*

**The signal.** The timeline with the aperture open over a day, then closed around the point of interest — the same traffic, redrawn to what remains.

**How to read it.** The aperture decides what the timeline is a picture of. Open, it shows the whole file at the default bucket width and tells you where to look; closed around a moment, every row is one slice of that moment and the bars rescale to what remains.

The move runs both ways, and which way you go depends on what you already have. Given a known error time, open the aperture around it — start an hour before and end an hour after — and read what preceded the error rather than the error itself: a rise in volume, a change in the status mix, a slow climb in duration. Given a spike you can already see, close the aperture onto it and drop everything else, so the rows that were one bar become a dozen. Neither direction is the beginning of the investigation more often than the other.

*What falsifies the reading.* Narrowing changes the population, so a rate that rises after the cut has not necessarily risen in the system — the quiet periods that were holding the average down have simply been dropped. Compare a narrowed run against the same figures before the cut, not against your expectation of what normal looks like. The bars, too, are scaled to the largest bucket in view, so the same traffic draws a full-width bar in a quiet window and a short one in a busy one.

**Command.**

```text
ltl -st "2026-05-07 09:00" -et "2026-05-07 11:00" access.log   # what preceded a 10:00 error
ltl -st "2026-05-07 10:45" -et "2026-05-07 11:00" access.log   # close onto the spike itself
```

**See also.** [Time](#time-time) (the grouping this belongs to), `resolution-zoom`, `traffic-load-profiling`, `period-over-period`. Options: `-st`, `-et`, `-bs`, `-pr`.

---

### Resolution Zoom — `resolution-zoom`

*What is inside that bar?*

**The signal.** One hour drawn at three bucket widths in turn — sixty minutes, five minutes, one minute — so the spike that is invisible at the top of the ladder localises to a single row at the bottom.

**How to read it.** A bar is a total, and a total hides its own shape. At the 60-minute default a day is 24 rows and every value is an hour's worth, which is enough to say where to look and nothing more: a peak at 10:00 says nothing about what happens inside that hour.

From there the move alternates two adjustments, and the alternation is the technique. Close the aperture around the peak, then narrow the bucket for what remains, then read the result and decide whether to go again. Still localised to one row means an anomalous occurrence and the ladder continues; spread flat across the whole window means a condition that ran for the whole window, and the answer is already in hand. In the example the hour holds 282 client errors, which at five minutes turns out to be one bucket rather than twelve, and at one minute turns out to be one minute — 220 of them inside sixty seconds.

Watch the two numbers beside each other as you descend. The raw counts fall with the bucket width, because a bucket holds less; the rates beside them are normalised per unit of time and do not, so the message rate holding near 1.8k a minute across two rungs is what says the traffic did not change while the errors did. That pairing is what makes two rungs comparable at all.

Continuing down: tighten the aperture again, drop below the minute with a sub-minute bucket, and raise the timestamp precision to seconds and then milliseconds, until at the finest grain a quarter-second bucket answers whether executions are spread evenly across a second or all land on the second transition.

*What falsifies the reading.* The finest rungs need the log's own timestamps to carry that precision, and a millisecond bucket over second-resolution timestamps invents structure that is not in the data. At very fine widths the normalised rates also become noisy, since one or two observations in a narrow bucket extrapolate to a large per-minute figure; below about a minute, read the counts and treat the rates as indicative.

**Command.**

```text
ltl access.log                                                       # the day at the 60-minute default
ltl -st "2026-05-07 10:00" -et "2026-05-07 11:00" -bs 5 access.log   # the hour, five minutes a row
ltl -st "2026-05-07 10:45" -et "2026-05-07 11:00" -bs 1 access.log   # the quarter hour, a minute a row
ltl -st "2026-05-07 10:50" -et "2026-05-07 10:51" -bs 5s -s access.log  # the minute, five seconds a row
```

**See also.** [Time](#time-time) (the grouping this belongs to), `window-narrowing`, `traffic-load-profiling`. Options: `-st`, `-et`, `-bs`, `-s`, `-ms`, `-ru`.

---

### Traffic Load Profiling — `traffic-load-profiling`

*What does the load look like hour to hour and day to day?*

**The signal.** The timeline folded onto one representative period, so several days draw one day and several weeks draw one week.

**How to read it.** Folding collapses the calendar onto one representative period. What you are reading is the rhythm rather than the events: where the high and low hours fall, where the peak-load periods sit, and whether the errors recur in consistent groupings or arrive at no particular time.

A load profile that rises through the morning, peaks mid-morning and falls away through the evening is a working day; the same profile with a second peak at three in the morning is a batch window, and worth knowing about before anything is concluded from a daytime measurement. Fold by week rather than by day to see which days carry the load, and by working week to drop the weekend from the picture entirely.

The most useful reading is often the one that is absent: an error grouping that survives the fold happens at the same time every day and is scheduled; one that disappears into the average happened once.

*What falsifies the reading.* Folding a single unrepresentative period reproduces its one-off spikes as though they were the rhythm, and the fold gives you no way to tell the two apart. A profile drawn from one week is a description of that week. Fold several, and where the peaks stay put they are the rhythm.

**Command.**

```text
ltl -pr day access.log-*         # the daily rhythm across the set
ltl -pr week access.log-*        # which days carry the load
ltl -pr workweek access.log-*    # the same, weekend dropped
ltl -pr day -bs 15 access.log-*  # a finer profile, 15 minutes a row
```

**See also.** [Time](#time-time) (the grouping this belongs to), `period-over-period`, `window-narrowing`, `load-over-time`. Options: `-pr`, `-bs`, `-st`, `-et`.

---

### Contribution Highlighting — `contribution-highlighting`

*How much of this is that?*

**The signal.** The highlighted run leading each bar, the highlighted twin in the legend and the run summary, and a `TOP HIGHLIGHTED MESSAGES` table beside the overall one.

**How to read it.** A highlight marks part of the population without removing any of it. Three surfaces carry the answer at once. The bars gain a leading run in the highlight colour, so the share a pattern contributes is visible bucket by bucket and you can see whether it is steady or concentrated in one stretch. The legend gains a twin entry carrying the highlighted count beside the family it came from, and the run summary carries the same pair with its percentage. And the matched messages get a table of their own beside the overall one, which is what makes the technique work on small contributors: a pattern that is a fraction of a percent of the traffic will never reach the overall table, but it is the whole of the highlighted one.

This is the discovery move, and it is the safer one to make first. Nothing is removed, so every total, rate and share still describes the system; the highlighted figures sit inside them rather than replacing them. Isolation, which cuts the population down, is what you reach for once you know the pattern is worth isolating.

*What falsifies the reading.* The highlight matches line content, so it can only mark what a line says. It cannot mark lines by the file they came from, so a highlight cannot separate a baseline corpus from a current one within a single run.

**Command.**

```text
ltl -h "/api/v2/checkout" access.log  # how much of the traffic is one endpoint
ltl -h "timeout|refused" app.log      # where two failure words occur
ltl -hdmin 5000 access.log            # mark every request over five seconds
```

**See also.** [Population](#population-population) (the grouping this belongs to), `api-isolation`, `outcome-isolation`, `remainder`, `shape-comparison`. Options: `-h`, `-hdmin`, `-hdmax`, `-hf`, `-hs`, `-hpf`.

---

### API Isolation — `api-isolation`

*What does this call look like on its own?*

**The signal.** The timeline containing only the matching lines: the same hours, redrawn to the isolated call's own scale.

**How to read it.** Isolation drops every line that does not match, so what is left is one call and the timeline is redrawn around it. That is the point: at four per cent of the traffic a call's own shape is invisible inside the population, and isolated it fills the chart.

It is also the precondition for the moves that follow. The attribute exposures are unreadable across a whole population — too many values, too little signal — and become readable the moment the population is one call. So does the shape work: a histogram of everything shows the aggregate of every call mixed together, and a histogram of one call shows that call.

*What falsifies the reading.* Every figure now describes the isolated subset and not the system. The rate is the call's rate, not the traffic's; the bars are scaled to the call's own busiest bucket, so a bar that fills the width means the call's own peak and says nothing about load; and the shares in the run summary are shares of what survived the filter. Read them as answers about the call, and go back to the unfiltered run for anything about the system. If the question is how much of the whole this call accounts for, the move is the highlight, not the isolation.

**Command.**

```text
ltl -i "/api/v2/checkout" access.log                  # only that endpoint
ltl -i "/api/v2/checkout" -hg duration access.log     # its distribution, clear of the rest
ltl -i "/api/v2/checkout" -bs 5 access.log            # its shape over time, five minutes a row
```

**See also.** [Population](#population-population) (the grouping this belongs to), `contribution-highlighting`, `attribute-surfacing`, `rank-then-isolate`, `remainder`. Options: `-i`, `-ipf`, `-e`, `-n`.

---

### Attribute Isolation — `attribute-isolation`

*What is this one session, thread, user, caller or query string doing?*

**The signal.** The timeline cut to, or highlighting, one attribute value — the same move whichever attribute it is.

**How to read it.** An attribute is anything the line carries that identifies the actor rather than the action: a session id, a user name, a thread, a caller address, a query string. The technique is to take one value of one such attribute and act on it — isolate the population to it, mark it within the population, or take it out.

The three are the same move with different consequences, and which one to reach for depends on what you already know. Highlight when you want the value's contribution in context, with every total still describing the system. Isolate when you want the value's own behaviour and are willing to give up the context. Exclude when the value is the known problem and the question is what is left.

It works for any attribute the line carries, which is why the technique is not one per attribute: what you type changes, what you are doing does not. Pair it with `attribute-surfacing`, which is the move that finds the value in the first place — surfacing separates the population by an attribute so the values can be seen, and isolation acts on one of them once it is known.

*What falsifies the reading.* The attribute has to be on the line and has to be part of what the tool matches against. A value that appears in a field the message key does not carry cannot be addressed this way, and a session id that appears on only some of a session's lines will isolate those lines rather than that session.

**Command.**

```text
ltl -h "sess-4BDC7EE2" access.log  # one session inside the population
ltl -i "sess-4BDC7EE2" access.log  # only that session
ltl -e "sess-4BDC7EE2" access.log  # everything but that session
ltl -i "10.0.12.44" access.log     # one caller, when the line carries it
```

**See also.** [Population](#population-population) (the grouping this belongs to), `attribute-surfacing`, `api-isolation`, `contribution-highlighting`. Options: `-i`, `-e`, `-h`, `-xs`, `-xu`, `-xqs`.

---

### Rank then Isolate — `rank-then-isolate`

*Which message should I be looking at?*

**The signal.** The top-messages table ranked two ways — by occurrences, then by total duration — putting different rows at the top.

**How to read it.** The ranked table is the entry point to almost everything else, and the ranking metric decides what it points at. Ranked by occurrences it names the volume contributors: the calls made most often, which is what to look at when the complaint is about load or a system that is busy. Ranked by total duration it names the time contributors: the calls that own the wall clock, which is what to look at when the complaint is that something is slow.

They are usually different rows. In the example the busiest call runs twelve thousand times for fourteen seconds of total time, while the call that owns seven hours of it runs half as often — a ranking by occurrences would never have found it.

Pick the ranking that matches the complaint, take the row at the top, and isolate on it. That pair — rank, then isolate — is how every technique in the shape group begins, because a distribution is only readable once the candidate is on its own. The ranking can also be by any of the statistics, which is what makes the shape techniques reachable: rank by tail-heaviness to find the call with outliers, by asymmetry to find one being cut off at a ceiling.

*What falsifies the reading.* A ranking metric the rows cannot support returns nothing to rank. The shape statistics need several observations per row before they mean anything, so ranking a table of one-request endpoints by tail-heaviness ranks noise. Check the occurrence count of the rows a ranking put at the top before believing the order.

**Command.**

```text
ltl -so occurrences -n 20 access.log            # the volume contributors
ltl -so duration -n 20 access.log               # the time contributors
ltl -so mean -n 20 access.log                   # the slowest per call
ltl -i "<the winner>" -hg duration access.log   # then isolate and look at its shape
```

**See also.** [Population](#population-population) (the grouping this belongs to), `api-isolation`, `tail-excursion`, `bimodal-split`, `timeout-clustering`. Options: `-so`, `-n`, `-sa`, `-i`.

---

### Outcome Isolation — `outcome-isolation`

*Which messages are failing, and is one of them responsible?*

**The signal.** `TOP HIGHLIGHTED MESSAGES` under a failure highlight beside the overall table, with the highlighted twins in the run summary.

**How to read it.** A failure highlight marks every line the format classifies as a failure, and the highlighted message table then names them. That table is the technique: failures are rare by definition, so they are exactly the rows a ranking by occurrences will never reach. In the example the top overall row runs eleven thousand times, while the failing rows run fifty-seven, sixteen and twelve — invisible in any ranking of the population, and the whole content of the highlighted table.

Each arrives with its name, its count and its durations, which is usually enough to say whether the failures are one broken endpoint or spread across many. The run summary carries the same split as highlighted twins beside their families, so the share is there as well as the names.

The classification also filters rather than marks — include only failures to make the whole run about them, or drop both successes and failures to leave exactly the lines the format could not classify, which is the remainder worth reading when the classified pair does not add up.

*What falsifies the reading.* A format that declines to classify produces no outcome at all, and there is nothing for this technique to work on. Where a format does classify, a large unclassified share means the successes and failures are not the whole population and a percentage over them is not a rate over everything that happened. The run summary reports that share; read it before treating a failure percentage as a failure rate.

**Command.**

```text
ltl -hf access.log                      # mark failures, keep the population
ltl -if access.log                      # only the failures
ltl -ef -es access.log                  # the unclassified remainder
ltl -hf -so duration -n 20 access.log   # failures ranked by the time they cost
```

**See also.** [Population](#population-population) (the grouping this belongs to), `status-composition`, `contribution-highlighting`, `rank-then-isolate`. Options: `-hf`, `-hs`, `-if`, `-ef`, `-is`, `-es`. See also the [classification reference](classification.md).

---

### Remainder Analysis — `remainder`

*With the known problem taken out, is what is left healthy?*

**The signal.** The same window before and after one dominant contributor is dropped — and the figures that move when it goes.

**How to read it.** Exclusion answers the question isolation cannot: with the known problem taken out, is what is left healthy? It is not the second half of isolation. Isolation asks what this looks like; subtraction asks what everything else looks like without it, and the two cannot be drawn at the same time.

What makes it worth its own move is the rescaling. A dominant contributor flattens everything beside it, and dropping it lets the rest become readable. In the example, dropping one endpoint takes the total duration in each bucket from around ten minutes to around twenty seconds — that endpoint was almost all of the time — and the whole shape of what remains becomes visible where before it was a flat line at the bottom of the chart.

The shares move too, and for the same reason: the redirect share rises from 0.852% to 1.33% without a single extra redirect, because the denominator shrank. That rescaling is the reading. If what is left looks healthy, the excluded thing was the problem. If what is left has its own peak in the same bucket, it was not.

*What falsifies the reading.* The exclusion removes that traffic from every total and every rate as well as from the chart, so the remainder's figures are not the system's. A share that rises after an exclusion has not risen in the system. Compare the remainder against itself over time, not against the figures from the unfiltered run.

**Command.**

```text
ltl -e "/api/v2/report" access.log              # everything but the known problem
ltl -e "/api/v2/report" -bs 5 access.log        # what is left, at a finer resolution
ltl -e "/health" -e "/favicon.ico" access.log   # drop the noise before reading anything
```

**See also.** [Population](#population-population) (the grouping this belongs to), `api-isolation`, `contribution-highlighting`, `attribute-isolation`. Options: `-e`, `-epf`, `-i`, `-bs`.

---

### Attribute Surfacing — `attribute-surfacing`

*Which user, session or query string inside this one call is producing the errors, the volume or the slow requests?*

**The signal.** One consolidated message row separating into a row per attribute value, each with its own count and durations.

**How to read it.** Consolidation is what makes a message table readable: near-identical lines are grouped so a call appears once with its totals rather than ten thousand times. That is the right default across a population, and it is what hides the answer once a call has been isolated.

Surfacing reverses it for one attribute — keep the session, the user or the query string in the grouping key, and the single consolidated row separates into a row per value, each with its own count and durations. In the example one endpoint at 785 requests becomes four sessions, and the distribution across them is the answer: one session at 683 requests, three others in the hundreds. A single value carrying most of the volume is a different finding from the volume being spread evenly, and the consolidated row cannot tell you which you have. The same applies to time rather than volume — a per-value breakdown of durations says whether one user is experiencing the slowness or all of them are.

*What falsifies the reading.* Run before a call has been isolated, there is too much in the view to read anything from it, because every call separates by every value at once. Isolate first. And the attribute must be on the line: surfacing a field the log does not record produces the consolidated row unchanged, not an error.

**Command.**

```text
ltl -i "/api/v2/device" -xs access.log                 # that call, a row per session
ltl -i "/api/v2/device" -xu access.log                 # a row per user
ltl -i "/api/v2/search" -xqs access.log                # a row per query string
ltl -i "/api/v2/device" -xs -so duration access.log    # which session owns the time
```

**See also.** [Population](#population-population) (the grouping this belongs to), `attribute-isolation`, `api-isolation`, `rank-then-isolate`. Options: `-xs`, `-xu`, `-xqs`, `-i`, `-so`, `-g`.

---

### Tail Excursion vs. Distribution Shift — `tail-excursion`

*Did a few requests become very slow, or did everything become slower?*

**The signal.** Two histograms side by side: a body that has not moved with a thin tail reaching far right, against a body that has moved bodily right.

**How to read it.** Two very different problems produce the same complaint, and the median cannot tell them apart. In a tail excursion the body of the distribution has not moved: most requests are as fast as they ever were, and a small population is suffering something extreme. In a distribution shift the whole body has moved right: nobody is having the old experience any more, and everybody is a little slower. The first is a small number of users having a terrible time; the second is every user having a slightly worse one, and they call for different fixes.

The percentile ladder separates them once you read the whole of it rather than one rung. An excursion shows an unremarkable median and low percentiles with the ladder pulling far apart at the top — in the example the median is 2ms and the 99.9th is 2.8 seconds, three decades away. A shift shows every rung moved together and the spread between them ordinary — a median of 96ms with the 99.9th at 580ms is a body that has moved, not a tail that has grown.

Tail-heaviness is the statistic that makes this rankable rather than something you look for one call at a time: rank the messages by it and the excursions come to the top, then isolate the winner and look at its shape.

*What falsifies the reading.* The two are genuinely indistinguishable in the median and the ninetieth alone, so a reading taken from those two numbers is not this technique whatever it concludes. And tail-heaviness over a handful of observations is noise; check the occurrence count on the rows a ranking put at the top.

**Command.**

```text
ltl -so kurtosis -n 20 access.log               # rank by tail-heaviness
ltl -i "<the winner>" -hg duration access.log   # then look at its shape
ltl -i "<the winner>" -o access.log             # the full percentile ladder
```

**See also.** [Shape](#shape-shape) (the grouping this belongs to), `rank-then-isolate`, `bimodal-split`, `timeout-clustering`, `shape-comparison`. Statistics: [`kurtosis`, `percentiles`](statistics.md). Options: `-so`, `-n`, `-i`, `-hg`.

---

### Bimodal Split — `bimodal-split`

*Is this one behaviour or two mashed together?*

**The signal.** A histogram with two peaks and a valley between them — and the mean sitting in the valley.

**How to read it.** A distribution with two peaks is two behaviours sharing a name. The usual causes are a cache that hits or misses, a fast path and a slow path through the same code, a request served locally or forwarded, a small response and a large one.

What makes the pattern worth its own technique is that the summary statistics actively mislead on it: the mean falls in the valley between the peaks, where almost no request actually lands, and the median falls in whichever peak happens to hold more than half the observations, telling you nothing about the other one. In the example the mean is 34ms, and the histogram shows almost nothing there — a spike at a millisecond and a second peak two decades away, with the space between them nearly empty.

The bimodality coefficient is what makes this rankable: above 0.555 is suspect multimodal, and approaching 1.0 is strongly so. Rank by it, isolate the top row, and read the histogram to see whether the two peaks are really there and how far apart they sit. Once they are confirmed the follow-on move is attribute surfacing: separate the isolated call by session, user or query string and see whether the two peaks are two populations.

*What falsifies the reading.* The coefficient is a screening statistic, not a test. Below about a hundred observations, noise alone clears the threshold routinely, and a genuinely bimodal distribution with very unequal peaks can sit under it. Read the histogram before believing either answer — the chart is the evidence and the coefficient is only what brought you to it.

**Command.**

```text
ltl -so bimodality_coef -n 20 access.log        # rank by the screening statistic
ltl -i "<the winner>" -hg duration access.log   # confirm the two peaks
ltl -i "<the winner>" -xs access.log            # are the peaks two populations?
```

**See also.** [Shape](#shape-shape) (the grouping this belongs to), `rank-then-isolate`, `attribute-surfacing`, `tail-excursion`. Statistics: [`bimodality_coef`](statistics.md). The [histogram reference](histogram.md). Options: `-so`, `-n`, `-i`, `-hg`, `-xs`.

---

### Shape Comparison — `shape-comparison`

*Does this one thing have the same shape as the population, or its own?*

**The signal.** The histogram's two overlaid series and its two percentile ladders — the population's, and the highlighted subset's.

**How to read it.** Every other technique in this group starts from a ranked statistic and looks for a candidate. This one starts with the candidate already in hand and asks how it sits against everything else. Highlight it rather than isolating it, and the histogram draws both: the population's bars with the highlighted subset's overlaid, and two percentile ladders beneath.

Reading the two ladders together is the technique. In the example the population runs from 2ms at the median to a second at the 99th, three decades of spread — a mixture of many different calls, which is what a whole population looks like. The highlighted endpoint reads 1ms at the median and 2ms at the 99.9th: one tight column, a single behaviour with almost no spread at all. That is a call that is not participating in the population's problem.

Had the two ladders sat on top of each other, the call would simply be the population in miniature and nothing about it would be distinctive. Had the subset's ladder sat to the right of the population's at every rung, the call would be uniformly slower than everything around it. The heatmap answers the same question over time rather than in aggregate, which is worth doing when a relationship holds in one part of the day and not another.

*What falsifies the reading.* The comparison is against the population *including* the highlighted subset, not against the rest of it. A subset that is most of the traffic is largely comparing against itself, and the two ladders will agree for that reason rather than because the call is typical. Check the highlighted share in the run summary before reading a close match as a finding.

**Command.**

```text
ltl -h "/api/v2/checkout" -hg duration access.log  # the two ladders, one under the other
ltl -h "/api/v2/checkout" -hm duration access.log  # does the relationship hold over time?
```

**See also.** [Shape](#shape-shape) (the grouping this belongs to), `contribution-highlighting`, `tail-excursion`. The [histogram](histogram.md) and [heatmap](heatmap.md) references. Options: `-h`, `-hg`, `-hm`, `-hgw`.

---

### Timeout Clustering — `timeout-clustering`

*Is something being killed at a ceiling?*

**The signal.** A histogram with a pile at a fixed value rather than a tail, and a percentile ladder whose rungs all read the same number.

**How to read it.** Latency is naturally right-skewed: most requests are quick, a few are slow, and the tail trails away to the right. A cap breaks that shape. Requests that should have run long are cut off at the limit and pile up against it, so instead of a tail there is a wall — a mass of observations at one value with nothing beyond it.

The signature is unmistakable once seen: in the example 1,950 requests all land on the same second, every percentile from the median to the 99.9th reads the same value, and the coefficient of variation is 0.00. A distribution with no spread at all is not a distribution of durations; it is a distribution of one number, which is what a timeout produces.

Asymmetry is the statistic that makes it rankable. Because latency is normally right-skewed, near-zero or negative asymmetry on a call that is slow is the flag: the tail that should be there has been cut off. Rank ascending by asymmetry to bring those rows to the top, isolate the winner and confirm on its histogram. The value the pile sits at is the configured limit, and it is usually recognisable — one second, thirty seconds, two minutes — which is often enough to say which component owns it.

*What falsifies the reading.* A naturally bounded operation is left-skewed without any timeout involved. A call that always does the same fixed amount of work has little spread for honest reasons, and a poll on a fixed interval will cluster at that interval. The question to ask is whether the value the pile sits at is a round configured-looking number and whether requests that should be slower than it exist at all — a cap has nothing beyond the wall, while a naturally bounded operation usually does.

**Command.**

```text
ltl -so skewness -sa -n 20 access.log           # rank ascending: the least right-skewed
ltl -i "<the winner>" -hg duration access.log   # confirm the pile at one value
ltl -i "<the winner>" -so cv -n 5 access.log    # a cv near zero confirms it
```

**See also.** [Shape](#shape-shape) (the grouping this belongs to), `rank-then-isolate`, `tail-excursion`. Statistics: [`skewness`, `cv`](statistics.md). Options: `-so`, `-sa`, `-n`, `-i`, `-hg`.

---

### Period-over-Period Comparison — `period-over-period`

*Is this period normal, and has behaviour changed since the baseline?*

**The signal.** Several periods folded onto one axis — one week, then six — so a peak that belongs to one week separates from a peak that is the rhythm.

**How to read it.** Folding several periods onto one axis serves two different questions, and it is worth knowing which one you are asking.

The first is **normalisation**. A single week may be a poor example of ordinary behaviour — one day carrying an activity that does not normally happen at all — and reading it as though it were the norm produces conclusions about nothing. Folding several weeks together broadens the sample, smooths the one-off spikes and yields a generic profile. In the example one week shows a Wednesday three times the size of every other day; six weeks folded together show five ordinary days, because that Wednesday belonged to one week rather than to the rhythm. Used this way the fold is not good for finding specific things — it is precisely designed to average them away — and it is what to reach for when the question is what the profile generically looks like.

The second is **before and after**. A baseline captured after a go-live or a benchmarking exercise, set against current behaviour once users have complained. Merge both corpora into one run and fold by period: the two align on the same times of day, so you can see whether the high-load periods and the error periods line up between them or whether the current one has grown a peak the baseline did not have.

*What falsifies the reading.* The two corpora cannot be told apart within a single run, because nothing marks a line by the file it came from. The comparison therefore takes a couple of executions — one over each corpus, read side by side — and inferring a difference from two runs is weaker than seeing it in one. And where the two corpora come from machines on different time bases, the fold aligns them by the wall clock each file states, so the periods line up wrongly without anything reporting that they have.

**Command.**

```text
ltl -pr week current/access.log-*    # this period's profile
ltl -pr week baseline/access.log-*   # the baseline's, read beside it
ltl -pr day -bs 15 access.log-*      # several weeks smoothed into one day
```

**See also.** [Comparison](#comparison-comparison) (the grouping this belongs to), `traffic-load-profiling`, `window-narrowing`, `cross-log-correlation`. Options: `-pr`, `-bs`, `-st`, `-et`.

---

### Status Composition Over Time — `status-composition`

*Is the mix changing while the volume holds?*

**The signal.** The per-bucket legend composition, split by a highlight so one call's statuses sit beside the population's in every row.

**How to read it.** A single failure percentage collapses two different events into one number. Two-hundreds giving way to four-hundreds at constant volume is a client population that has started sending something the server rejects; five-hundreds appearing on top of unchanged two-hundreds is a server that has started failing under load it was already carrying. Both move a failure percentage, and only the composition tells them apart.

The legend carries the composition per bucket, and the technique is to read it down the column rather than across one row: which families are present, in what proportion, and how that proportion changes from bucket to bucket while the total volume stays where it was. The shortened totals are what make that possible — a column of comparable magnitudes rather than a column of raw numbers of differing lengths.

Adding a highlight splits each bucket's composition, so one call's statuses sit beside the population's in every row. That is what turns the reading into an attribution: in the example the bucket at 10:50 carries 237 client errors, and 216 of them belong to the highlighted call. The composition said something changed; the highlight said what changed. Where the format supports it, the success and failure percentage columns give the same reading as a ratio per bucket rather than as a set of counts.

*What falsifies the reading.* Those percentages are withheld whenever the classified pair has stopped being the whole population — a classification conflict, a mixed row, or an unclassified line on a format that declares both rules — and the counts are shown instead. A missing percentage is a statement about the data, not a rendering gap, and a percentage read without checking the unclassified share is a ratio over an unknown denominator.

**Command.**

```text
ltl -bs 10 access.log                         # composition per bucket, read down
ltl -h "/api/v2/checkout" -bs 10 access.log   # split it by one call
ltl -hf -bs 10 access.log                     # split it by outcome instead
```

**See also.** [Comparison](#comparison-comparison) (the grouping this belongs to), `outcome-isolation`, `contribution-highlighting`. The [classification reference](classification.md). Options: `-h`, `-bs`, `-hf`, `-hs`, `-hcl`, `-scl`.

---

### Load Over Time — `load-over-time`

*How much was in flight, and did it hit a ceiling?*

**The signal.** A distinct-count column beside the occurrences bar — here a thread pool pinned at its ceiling while throughput falls away underneath it.

**How to read it.** A count of lines says how much work arrived. A distinct count says how much was in flight at once, which is a different question and usually the more useful one when the complaint is about capacity.

Where the log carries a session or a user, those counts appear on their own and are load measures without any further asking: distinct sessions per bucket is concurrent users, and its shape over the day is the load profile the system actually experienced.

Where the log carries a thread name, the thread-pool counts are switched on explicitly, and they answer two questions. Set against the request count they say whether the pool is sized right: a count that rises and falls with demand, well below its maximum, is a pool with headroom. And a count that reaches its maximum and stays there is the bottleneck — in the example the pool sits at exactly 182 in every bucket while throughput falls from 706 a minute to 537, which is a queue forming behind a limit rather than demand falling away. A pool pinned at its ceiling with throughput dropping underneath it is the clearest capacity signal the tool produces.

*What falsifies the reading.* A distinct count is a concurrency measure only where the attribute is held for the duration of the work. A session id that persists for hours counts sessions that exist, not sessions doing anything, and a thread name reused between requests undercounts what was actually in flight. Where the attribute does not have that property the count is still a population measure — how many distinct actors appeared — which is worth reading, but it is not concurrency.

**Command.**

```text
ltl -tpas access.log                  # every pool the log names
ltl -tpa "https-jsse-nio" access.log  # one pool
ltl -tpas -bs 10 access.log           # finer, to see a ceiling being reached
```

**See also.** [Load](#load-load) (the grouping this belongs to), `custom-metric`, `traffic-load-profiling`, `attribute-surfacing`. Options: `-tpa`, `-tpas`, `-bs`, `-xs`, `-xu`.

---

### Custom Metric Tracking — `custom-metric`

*What does a value the log already reports look like over time?*

**The signal.** A monitoring line whose payload is a run of name-and-value pairs, and one of those values drawn as a column of its own beside the occurrences bar.

**How to read it.** Everything else here reads something the tool derives by itself. This one draws a value the log already reports and the tool has no reason to know about. Many logs carry monitoring lines whose payload is a run of name-and-value pairs — a queue depth, a heap size, a connection count, a round-trip time — and each of those is a series waiting to be graphed. Name the value and an aggregation, and it becomes a column beside the occurrences bar, one figure per time bucket, on the same axis as everything else.

Which aggregation to ask for is part of the question. A maximum answers how bad it got and is usually right for a depth or a backlog. A mean answers what it was typically doing and is right for a rate or a latency. A distinct count answers how many different values appeared, which is how a count of actors is built out of a field that names them.

The value is on the same timeline as the requests and the errors, so a queue that fills at the same moment the error rate rises is a relationship you can see rather than infer.

*What falsifies the reading.* A specification that matches nothing is reported after the read, with how it was interpreted, so a metric that silently produces no column is not something you have to discover for yourself — but you do have to read the notice. And a value reported on some lines rather than every line is a sample, not a series: the bucket figure is an aggregate over the lines that happened to carry it, so a monitoring line written every five minutes gives twelve observations an hour whatever the bucket width says.

**Command.**

```text
ltl -udm "queue_depth::max" app.log                   # the worst depth per bucket
ltl -udm "rtt:ms:mean" conn.log                       # a mean round-trip time
ltl -udm "heap:MB:max" -udm "threads::max" app.log    # two metrics, two columns
```

**See also.** [Load](#load-load) (the grouping this belongs to), `load-over-time`, `traffic-load-profiling`. Options: `-udm`, `-ucm`, `-bs`.

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

**See also.** [Correlation](#correlation-correlation) (the grouping this belongs to), `contribution-highlighting`, `outcome-isolation`, `api-isolation`. Options: `-i`, `-e`, `-h`, `-hdmin`, `-hdmax`, `-if`, `-ef`, `-is`, `-es`, `-r`.
