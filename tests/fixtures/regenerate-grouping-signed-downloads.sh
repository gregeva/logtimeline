#!/usr/bin/env bash
# regenerate-grouping-signed-downloads.sh — Rebuild the signed direct-download
# fixture for tests/validate-message-grouping.sh from the Apache HTTP Server
# access log in the corpus.
#
# Produces:
#   - tests/fixtures/grouping-signed-downloads.txt
#
# What the fixture must carry (features/fuzzy-message-consolidation.md
# § Design: candidate search that finds every partner (#569), acceptance
# criteria 1 and 2): a few hundred signed direct-download requests whose
# message keys, as ltl builds them under -xqs, each have at least one partner
# scoring Dice >= 75 while no pair scores Dice 85.
#
# Method, deterministic for a given source log (fixed seed, own PRNG so the
# result does not depend on the Perl build):
#   1. Take every status-200 doDirectDownload request line of the source.
#   2. Pick a contiguous window of WINDOW lines at a seeded offset.
#   3. Scrub each line (see scrub_line below):
#        client address -> TEST-NET-1 address, one per distinct source address
#                          (port kept); remote user fields -> '-'
#        userid, AUTH_CODE, site -> neutral constants
#        folderId, adId, fileName -> placeholders consistent per distinct
#                          value, preserving length and character class, and
#                          which values share a leading run (leading zeros kept)
#        sign            -> re-randomised with the same length and alphabet
#        sT, refsize, c, timestamps, bytes, duration -> kept
#   4. Build each key as ltl does ("[200] GET <request>", capped message) and
#      score pairs with get_consolidation_trigrams() and dice_coefficient(),
#      sliced verbatim from ltl.
#   5. Drop lines whose key has no partner >= 75, and the later line of any
#      pair >= 85, until neither remains; fail when too few lines survive.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=../lib/logs-dir.sh
source "$REPO_DIR/tests/lib/logs-dir.sh"

SOURCE="$LOGS_DIR/AccessLogs/access.log_2026-05-19_00_00_00"
TARGET="$SCRIPT_DIR/grouping-signed-downloads.txt"

SEED=569
WINDOW=400
PARTNER_MIN=75
PAIR_MAX_EXCLUSIVE=85
MIN_LINES=200

if [[ ! -f "$SOURCE" ]]; then
    echo "ERROR: source log missing: $SOURCE" >&2
    exit 1
fi
if [[ ! -f "$LTL" ]]; then
    echo "ERROR: ltl not found at $LTL" >&2
    exit 1
fi

BUILD_DIR=$(mktemp -d); trap 'rm -rf "$BUILD_DIR"' EXIT

perl - "$LTL" "$SOURCE" "$BUILD_DIR/fixture.txt" "$SEED" "$WINDOW" \
        "$PARTNER_MIN" "$PAIR_MAX_EXCLUSIVE" "$MIN_LINES" <<'PERL'
use strict;
use warnings;

my ($ltl, $source, $out, $seed, $window, $partner_min, $pair_max, $min_lines) = @ARGV;

# --- Slice the similarity code from ltl so the property is measured with it ---
open my $lfh, '<', $ltl or die "open $ltl: $!";
my @src = <$lfh>;
close $lfh;
my ($cap_line) = grep { /^my \$consolidation_message_length_cap\s*=/ } @src;
die "ERROR: \$consolidation_message_length_cap not found in ltl\n" unless $cap_line;
my $code = $cap_line =~ s/^my /our /r;
for my $name (qw(get_consolidation_trigrams dice_coefficient)) {
    my ($start) = grep { $src[$_] =~ /^sub \Q$name\E \{/ } 0 .. $#src;
    die "ERROR: sub $name not found in ltl\n" unless defined $start;
    my ($depth, $j) = (0, $start);
    while (1) {
        $depth += () = $src[$j] =~ /\{/g;
        $depth -= () = $src[$j] =~ /\}/g;
        last if $depth == 0;
        $j++;
    }
    $code .= join '', @src[$start .. $j];
}
our $consolidation_message_length_cap;
eval "$code; 1" or die "ERROR: sliced ltl code failed to compile: $@";

# --- Deterministic PRNG (LCG, 31-bit state) ---
my $state = $seed;
sub rnd { my ($n) = @_; $state = ($state * 1103515245 + 12345) % 2147483648; return int($state / 65536) % $n; }

# --- 1. Status-200 signed direct-download lines ---
my $line_re = qr{^(\S+) (\S+) (\S+) (\[[^\]]+\]) "GET (\S+) (HTTP/[\d.]+)" (\d{3}) (\S+) (\S+)$};
open my $sfh, '<', $source or die "open $source: $!";
my @pool;
while (my $l = <$sfh>) {
    chomp $l;
    next unless index($l, '/doDirectDownload/') >= 0;
    next unless $l =~ $line_re && $7 eq '200';
    next unless $l =~ /[?&]sign=/ && $l =~ /[?&]sT=/;
    push @pool, $l;
}
close $sfh;
die "ERROR: only " . scalar(@pool) . " signed download lines in $source\n" if @pool < $window;

# --- 2. Seeded contiguous window ---
my $offset = rnd(scalar(@pool) - $window);
my @lines = @pool[$offset .. $offset + $window - 1];

# --- 3. Scrub ---
my %addr_map;
my %value_map;     # field -> original prefix -> original char -> new char
my %used;          # field -> original prefix -> new char -> 1
my %class = (digit => ['0'..'9'], hexl => ['a'..'f'], lowr => ['g'..'z'], uppr => ['A'..'Z']);
sub char_class {
    my ($c) = @_;
    return 'digit' if $c =~ /[0-9]/;
    return 'hexl'  if $c =~ /[a-f]/;
    return 'lowr'  if $c =~ /[g-z]/;
    return 'uppr'  if $c =~ /[A-Z]/;
    return;
}
# Placeholder consistent per distinct value: each character is mapped given the
# original characters before it, so two values sharing a leading run still share
# one after scrubbing, and the rest is replaced within its character class.
sub placeholder {
    my ($field, $value) = @_;
    my $new = '';
    my $leading_zeros = 1;
    for my $i (0 .. length($value) - 1) {
        my $c = substr($value, $i, 1);
        my $prefix = substr($value, 0, $i);
        if ($leading_zeros && $c eq '0') { $new .= '0'; next; }
        $leading_zeros = 0;
        my $cls = char_class($c);
        if (!defined $cls) { $new .= $c; next; }
        my $m = $value_map{$field}{$prefix}{$c};
        if (!defined $m) {
            my @free = grep { !$used{$field}{$prefix}{$_} && !($i == 0 && $_ eq '0') } @{ $class{$cls} };
            die "ERROR: placeholder alphabet exhausted for $field\n" unless @free;
            $m = $free[rnd(scalar @free)];
            $value_map{$field}{$prefix}{$c} = $m;
            $used{$field}{$prefix}{$m} = 1;
        }
        $new .= $m;
    }
    return $new;
}
sub resign {
    my ($sign) = @_;
    my @alnum = ('A'..'Z', 'a'..'z', '0'..'9');
    my $new = '';
    while (length $sign) {
        if ($sign =~ s/^%3D//i)        { $new .= '%3D'; }
        elsif ($sign =~ s/^%2[BF]//i)  { $new .= (rnd(2) ? '%2B' : '%2F'); }
        elsif ($sign =~ s/^[A-Za-z0-9]//) { $new .= $alnum[rnd(scalar @alnum)]; }
        else { die "ERROR: unexpected character in sign value\n"; }
    }
    return $new;
}
my %constant = (
    userid    => '100',
    AUTH_CODE => 'SIGNSCHEME',
    site      => 'https%3A%2F%2Fplm.example.com%2FWindchill%2Fservlet%2FWindchillGW',
);
sub scrub_line {
    my ($l) = @_;
    $l =~ $line_re or die "ERROR: line no longer matches the access-log shape\n";
    my ($client, $ts, $url, $proto, $status, $bytes, $dur) = ($1, $4, $5, $6, $7, $8, $9);
    my ($addr, $port) = $client =~ /^([^:]+)(:\d+)?$/;
    if (!exists $addr_map{$addr}) {
        my $next = 10 + scalar keys %addr_map;
        $addr_map{$addr} = "192.0.2.$next";
    }
    my $new_client = $addr_map{$addr} . ($port // '');
    my ($path, $query) = split /\?/, $url, 2;
    my @params;
    for my $kv (split /&/, $query) {
        my ($k, $v) = split /=/, $kv, 2;
        if    (exists $constant{$k})                       { $v = $constant{$k}; }
        elsif ($k eq 'folderId' || $k eq 'adId' || $k eq 'fileName') { $v = placeholder($k, $v); }
        elsif ($k eq 'sign')                               { $v = resign($v); }
        push @params, "$k=$v";
    }
    return qq{$new_client - - $ts "GET $path?} . join('&', @params) . qq{ $proto" $status $bytes $dur};
}
my @scrubbed = map { scrub_line($_) } @lines;

# --- 4. Keys and pairwise Dice ---
my @trig;
for my $l (@scrubbed) {
    $l =~ $line_re or die;
    my $key = substr("[$7] GET $5", 0, $consolidation_message_length_cap);
    push @trig, get_consolidation_trigrams($key);
}
my $n = @scrubbed;
my @score;
for my $i (0 .. $n - 1) {
    for my $j ($i + 1 .. $n - 1) {
        $score[$i][$j] = $score[$j][$i] = dice_coefficient($trig[$i], $trig[$j]);
    }
}

# --- 5. Prune to the property ---
my %alive = map { $_ => 1 } 0 .. $n - 1;
my $changed = 1;
while ($changed) {
    $changed = 0;
    my @ids = sort { $a <=> $b } keys %alive;
    for my $i (@ids) {
        next unless $alive{$i};
        for my $j (@ids) {
            next unless $j > $i && $alive{$j};
            if ($score[$i][$j] >= $pair_max) { delete $alive{$j}; $changed = 1; }
        }
    }
    @ids = sort { $a <=> $b } keys %alive;
    for my $i (@ids) {
        my $best = 0;
        for my $j (@ids) { next if $j == $i; $best = $score[$i][$j] if $score[$i][$j] > $best; }
        if ($best < $partner_min) { delete $alive{$i}; $changed = 1; }
    }
}
my @keep = sort { $a <=> $b } keys %alive;
die "ERROR: only " . scalar(@keep) . " lines satisfy the property (need $min_lines)\n" if @keep < $min_lines;

open my $ofh, '>', $out or die "open $out: $!";
print {$ofh} "$scrubbed[$_]\n" for @keep;
close $ofh;

my @best = map { my $i = $_; my $b = 0; for my $j (@keep) { next if $j == $i; $b = $score[$i][$j] if $score[$i][$j] > $b; } $b } @keep;
my @sorted = sort { $a <=> $b } @best;
printf "  window %d lines at offset %d of %d; kept %d\n", $window, $offset, scalar(@pool), scalar(@keep);
printf "  best partner Dice: min %d, median %d, max %d\n", $sorted[0], $sorted[int($#sorted / 2)], $sorted[-1];
PERL

mv "$BUILD_DIR/fixture.txt" "$TARGET"
echo "Wrote $TARGET ($(wc -l < "$TARGET" | tr -d ' ') lines)"
