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
#   check <ltl> <work dir>       one capture run per input with -mem, and three
#                                rounds on 15 unmasked days with and without -mem;
#                                then the check against the reference
set -u
here="$(cd "$(dirname "$0")" && pwd)"
mode="$1"; ltl="$2"; work="$3"
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
    cp "$ltl" "$work/arms/ltl-checked" && cp "$ltl" "$work/arms/ltl-tracked" && chmod +x "$work/arms"/ltl-*
    ARMS=checked "$here/run-arms.sh" "$work/arms" "$work/capture" "$here/candidates.txt" 1 "${INPUTS[@]}" || exit 1
    ARMS="tracked checked" "$here/run-arms.sh" "$work/arms" "$work/cost" "$here/candidates.txt" 3 tc-g-d15 || exit 1
    python3 "$here/check-criterion-11.py" check "$work/capture" "$work/cost" checked "$PERL_HASH_SEED" "$reference_tsv"
    ;;
*)
    echo "usage: criterion-11.sh reference|check <ltl> <work dir>" >&2; exit 2 ;;
esac
