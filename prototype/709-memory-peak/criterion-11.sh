#!/usr/bin/env bash
# #709 criterion 11, under one pinned hash seed (the architect, 2026-10-28).
#
# The message store's size follows Perl's per-process hash seed by 64 bytes an
# entry, so the runs compared share one seed: every run here hashes under
# PINNED_SEED, prints it (PERL_HASH_SEED_DEBUG), and check-criterion-11.py
# refuses a run that does not show it. The seed was captured from a run on this
# development host's Perl (5.44, SBOX32_WITH_SIPHASH_1_3); another Perl may hash
# differently under it, so the reference is regenerated with the Perl that checks.
#
#   reference <ltl> <work dir>   one run per input of an ltl walking every store
#                                at every site; writes results/criterion-11-reference.tsv
#   check <before ltl> <after ltl> <work dir>
#                                one capture run per input of the after with -mem
#                                against the reference; five rounds on 15 unmasked
#                                days of the before and the after, each with and
#                                without -mem, the after against the before in
#                                each mode
set -u
here="$(cd "$(dirname "$0")" && pwd)"
mode="$1"
case "$mode" in
check) before="$2"; ltl="$3"; work="$4" ;;
*)     ltl="$2"; work="$3" ;;
esac
export PERL_HASH_SEED=0xcb7f69e1ad7b89b8a97db9af9d749f5c1ede2a51b28dc5f4107d65e2a17c8cb5
export PERL_PERTURB_KEYS=0
export PERL_HASH_SEED_DEBUG=1
INPUTS=(tc-mask-d1 tc-mask-d7 tc-mask-d15 tc-g-d1 tc-g-d7 tc-g-d15 wc-access-xqs appl)
reference_tsv="$here/results/criterion-11-reference.tsv"
mkdir -p "$work/arms"

case "$mode" in
reference)
    cp "$ltl" "$work/arms/ltl-every" && chmod +x "$work/arms/ltl-every"
    ARMS=every "$here/run-arms.sh" "$work/arms" "$work/reference" "$here/candidates.txt" 1 "${INPUTS[@]}" || exit 1
    python3 "$here/check-criterion-11.py" reference "$work/reference" every "$PERL_HASH_SEED" > "$reference_tsv" || exit 1
    echo "wrote $reference_tsv ($(grep -vc '^#' "$reference_tsv") rows)"
    ;;
check)
    cp "$ltl" "$work/arms/ltl-checked"
    for m in floor mem; do cp "$before" "$work/arms/ltl-before-$m"; cp "$ltl" "$work/arms/ltl-after-$m"; done
    chmod +x "$work/arms"/ltl-*
    ARMS=checked "$here/run-arms.sh" "$work/arms" "$work/capture" "$here/candidates.txt" 1 "${INPUTS[@]}" || exit 1
    ARMS="before-floor before-mem after-floor after-mem" "$here/run-arms.sh" "$work/arms" "$work/cost" "$here/candidates.txt" 5 tc-g-d15 || exit 1
    python3 "$here/check-criterion-11.py" check "$work/capture" "$work/cost" checked "$PERL_HASH_SEED" "$reference_tsv"
    ;;
*)
    echo "usage: criterion-11.sh reference <ltl> <work dir> | check <before ltl> <after ltl> <work dir>" >&2; exit 2 ;;
esac
