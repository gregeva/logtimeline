#!/usr/bin/env bash
# regenerate-grouping-accounting.sh — Rebuild the synthetic access-log fixture
# for the consolidation accounting scenarios of tests/validate-message-grouping.sh.
#
# Produces:
#   - tests/fixtures/grouping-accounting.txt
#
# What the fixture must carry (features/619-per-run-key-cut.md § 5.11 and
# § 6, AC18 to AC21): a Tomcat access log carrying bytes and execution time,
# whose message keys exercise every way consolidation moves data, when ltl runs
# with a lowered --consolidation-trigger:
#   - streaming checkpoints that discover patterns, followed by lines that the
#     inline match absorbs into those patterns (keys whose every line is
#     absorbed inline, and keys absorbed in part);
#   - keys left for the final pass, and keys that group in it;
#   - GET and POST requests on similar paths, several status codes (the
#     grouping key of an access log), and lines without a bytes value, so the
#     bytes count differs from the occurrences.
#
# Synthetic: documentation addresses (TEST-NET-1), neutral paths. Deterministic
# for a given script (fixed seed, own PRNG, so the result does not depend on the
# Perl build).
#
# Usage: tests/fixtures/regenerate-grouping-accounting.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$SCRIPT_DIR/grouping-accounting.txt"

perl - > "$OUT" <<'PERL'
use strict;
use warnings;

my $seed = 619;
sub rnd { $seed = ($seed * 1103515245 + 12345) % 2147483648; return $seed / 2147483648; }
sub pick { my @a = @_; return $a[int(rnd() * @a)]; }

my @words = qw(Alpha Bravo Charlie Delta Echo Foxtrot Golf Hotel India Juliet Kilo Lima);
my @lines;
my $t = 0;
for my $i (1 .. 1200) {
    $t += 1 + int(rnd() * 60);
    my $r = rnd();
    my ($method, $path, $status, $bytes);
    if ($r < 0.30) {
        ($method, $path, $status) = ('GET', sprintf('/app/Things/Device-%04d/Properties', int(rnd() * 150)), 200);
    } elsif ($r < 0.55) {
        ($method, $path, $status) = ('POST', sprintf('/app/Things/Device-%04d/Services/GetStatus', int(rnd() * 150)), 200);
    } elsif ($r < 0.70) {
        ($method, $path, $status) = ('GET', '/app/Mashups/Panel.' . pick(@words), 200);
    } elsif ($r < 0.82) {
        ($method, $path, $status) = ('GET', sprintf('/app/missing/%08x', int(rnd() * 4294967295)), 404);
    } elsif ($r < 0.94) {
        ($method, $path, $status) = ('GET', sprintf('/app/Login?redirect=%d', int(rnd() * 400)), 302);
    } else {
        ($method, $path, $status) = ('POST', '/app/Resources/Session/Services/' . pick(qw(Ping Renew Close)), 401);
    }
    $bytes = ($status == 302 || rnd() < 0.1) ? '-' : 100 + int(rnd() * 20000);
    my $duration = 1 + int(rnd() * rnd() * 3000);
    my ($h, $m, $s) = (int($t / 3600) % 24, int($t / 60) % 60, $t % 60);
    push @lines, sprintf('192.0.2.%d - - [05/Oct/2026:%02d:%02d:%02d +0000] "%s %s HTTP/1.1" %d %s %d',
        10 + int(rnd() * 20), $h, $m, $s, $method, $path, $status, $bytes, $duration);
}
print "$_\n" for @lines;
PERL

echo "Wrote $OUT ($(wc -l < "$OUT") lines)"
