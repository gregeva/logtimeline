#!/usr/bin/env bash
# Lists every record that mentions the surfaces a piece of work touches, so the
# owning records are found by search rather than taken from an issue's links
# (CLAUDE.md, Before planning). Each record listed is read, or dismissed in the
# feature doc with its reason.
#
# Usage: find-records.sh [--issues] <term> [<term> ...]
#   A term starting with '-' is an option and is matched as written inside a
#   code span (`-g`, `-g 85`, `--group-similar`); any other term (a sub name, a
#   section name, a table name) is matched as a fixed string.
#   --issues also searches open and closed issue bodies through gh, keeping
#   only the issues whose title or body carries the term as the records search
#   matches it. A search that fails is named on stderr, the other terms are
#   still searched, and the exit status is 3 so the list is known incomplete.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
search_issues=0
if [[ "${1:-}" == "--issues" ]]; then search_issues=1; shift; fi
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [--issues] <term> [<term> ...]" >&2
    exit 1
fi

records=()
while IFS= read -r f; do records+=("$f"); done < <(
    cd "$root" && find features docs releases -name '*.md' -type f | sort
)

# The fixed strings a term is matched by: an option inside a code span, any
# other term as written.
term_patterns() {
    local term="$1"
    if [[ "$term" == -* ]]; then
        printf '%s\n' "\`$term\`" "\`$term " "\`$term," "\`$term/" "/$term\`" "/$term "
    else
        printf '%s\n' "$term"
    fi
}

declare -A hits=() terms_of=()
for term in "$@"; do
    patterns=()
    while IFS= read -r pattern; do patterns+=(-e "$pattern"); done < <(term_patterns "$term")
    while IFS=: read -r f n; do
        [[ "$n" -gt 0 ]] || continue
        hits[$f]=$(( ${hits[$f]:-0} + n ))
        terms_of[$f]="${terms_of[$f]:-}${terms_of[$f]:+, }$term"
    done < <(cd "$root" && grep -a -c -F "${patterns[@]}" "${records[@]}" 2>/dev/null || true)
done

if [[ ${#hits[@]} -eq 0 ]]; then
    echo "No record mentions: $*"
else
    for f in "${!hits[@]}"; do
        printf '%6d  %s  [%s]\n' "${hits[$f]}" "$f" "${terms_of[$f]}"
    done | sort -rn
fi

# The patterns file is an index of entries, each its own record: a hit there
# is listed by the entries whose text carries a term, so each entry is read or
# dismissed by name rather than the file by the entries already known.
patterns_file=docs/architecture-patterns.md
if [[ -n "${hits[$patterns_file]:-}" ]]; then
    echo
    echo "Entries of $patterns_file that mention a term:"
    for term in "$@"; do
        term_patterns "$term" | while IFS= read -r pattern; do printf '%s\t%s\n' "$term" "$pattern"; done
    done | (cd "$root" && perl -e '
        my $file = shift;
        my @pairs = map { chomp; [ split /\t/, $_, 2 ] } <STDIN>;
        open my $fh, "<", $file or die "find-records: $file: $!\n";
        my ( $heading, @order, %terms );
        while ( my $line = <$fh> ) {
            if ( $line =~ /^## (.+?)\s*$/ ) { $heading = $1; next }
            next unless defined $heading;
            for my $pair (@pairs) {
                next unless index( $line, $pair->[1] ) >= 0;
                push @order, $heading unless $terms{$heading};
                $terms{$heading}{ $pair->[0] } = 1;
            }
        }
        printf "  § %s  [%s]\n", $_, join( ", ", sort keys %{ $terms{$_} } ) for @order;
    ' "$patterns_file")
fi

status=0
if [[ $search_issues -eq 1 ]]; then
    echo
    echo "Issues whose title or body mentions a term:"
    err=$(mktemp); listed=$(mktemp); trap 'rm -f "$err" "$listed"' EXIT
    if ! repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>"$err"); then
        echo "find-records: issue search failed, the repository could not be read: $(head -1 "$err")" >&2
        exit 3
    fi
    # The loop writes to a file, not a pipe, so a failed search's status
    # survives the loop.
    for term in "$@"; do
        # GitHub's search matches words, so its results are candidates only:
        # each is kept when its title or body carries one of the term's patterns.
        if ! found=$(gh search issues --repo "$repo" --match body --limit 100 \
                     --json number,title,state,body -- "$term" 2>"$err"); then
            echo "find-records: issue search failed for [$term]: $(head -1 "$err")" >&2
            status=3
            continue
        fi
        term_patterns "$term" | perl -MJSON::PP -CO -e '
            my ( $json, $term ) = @ARGV;
            chomp( my @patterns = <STDIN> );
            for my $issue ( @{ decode_json($json) } ) {
                my $text = ( $issue->{title} // "" ) . "\n" . ( $issue->{body} // "" );
                next unless grep { index( $text, $_ ) >= 0 } @patterns;
                print "  #$issue->{number} $issue->{state} $issue->{title}  [$term]\n";
            }' "$found" "$term" >> "$listed"
    done
    sort -u "$listed"
fi
exit $status
