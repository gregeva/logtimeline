# Candidate search for trigram Dice consolidation: industry grounding

Primary-source research on exact and approximate candidate generation for set-similarity joins, and on how log template miners remove per-line variable tokens. It grounds the consolidation candidate pre-filter examined in `features/fuzzy-message-consolidation.md` § Finding: no groupings on keys whose rarest trigrams are per-request values (#569), whose facts (distinct trigrams per key, Dice threshold T, a per-batch inverted index, rarest-first ordering by posting-list size, top K = 50 kept, at least 15 of those required) are the ones mapped in the last section.

## Sources read (full text)

| Short name | Citation | URL |
|---|---|---|
| PPJoin (WWW'08) | C. Xiao, W. Wang, X. Lin, J. X. Yu. *Efficient Similarity Joins for Near Duplicate Detection.* WWW 2008, pp. 131-140 | https://rutgers-db.github.io/cs541-fall19/paper/prefixfilter.pdf (mirror; ACM: https://dl.acm.org/doi/10.1145/1367497.1367516) |
| AllPairs | R. J. Bayardo, Y. Ma, R. Srikant. *Scaling Up All Pairs Similarity Search.* WWW 2007, pp. 131-140 | https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/32781.pdf |
| Mann 2016 | W. Mann, N. Augsten, P. Bouros. *An Empirical Evaluation of Set Similarity Join Techniques.* PVLDB 9(9), 2016, pp. 636-647 | https://www.vldb.org/pvldb/vol9/p636-mann.pdf |
| AdaptJoin | J. Wang, G. Li, J. Feng. *Can We Beat the Prefix Filtering? An Adaptive Framework for Similarity Join and Search.* SIGMOD 2012, pp. 85-96 | https://www2.cs.sfu.ca/~jnwang/papers/sigmod2012-adaptjoin.pdf |
| Gravano 2001 | L. Gravano, P. G. Ipeirotis, H. V. Jagadish, N. Koudas, S. Muthukrishnan, D. Srivastava. *Approximate String Joins in a Database (Almost) for Free.* VLDB 2001, pp. 491-500 | https://ipeirotis.org/wp-content/uploads/2012/01/vldb2001.pdf |
| MMDS ch. 3 | J. Leskovec, A. Rajaraman, J. D. Ullman. *Mining of Massive Datasets*, Chapter 3 "Finding Similar Items" | http://infolab.stanford.edu/~ullman/mmds/ch3.pdf |
| ER survey | G. Papadakis, D. Skoutas, E. Thanos, T. Palpanas. *A Survey of Blocking and Filtering Techniques for Entity Resolution.* arXiv:1905.06167 (ACM CSUR version, 2020) | https://arxiv.org/pdf/1905.06167 |
| Drain | P. He, J. Zhu, Z. Zheng, M. R. Lyu. *Drain: An Online Log Parsing Approach with Fixed Depth Tree.* ICWS 2017, pp. 33-40 | https://jiemingzhu.github.io/pub/pjhe_icws2017.pdf |
| Spell | M. Du, F. Li. *Spell: Streaming Parsing of System Event Logs.* ICDM 2016 | https://www.cs.utah.edu/~lifeifei/papers/spell.pdf |
| LogMine | H. Hamooni, B. Debnath, J. Xu, H. Zhang, G. Jiang, A. Mueen. *LogMine: Fast Pattern Recognition for Log Analytics.* CIKM 2016 | https://www.cs.unm.edu/~mueen/Papers/LogMine.pdf |
| Zhu 2019 | J. Zhu, S. He, J. Liu, P. He, Q. Xie, Z. Zheng, M. R. Lyu. *Tools and Benchmarks for Automated Log Parsing.* ICSE-SEIP 2019 | https://arxiv.org/pdf/1811.03509 |

Not retrieved:
- The journal version of PPJoin (Xiao, Wang, Lin, Yu, Wang, *ACM TODS* 36(3), 2011, https://dl.acm.org/doi/10.1145/2000824.2000825). The author's server returned HTTP 403. Anything that version adds, such as Dice-specific formulas, is **UNVERIFIED**.
- Chaudhuri, Ganti and Kaushik 2006, the SSJoin paper that introduced the prefix filter. Mann 2016 cites it as reference [5] and the ER survey as [22]. It was not read.

Notation in quotes follows each source. The PDF text extraction garbles some typeset tables; where a formula was reconstructed from a garbled table, this is stated.

---

## 1. Prefix filtering

### 1.1 The principle, as stated

**PPJoin (WWW'08), Section 3, Lemma 1 (Prefix Filtering Principle)**, which PPJoin re-phrases from Chaudhuri et al.:

> "Consider an ordering O of the token universe U and a set of records, each with tokens sorted in the order of O. Let the p-prefix of a record x be the first p tokens of x. If O(x, y) ≥ α, then the (|x| − α + 1)-prefix of x and the (|y| − α + 1)-prefix of y must share at least one token."

**Only one shared token is required.** Lemma 1 says "at least one token". Mann 2016, Section 2.1 (p. 637), says the same thing for an overlap threshold t: "if |r∩s| ≥ t, then there is at least one common token within the πr-prefix of r and the πs-prefix of s, where πr = |r| − t + 1 and πs = |s| − t + 1." Their intuition, from the same section: the tokens left outside the prefix "can contribute at most [|r| − π] matches to the overlap, which is not enough."

**No false negatives.** PPJoin Section 3: "The candidate pairs are those that have the potential of meeting the similarity threshold and are guaranteed to be a superset of the final answer due to the prefix filtering principle." With the indexing prefix below, the method "does not miss any similarity join result."

### 1.2 From a normalised threshold to an overlap, and the prefix lengths

**Jaccard, PPJoin Section 2.2, Equations (1) and (3):**

> J(x, y) ≥ t ⟺ O(x, y) ≥ α = t/(1+t) · (|x| + |y|)   (1)
> J(x, y) ≥ t ⟹ t · |x| ≤ |y|   (3)

**Jaccard prefix lengths, PPJoin Section 3 and Section 4.3:**
- Probing and indexing prefix (Section 3): "we only need to index a prefix of length |x| − ⌈t · |x|⌉ + 1 for every record x to ensure the prefix filtering-based method does not miss any similarity join result."
- Lemma 3 (Section 4.3): "Given a record x, we only need to index its (|x| − ⌈2t/(1+t) · |x|⌉ + 1)-prefix for Algorithm 1 to produce correct join result." Section 4.3 adds: "the length of the prefix used for probing into the indices remains the same." Lemma 3 relies on Algorithm 1 processing records "sorted in the ascending order of their sizes" (Section 4.2).

**Cosine, PPJoin Section 6:**

> C(x, y) ≥ t ⟺ O(x, y) ≥ ⌈t · √(|x| · |y|)⌉. "The length of the prefix for a record x is |x| − ⌈t² · |x|⌉ + 1, yet the length of the tokens to be indexed can be optimized to |x| − ⌈t · |x|⌉ + 1. The size filtering threshold is ⌈t² · |x|⌉."

Footnote 2 of the same section: "These are the same bounds obtained in [3]", where [3] is AllPairs. For binary vectors, AllPairs Figure 4 (Section 4.5) sets `minsize ← |x| · t²`.

**Overlap, PPJoin Section 6:** "The prefix length for a record x will be x − α + 1. The size filtering threshold is α."

**All four measures, Mann 2016, Table 1 (p. 638).** The table is attributed to their reference [9]. It was reconstructed from garbled extraction, and the Jaccard and cosine rows cross-check against PPJoin.

| Measure | Definition | eqoverlap(r, s) | lb_r (minimum partner size) | ub_r (maximum partner size) |
|---|---|---|---|---|
| Jaccard | \|r∩s\| / \|r∪s\| | tJ/(1+tJ) · (\|r\| + \|s\|) | tJ · \|r\| | \|r\| / tJ |
| Cosine | \|r∩s\| / √(\|r\|·\|s\|) | tC · √(\|r\|·\|s\|) | tC² · \|r\| | \|r\| / tC² |
| Dice | 2·\|r∩s\| / (\|r\| + \|s\|) | tD · (\|r\| + \|s\|) / 2 | tD · \|r\| / (2 − tD) | (2 − tD) · \|r\| / tD |
| Overlap | \|r∩s\| | tO | tO | ∞ |

Mann 2016, Section 2.2, gives the prefix sizes used by all the algorithms they tested:
- Probing: "The prefix size is πr = |r| − ⌈eqoverlap(r, s)⌉ + 1. Since the size of s is not known when πr is computed, |s| = lbr is assumed to get an upper bound for the prefix size. With |s| = lbr we get eqoverlap(r, s) = lbr, thus the prefix size is πr = |r| − ⌈lbr⌉ + 1."
- Indexing in a self-join, where sets are processed in increasing size order: "This allows us to use shorter prefixes of size |r| − ⌈eqoverlap(r, r)⌉ + 1 for indexing [21]."

**Where the sources differ or are silent:**
- The WWW'08 PPJoin paper does not give Dice. The Dice row above comes only from Mann 2016 Table 1. Whether the TODS 2011 PPJoin version gives Dice is **UNVERIFIED**.
- The sources do not disagree on any formula. They differ in which prefix they call "the" prefix:
  - PPJoin Section 3 indexes |x| − ⌈t|x|⌉ + 1.
  - PPJoin Lemma 3 shortens only the index side, to |x| − ⌈2t/(1+t)|x|⌉ + 1, and only under size-ordered processing.
  - Mann writes the same two quantities generically as |r| − ⌈lb_r⌉ + 1 for probing and |r| − ⌈eqoverlap(r, r)⌉ + 1 for indexing.
  - For Jaccard, lb_r = t|r| and eqoverlap(r, r) = 2t/(1+t)·|r|, which are PPJoin's two expressions.
- AllPairs does not state a closed-form prefix length. It indexes features until an accumulated score bound reaches t (Section 4.2: "maintains a trivial upperbound b on the score attainable by matching the first features of the current vector against any other vector ... As soon as this upperbound exceeds t, it begins indexing the remaining features"). PPJoin says the resulting bounds match its own (footnote 2).

### 1.3 Why tokens are ordered by increasing frequency

- **PPJoin, Section 2.1:** "A document frequency ordering O_df arranges tokens in U according to the increasing order of tokens' document frequencies."
- **PPJoin, Section 4.2:** "The document frequency ordering O_df is often used to canonicalize the records. It favors rare tokens in the prefixes and hence results in a small candidate size and fast execution speed."
- **AllPairs, Section 4.2:** "The frequency-based feature ordering is not required for correctness; its effect is to heuristically minimize the length of the inverted lists."
- **Mann 2016, Section 2.2:** "the tokens are sorted by their frequency in the collections such that the prefixes are formed by infrequent tokens."
- **Global ordering is a prerequisite, not an optimisation.** Lemma 1 requires that both records be "sorted in the order of O", and PPJoin Section 4.1 says "a global ordering is a prerequisite of prefix filtering". The frequency direction of that ordering is the heuristic.

### 1.4 Prefix lengths for a 286-token set at Dice thresholds

**Conversion used.** Mann's Table 1 Dice row is used directly. The Jaccard equivalent is tJ = tD / (2 − tD), from D = 2I/(|r| + |s|) and J = I/(|r| + |s| − I), where I is the intersection size. The conversion is consistent with the table: substituting tJ = tD/(2 − tD) into the Jaccard row gives
- lb = tJ·|r| = tD·|r|/(2 − tD), and
- eqoverlap = tJ/(1+tJ)·(|r| + |s|) = tD/2·(|r| + |s|),

which are exactly the Dice row. So PPJoin's Jaccard formula |x| − ⌈tJ·|x|⌉ + 1 and Mann's Dice formula |r| − ⌈tD|r|/(2 − tD)⌉ + 1 give the same numbers.

The table is computed with exact rational arithmetic, n = |r| = 286:
- **Probing prefix:** 286 − ⌈lb⌉ + 1. This is the one that applies when the partner's size is unknown.
- **Size-ordered index prefix:** 286 − ⌈tD·286⌉ + 1.

| Dice tD | Jaccard tJ | lb = tD·286/(2−tD) | ⌈lb⌉ | Probing prefix | ⌈tD·286⌉ | Index prefix (size-ordered self-join) |
|---|---|---|---|---|---|---|
| 0.50 | 0.3333 | 95.33 | 96 | **191** | 143 | 144 |
| 0.60 | 0.4286 | 122.57 | 123 | **164** | 172 | 115 |
| 0.70 | 0.5385 | 154.00 | 154 | **133** | 201 | 86 |
| 0.75 | 0.6000 | 171.60 | 172 | **115** | 215 | 72 |
| 0.80 | 0.6667 | 190.67 | 191 | **96** | 229 | 58 |
| 0.85 | 0.7391 | 211.39 | 212 | **75** | 244 | 43 |
| 0.90 | 0.8182 | 234.00 | 234 | **53** | 258 | 29 |
| 0.95 | 0.9048 | 258.76 | 259 | **28** | 272 | 15 |

Length filter bounds for the same set, from Mann's lb_r and ub_r. At tD = 0.75, 171.6 ≤ |s| ≤ 476.7. This is derived arithmetic.

---

## 2. Length, positional, suffix and count filters

| Filter | Source | What it prunes | Cost as reported |
|---|---|---|---|
| **Length (size) filter** | PPJoin Eq. (3); Mann Section 2.1 and Table 1 ("Set r can reach Jaccard threshold tJ only with a set s of size lbr ≤ \|s\| ≤ ubr"); AllPairs Section 4.4 "minsize" | Partners whose size is outside [lb_r, ub_r] | Close to free. Mann Section 2.2: inverted-list entries are "sorted by increasing set size", so the lists "are cropped (1b) using the length filter" during lookup. AllPairs Section 4.4 removes entries permanently as minsize grows. |
| **Positional filter** | PPJoin Section 4.1, Lemma 2 | Pre-candidates that share a prefix token, but whose remaining tokens after the match position cannot supply the missing overlap | One stored position per posting entry (Mann Section 3: without positions the ALL lists shrink "by 50%"). Mann's implementation applies it "only to the first match in the prefix", which "reduces the overhead ... particularly relevant when only a small number of pre-candidates can be filtered". |
| **Suffix filter** (PPJoin+) | PPJoin Section 5, Algorithm 3, Eq. (4) | Candidates that survive prefix and positional filtering. It recursively partitions both suffixes around a pivot and lower-bounds their Hamming distance. | Bounded recursion (MAXDEPTH). PPJoin: "aimed to strike a balance between filtering power and filtering overhead", with partitioning by binary search, "O(log \|xs\|)", narrowed to a window. MAXDEPTH = 2 in PPJoin's experiments (Section 7) and in Mann. Mann Section 5.4: the suffix filter is "constant (2^Maxdepth)" but "always slower" than verification. |
| **Count filter** (q-grams, edit distance) | Gravano 2001, Section 3.3, Proposition 3.1 | Pairs sharing too few q-grams to be within edit distance k | Written as SQL GROUP BY / HAVING COUNT(*) over a positional q-gram table (Figure 1). No prefix, so every shared q-gram is joined. |
| **Position filter** (q-grams) | Gravano 2001, Proposition 3.2 | q-gram matches whose positions differ by more than k | One predicate in the same join |
| **Length filter** (strings) | Gravano 2001, Proposition 3.3 | String pairs whose lengths differ by more than k | One predicate |

Exact statements:

- **PPJoin Lemma 2 (Positional Filtering Principle):** "Let token w = x[i], w partitions the record into the left partition xl(w) = x[1..(i − 1)] and the right partition xr(w) = x[i..|x|]. If O(x, y) ≥ α, then for every token w ∈ x∩y, O(xl(w), yl(w)) + min(|xr(w)|, |yr(w)|) ≥ α." In Algorithm 1, a pair is kept as a candidate only if A[y] + ubound ≥ α, where ubound ← 1 + min(|x| − i, |y| − j).
- **PPJoin Eq. (4), suffix filter bound:** H(xs, ys) ≤ Hmax = 2|x| − 2⌈t/(1+t) · (|x| + |y|)⌉ − (⌈t·|x|⌉ − ⌈t·|y|⌉).
- **Gravano Proposition 3.1 (count filter):** "If σ1 and σ2 are within an edit distance of k, then the cardinality of Gσ1 ∩ Gσ2, ignoring positional information, must be at least max(|σ1|, |σ2|) − 1 − (k − 1) ∗ q."
  - G is built over the string extended with q − 1 padding characters on each side (Section 2.2), which gives |σ| + q − 1 q-grams (Section 3.2).
  - PPJoin Section 6 writes the same bound as α = (max(|u|, |v|) + q − 1) − qδ. That is algebraically identical to Gravano's form.
  - It is an **edit-distance** bound, not a Dice bound. The Dice analogue is eqoverlap in Table 1.
- **Positional filter effect on q-gram data (PPJoin Table 1, DBLP Jaccard candidate counts):**

  | Jaccard threshold | All-Pairs | ppjoin | ppjoin+ |
  |---|---|---|---|
  | 0.95 | 199,268 | 176,971 | 32,397 |
  | 0.90 | 1,857,987 | 657,200 | 36,318 |

  PPJoin Section 5.1: candidate size still grows "quadratically" with data size, and the reduction does not change that growth rate.
- **PPJoin Section 7, trend over thresholds:** "The general trend is that the speed-up increases with the decrease of the similarity threshold", because "inverted lists in the indices are longer for a lower similarity threshold". Also: "All-Pairs algorithm is not good at dealing with long records and/or a small token domain."

---

## 3. Empirical comparison (Mann, Augsten, Bouros 2016)

Setup (Sections 3-5):
- Seven algorithms, re-implemented in C++: AllPairs (ALL), PPJoin (PPJ), PPJoin+ (PP+), MPJoin (MPJ), MPJoin-PEL (PEL), AdaptJoin (ADP), GroupJoin (GRP).
- Ten real datasets and two synthetic. DBLP uses character bigrams, q = 2.
- Jaccard thresholds 0.50 to 0.95. Cosine and Dice were also run, with "little difference w.r.t. Jaccard ... since all normalized thresholds are translated into overlap thresholds" (Section 5.1).

Findings, quoted:

1. **The prefix filter is the key technique; plain AllPairs stays competitive.** From the abstract: "The key technique is the prefix filter, and AllPairs, the first algorithm adopting this techniques is still a relevant competitor." Section 5.1: "ALL wins on most data points (31), followed by PPJ (21), GRP (16), ADP (12), PEL (12), and MPJ (6)."
2. **Verification is cheap.** Introduction: "the number of required comparisons in the merge-like verification routine is a small constant (often 2 or less, 18 at most) that is independent of the set size." The routine is Algorithm 1, a merge with early termination on either side's remaining maximum.
3. **Sophisticated filters do not pay off.** Introduction: "expensive filters do not pay off: we measure the slowest runtimes for AdaptJoin and PPJoin+, which apply the most sophisticated filters and produce the smallest candidate sets." Section 5.3: "These filters only pay off if they are much faster on false positives than verification. Note that true positives must still go through verification: any filter effort on them is lost."
4. **Suffix filter.** Section 5.4: "PP+ never wins and cannot compete with the best algorithms."
5. **Low versus high thresholds.** Section 5.1: "ALL and GRP tend to be faster on large thresholds, while PPJ and ADP perform the best on small thresholds ... For large thresholds the prefix filter ... is very effective, leading to pre-candidates with a small percentage of false positives. ... On small thresholds, however, filtering pre-candidates pays off." Section 5.2: "the pre-candidate filters are typically more effective on small thresholds, e.g., PEL reduces #pre by less than 1% (20%) for tJ = 0.95, but 23% (71%) for tJ = 0.5 on AOL (ENRON)."
6. **Cost of candidate generation.** Section 5.2: "In many cases, #lookups ≪ #pre, and the candidate time mainly depends on the number of pre-candidates." At tJ = 0.95, "#lookups ∼ #pre", and lookups then add a visible runtime offset. Conclusions: "we do not expect significant impact from future techniques that sit on top of the prefix filter, but see opportunities in fast candidate generation."
7. **Token distribution decides whether the prefix filter works.**
   - Section 4: "Most datasets ... show a Zipf-like distribution and contain a large number of infrequent tokens (less than 10 occurrences), which favors the prefix filter. In contrast, NETFLIX has almost no tokens that occur less than 100 times."
   - Section 5.5: "When there are few infrequent tokens in the dataset (BMS-POS, DBLP, NETFLIX ...), the prefix filter generates many false positives; on these datasets ADP wins on some thresholds." Also: "On Zipf-like distributions, the prefix filter performs very well and the extended prefix does not pay off."
8. **Sorting.** Section 5.7: lexicographic sorting of equal-size sets helps all algorithms, mostly through cache locality ("10 times more cache misses for shuffled input").

The ER survey, Section 5.4, summarises the same study and adds a result from Jiang et al. 2014 (not read here): "PPJoin(+) and AdaptJoin perform better in datasets with Zipfian distribution than uniform one." It also states: "The core idea of prefix filtering is to select rare tokens as signatures so as to reduce the number of candidates."

---

## 4. MinHash and LSH (MMDS Chapter 3)

- **MinHash and Jaccard, Section 3.3.3:** "The probability that the minhash function for a random permutation of rows produces the same value for two sets equals the Jaccard similarity of those sets."
- **Banding, Section 3.4.2.** With b bands of r rows each, a pair with Jaccard similarity s becomes a candidate with probability **1 − (1 − s^r)^b**. The function "has the form of an S-curve" (Figure 3.7). "An approximation to the threshold is (1/b)^(1/r)."
- **Worked values, Example 3.11 and Figure 3.8 (b = 20, r = 5, signature length 100):**

  | s | 0.2 | 0.3 | 0.4 | 0.5 | 0.6 | 0.7 | 0.8 |
  |---|---|---|---|---|---|---|---|
  | P(candidate) | .006 | .047 | .186 | .470 | .802 | .975 | .9996 |

  At s = 0.8, "Only roughly one in 3000 pairs that are as high as 80% similar will fail to become a candidate pair and thus be a false negative."
- **Choosing b and r, Section 3.4.3, step 4:** "Pick a number of bands b and a number of rows r such that br = n, and the threshold t is approximately (1/b)^(1/r). If avoidance of false negatives is important, you may wish to select b and r to produce a threshold lower than t; if speed is important and you wish to limit false positives, select b and r to produce a higher threshold." The same section: "this approach can produce false negatives".
- **Memory, Example 3.9:** "signatures of length 250. Then we use 1000 bytes per document for the signatures", which is 4 bytes per minhash value. At that rate, the b = 20, r = 5 scheme (100 minhashes) is 400 bytes per key. That figure is derived arithmetic.
- **Shingle size and stop words, Sections 3.2.2 and 3.2.4:** k = 5 is suggested for e-mails and k = 9 for large documents. A news-article variant forms shingles from "a stop word followed by the next two words". Both are guidance for documents, not for log keys.
- **Per-line random tokens (derived from Section 3.3.3, not stated by MMDS for this case).**
  - The collision probability equals Jaccard over the whole set, and every shingle is treated identically.
  - Per-line unique trigrams therefore lower the estimated similarity exactly as much as they lower true Jaccard. MinHash has no mechanism to discount them.
  - Dice 0.75-0.81 is Jaccard 0.60-0.68. From Figure 3.8, b = 20 / r = 5 would miss about 20% of pairs at s = 0.6 (1 − .802) and 2.5% at s = 0.7.
  - Random pairs at Dice 0.60-0.82 (Jaccard 0.43-0.69) fall on the rising part of the same S-curve.

---

## 5. Unique tokens and very frequent tokens

What the sources say:
- **The rare-feature hypothesis and where it weakens (PPJoin, Section 1):** prefix filtering "hinges on the hypothesis that similar objects are likely to share rare 'features' (e.g., rare words in a collection of documents). This hypothesis might be weakened for problems with a low similarity threshold or with a restricted feature domain."
- **Very frequent tokens (PPJoin, Section 3):** "the inverted lists of some tokens, often known as 'stop words', can be very long. These long inverted lists incur significant overhead for building and accessing them." Prefix filtering avoids them by ordering: only the rarest tokens of each record are indexed (Section 1.3 above).
- **Infrequent tokens help (Mann 2016, Sections 4 and 5.5):** a large share of tokens with fewer than 10 occurrences "favors the prefix filter". Few infrequent tokens make it generate "many false positives". See Section 3, finding 7.
- **Blocking methods that adapt to the frequency distribution (ER survey, Sections 3.3 and 4.1):**
  - Token Blocking: "Assuming that duplicates share at least one common token ... A block b_t is then defined for every distinct token t."
  - Block Purging and Block Filtering: "the larger a block is, the less likely it is to contain unique duplicates ... Such large blocks ... correspond to stop words. In this context, Block Purging discards blocks that exceed an upper limit on block cardinality or size. Block Filtering applies this assumption to individual entities, removing every entity from the largest blocks that contain it. In other words, it retains every entity in r% of its smallest blocks."
  - These are lossy (blocking) techniques, not exact filters.
- **Adaptive prefix length from the data (AdaptJoin, Section 3, Eq. (1), Lemma 1, Lemma 2, Figure 4; section number UNVERIFIED):**
  - Cost of the ℓ-prefix scheme: Θ_ℓ = Σ_r Σ_{e∈Pℓ(r)} |Iℓ(e)| + Σ_r cost_v(r)·|Cℓ(r)|. The first term is the summed inverted-list lengths; the second is the verification cost of the candidates.
  - "a fixed prefix scheme may not always achieve the highest performance. ... we do not need to fix the prefix length for all objects. Instead we can select different prefix lengths for different objects."
  - Mann's description of the scheme (Section 2.3): "a pair (r, s) is pruned if there are less than e token matches in the (πr + e − 1)-prefix of r and the (πs + e − 1)-prefix of s ... For the standard prefix filter, e = 1. ADP computes e per probing set using a cost function."
  - AdaptJoin estimates |Cℓ(r)| by sampling (Theorem 1), so the cost model reads the dataset's list lengths.
- **Per-message token frequency in log parsing:** Zhu 2019, Section II.C: "LFA considers the token frequency distribution in each log message instead of the whole log data to parse rare log messages."

**UNVERIFIED:** no source read here states in so many words that a token occurring in only one record is useless for candidate generation. The closest are:
- Token Blocking's premise that duplicates share a token (a token whose block holds one entity yields no pair), and
- Lemma 1 itself, under which such a token can never be the shared prefix token.

Both readings are derivations, not quotations. The search snippet about IDF weighting (rare features weighted as more relevant) came from a search-result summary whose origin was not traced. It is **UNVERIFIED** and not relied on.

---

## 6. Log template mining

| Tool | Grouping mechanism (as stated) | Preprocessing of variable tokens | Cost as stated |
|---|---|---|---|
| **Drain** (ICWS 2017) | Fixed-depth parse tree. Section III.C routes by message length ("number of tokens"). Section III.D routes by the first (depth − 2) tokens, and "If a token contains digits, it will match a special internal node '\*'". A maxChild cap sends overflow tokens to "\*". Section III.E: simSeq = Σ equ(seq1(i), seq2(i)) / n, a position-wise equal-token fraction, compared with threshold st. Section III.F: differing positions become "\*" in the template. | Section III.B: "Drain allows users to provide simple regular expressions based on domain knowledge that represent commonly-used variables, such as IP address and block ID. Then Drain will remove the tokens matched ... block IDs ... will be removed by 'blk_[0-9]+'." The regexes are "very simple, because they are used to match tokens instead of log messages", and the evaluated datasets "require at most two such regular expressions". "preprocessing can improve parsing accuracy" (citing their earlier study, not read). | Section IV: "O((d + cm)n), where d is the depth of the parse tree, c is the number of candidate log groups in the leaf node, m is the log message length". |
| **Spell** (ICDM 2016) | Longest common subsequence against each stored template ("LCSseq"). A message joins the template with the largest LCS length ℓ if ℓ exceeds τ, "by default, τ = \|s\|/2". Differing positions become "\*". Rationale (Section III.A): "the constant that represents a message type often takes a majority part of the sequence and the parameter values take only a small portion". | Tokenisation by delimiters ("space and equal sign are sufficient to cover most cases"). Zhu 2019 Table II lists preprocessing per parser; the marks did not survive text extraction, so **UNVERIFIED** for Spell. | Online, streaming |
| **LogMine** (CIKM 2016) | One-pass "friends-of-friend" clustering. A message joins a cluster if its distance to the cluster representative is below MaxDist. Dist(P, Q) = 1 − Σ_{i=1..min(len)} Score(Pi, Qi) / max(len(P), len(Q)), position-wise. Hierarchy built by re-clustering with a larger MaxDist. | Section 3.1: type detection replaces "date, time, IP and number" with the field name ("replace 2015-07-09 with date, or 192.168.10.15 with IP"). "If no type detection is done, two logs generated by the same pattern can have a low similarity, just because they have different values for the same field. Therefore, we may end up generating huge number of unnecessary patterns." | Section 3.2.2: "the memory usage of our clustering algorithm is O(number of clusters)" |
| **Survey** (Zhu et al. 2019) | Section II.C groups 13 parsers into frequent pattern mining (SLCT, LFA, LogCluster), clustering (LKE, LogSig, LogMine, SHISO, LenMa), heuristics (AEL, IPLoM, Drain) and others (Spell: LCS; MoLFI: evolutionary). | Section II.B: "Preprocessing is a step to remove some common variable values, such as IP address and numbers, by manually specifying simple regular expressions." Section III.A: "we apply the same preprocessing rules (e.g., IP or number replacement) to each log parser." Industrial deployment section: "a simple yet effective preprocessing step to filter common parameters, such as IP, package name, number, and file path. This greatly simplifies the problem for subsequent parsing", followed by deduplication of the now-identical messages. | Section III.D: "Drain and IPLoM have better efficiency, which scales linearly with the log size." Drain "attains the highest accuracy on average" and "shows the smallest variance". |

None of these parsers uses character q-gram set similarity. All four compare token sequences position-wise or by LCS, after regex or type masking of variable tokens.

---

## Mapping to the tool's gate

The facts about the tool (distinct trigrams per key, Dice threshold T, an inverted index over the keys in the batch, rarest-first ordering by posting-list size, top K = 50 kept, at least 15 of those 50 required) come from `find_consolidation_candidates()` as recorded in the #569 finding. Everything below applies the sourced lemmas to those facts. Arithmetic results are marked **derived**.

### A. What the prefix-filter bound requires, compared with K = 50 / 15 hits

1. **Ordering.** Sorting a key's trigrams by posting-list size within the batch is the document-frequency ordering O_df (PPJoin Section 2.1). The sources treat that ordering as a cost heuristic, not the source of correctness (AllPairs Section 4.2).
2. **Prefix length depends on threshold and size; the gate's does not.** For exact candidate generation, the prefix length is |r| − ⌈lb_r⌉ + 1 (Mann Section 2.2 with Table 1, Dice row), and only one shared token is required (Lemma 1). For |r| = 286 that is 191, 164, 133, 115, 96, 75, 53 and 28 tokens at T = 50, 60, 70, 75, 80, 85, 90 and 95% (Section 1.4). The gate uses 50 at every T and every size.
3. **More than one required hit lengthens the prefix.** Requiring e matches needs the (π + e − 1)-prefix (AdaptJoin, as described by Mann Section 2.3). Requiring 15 hits therefore needs π + 14 tokens: 205, 178, 147, 129, 110, 89, 67 and 42 at the eight thresholds. **Derived:** only at T = 95% does π + 14 (42) fit inside K = 50.
4. **The same point by pigeonhole (derived, one-sided).** If the inverted index holds every trigram of every batch key, then for a pair with |r∩s| ≥ α, the first p tokens of r contain at least p − (|r| − α) shared tokens. This is the counting argument behind Lemma 1, applied to one side. With p = 50 and |r| = 286, the guaranteed hits within the top 50 are:

   | Partner size | T = 50-80% | T = 85% | T = 90% | T = 95% |
   |---|---|---|---|---|
   | At the Dice lower bound (α = ⌈lb⌉) | 0 | 0 | 0 | 23 |
   | Equal size, \|s\| = 286 (α = ⌈T·286⌉) | 0 | 8 | 22 | 36 |

   **Derived:** the 15-of-50 rule is lossless for a 286-trigram key only from about T ≥ 90% (equal-size partner) or T ≥ 93.3% (smallest admissible partner). Below that, the sources give no guarantee for it. At T ≤ 80%, even a 1-hit rule on 50 tokens is not lossless, because the exact prefix is longer than 50.
5. **Unique tokens do not break the exact bound; they break the fixed one.**
   - Lemma 1 holds for any record content. A key with u tokens shared with no other key can reach at most |r| − u overlap with any partner. Whenever that is enough to reach α, the exact prefix |r| − α + 1 is longer than u, so it reaches past them. **Derived.**
   - In the reported case, 17 of the top 50 are unique to the source key, which caps possible hits at 33. The observed best was 9, against a requirement of 15.
   - Under the exact bound at T = 75% (π = 115), a true partner at Dice 75-81% needs only one shared token among the first 115 rarest. Lemma 1 guarantees that token exists.
   - The cost of this is lookups on unique tokens' single-entry posting lists. Mann Section 5.2 treats lookup count as the minor term when #lookups ≪ #pre.
6. **Low thresholds are where the sources say the prefix filter weakens.** PPJoin Section 1 names low thresholds and a "restricted feature domain" (a character-trigram alphabet is one; that label is derived). Mann Section 5.5 finds that few infrequent tokens mean "many false positives". The #569 finding measures random download-key pairs at Dice 60-82%, overlapping the true partners' 75-81%. **Derived:** an exact filter at T = 75% must return those random pairs that reach 75%, because they are genuine results under the measure.

### B. Sourced techniques by problem

**(a) Per-line random tokens**
- **Masking before similarity:**
  - Drain: user regexes remove IPs and block IDs; tokens containing digits route to "\*".
  - LogMine: type detection replaces date, time, IP and number, with the stated reason that unmasked values give same-pattern logs "a low similarity".
  - Zhu 2019: regex preprocessing of IPs, numbers and file paths, applied to every evaluated parser and in the industrial deployment.
  - These change the sets being compared. They are not filters.
- **Exact prefix filtering tolerates them without masking.** Lemma 1 with a threshold-derived prefix length stays lossless whatever the unique tokens are (point A.5). Unique tokens cost lookups, not recall.
- **MinHash / LSH does not address them.** Collision probability equals Jaccard over all shingles (MMDS Section 3.3.3), so random tokens lower the estimate as they lower Jaccard.
- **Frequency-adaptive pruning for the opposite extreme** (stop-word-like tokens, not unique ones): Block Purging and Block Filtering (ER survey Section 4.1). These are lossy.

**(b) Threshold-dependent candidate generation**
- **Prefix length** as a function of T and |r| (PPJoin Section 3 and Lemma 3; Mann Section 2.2 and Table 1), with the one-shared-token requirement.
- **Length filter bounds** [tD|r|/(2 − tD), (2 − tD)|r|/tD] (Mann Table 1), applied by cropping size-sorted posting lists.
- **Positional filter** on the matching position (PPJoin Lemma 2); per Mann Section 5.1 it pays off mainly at small thresholds.
- **Adaptive prefix extension** (AdaptJoin): the number of required matches e and the prefix length π + e − 1 chosen per record by a cost model over list lengths and candidate counts. Per Mann Section 5.5 it pays off only when the data has few infrequent tokens.
- **LSH band and row choice** with (1/b)^(1/r) set below T when false negatives matter (MMDS Section 3.4.3). This is approximate, with a false-negative rate readable off the S-curve.
- **Where not to invest, per Mann 2016:** verification with early termination costs a small constant, so filters beyond prefix + length (+ positional) rarely pay back. The suffix filter "never pays off"; the stated opportunity is "fast candidate generation".
