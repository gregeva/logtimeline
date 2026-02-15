#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use List::Util qw(min max);

use Inline C => <<'END_C';
SV* compute_mask_c(const char *str_a, const char *str_b) {
    int len_a = strlen(str_a);
    int len_b = strlen(str_b);
    int min_len = len_a < len_b ? len_a : len_b;
    int prefix_len = 0;
    while (prefix_len < min_len && str_a[prefix_len] == str_b[prefix_len]) prefix_len++;
    int suffix_len = 0;
    while (suffix_len < (min_len - prefix_len) &&
           str_a[len_a - 1 - suffix_len] == str_b[len_b - 1 - suffix_len]) suffix_len++;
    char *mask = (char *)calloc(len_a, 1);
    int i;
    for (i = 0; i < prefix_len; i++) mask[i] = 1;
    for (i = 0; i < suffix_len; i++) mask[len_a - 1 - i] = 1;
    int mid_a = len_a - prefix_len - suffix_len;
    int mid_b = len_b - prefix_len - suffix_len;
    if (mid_a > 0 && mid_b > 0) {
        const char *a = str_a + prefix_len;
        const char *b = str_b + prefix_len;
        int m = mid_a, n = mid_b;
        int k = (m > n ? m : n) * 6 / 10 + 2;
        int big = m + n + 1;
        int row_bytes = (n + 1 + 3) / 4;
        unsigned char *dir = (unsigned char *)calloc((m + 1), row_bytes);
        int *prev = (int *)malloc((n + 1) * sizeof(int));
        int *curr = (int *)malloc((n + 1) * sizeof(int));
        int j;
        for (j = 0; j <= n; j++) prev[j] = j;
        for (j = 1; j <= n && j <= k; j++) { dir[j/4] |= (2 << ((j%4)*2)); }
        for (i = 1; i <= m; i++) {
            int j_min = i-k; if (j_min<1) j_min=1;
            int j_max = i+k; if (j_max>n) j_max=n;
            unsigned char *dr = dir + i*row_bytes;
            curr[0] = i;
            for (j=1; j<j_min; j++) curr[j]=big;
            for (j=j_min; j<=j_max; j++) {
                if (a[i-1]==b[j-1]) { curr[j]=prev[j-1]; }
                else {
                    int sc=prev[j-1]+1, dc=prev[j]+1, ic=curr[j-1]+1;
                    if (sc<=dc && sc<=ic) { curr[j]=sc; }
                    else if (dc<=ic) { curr[j]=dc; dr[j/4]|=(1<<((j%4)*2)); }
                    else { curr[j]=ic; dr[j/4]|=(2<<((j%4)*2)); }
                }
            }
            for (j=j_max+1; j<=n; j++) curr[j]=big;
            int *tmp=prev; prev=curr; curr=tmp;
        }
        i=m; j=n;
        while (i>0 && j>0) {
            unsigned char *dr = dir+i*row_bytes;
            int d = (dr[j/4]>>((j%4)*2))&3;
            if (d==0) { if (a[i-1]==b[j-1]) mask[prefix_len+i-1]=1; i--; j--; }
            else if (d==1) { i--; } else { j--; }
        }
        free(dir); free(prev); free(curr);
    }
    AV *av = newAV();
    av_extend(av, len_a - 1);
    for (i = 0; i < len_a; i++) av_push(av, newSViv(mask[i]));
    free(mask);
    return newRV_noinc((SV*)av);
}
END_C

# --- Shared functions (copied from prototype, abbreviated) ---

my $twx_regex = qr/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})[\+\-]\d{4} \[L: ([^\]]*)\] \[O: ([^\]]*)] \[I: ([^\]]*)] \[U: ([^\]]*)] \[S: ([^\]]*)] \[P: ([^\]]*)] \[T: ((?:\](?! )|[^\]])*)] (.*)/;

my $message_length_cap = 300;
my $threshold = 80;
my $trigger = 5000;
my $occurrence_ceiling = 3;
my $max_patterns_cap = 50;

my %log_messages;
my %key_message;
my %ngram_index;
my %key_trigrams;
my %canonical_patterns;
my %clusters;

# --- Timing accumulators ---
my $t_index = 0;
my $t_find_candidates = 0;
my $t_compute_mask = 0;
my $t_coalesce = 0;
my $t_derive = 0;
my $t_interleaved_rescan = 0;
my $t_merge_check = 0;
my $t_merge_rescan = 0;
my $t_other = 0;

my $n_index_calls = 0;
my $n_find_calls = 0;
my $n_mask_calls = 0;
my $n_rescan_evals = 0;
my $n_merge_rescan_evals = 0;
my $n_patterns_discovered = 0;

# --- Parse ---
print "Parsing...\n";
my $t0 = time();
open(my $fh, "<", "logs/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log") or die $!;
while (<$fh>) {
    chomp;
    if (my ($ts,$cat,$obj,$inst,$user,$sess,$plat,$thr,$msg) = $_ =~ $twx_regex) {
        my $to = substr($obj, length($obj)>25 ? length($obj)-25 : 0, 25);
        my $tt = substr($thr,0,20);
        my $lk = substr("[$cat] [$tt] [$to] $msg", 0, 350);
        $log_messages{$cat}{$lk}{occurrences}++;
        $key_message{$lk} //= $lk;
    }
}
close($fh);
printf "Parse: %.2fs\n\n", time()-$t0;

# --- N-gram functions ---
sub get_trigrams {
    my ($str) = @_;
    my $capped = substr($str, 0, $message_length_cap);
    my %trigrams;
    for my $i (0 .. length($capped) - 3) { $trigrams{substr($capped,$i,3)} = 1; }
    return \%trigrams;
}

sub dice_coefficient {
    my ($a,$b) = @_;
    my $sa = scalar keys %$a; my $sb = scalar keys %$b;
    return 0 if $sa==0||$sb==0;
    my $int = 0;
    if ($sa <= $sb) { for (keys %$a) { $int++ if exists $b->{$_}; } }
    else { for (keys %$b) { $int++ if exists $a->{$_}; } }
    return int((2*$int*100)/($sa+$sb));
}

sub build_ngram_index {
    my ($cat,$keys_ref) = @_;
    my $indexed = 0;
    for my $lk (@$keys_ref) {
        my $msg = $key_message{$lk}; next unless defined $msg;
        my $tg = get_trigrams($msg);
        $key_trigrams{$lk} = $tg;
        for (keys %$tg) { $ngram_index{$cat}{$_}{$lk} = 1; }
        $indexed++;
    }
    return $indexed;
}

sub compute_mask { return compute_mask_c($_[0], $_[1]); }

sub coalesce_mask {
    my ($mask) = @_;
    my @m = @$mask;
    my $len = scalar @m;
    my $i = 0;
    while ($i < $len) {
        if ($m[$i] == 1) {
            my $start = $i;
            while ($i < $len && $m[$i] == 1) { $i++; }
            my $run_len = $i - $start;
            if ($run_len < 3) {
                my $vb = ($start == 0) ? 0 : ($m[$start-1] == 0);
                my $va = ($i >= $len)  ? 0 : ($m[$i] == 0);
                if ($vb && $va) { for my $k ($start .. $start+$run_len-1) { $m[$k] = 0; } }
            }
        } else { $i++; }
    }
    $i = 0;
    while ($i < $len) {
        if ($m[$i] == 0) {
            my $ss = $i; my $j = $i;
            while ($j < $len) {
                if ($m[$j]==1) { my $ks=$j; while ($j<$len&&$m[$j]==1){$j++} if ($j-$ks>=10){$j=$ks;last;} }
                else { $j++; }
            }
            my $sl = $j - $ss;
            if ($sl >= 5) {
                my $kc = 0; for my $k ($ss..$j-1) { $kc++ if $m[$k]==1; }
                if ($kc/$sl < 0.40) { for my $k ($ss..$j-1) { $m[$k]=0; } }
            }
            $i = $j;
        } else { $i++; }
    }
    return \@m;
}

sub derive_canonical {
    my ($ref,$mask) = @_;
    my @c = split //, $ref; my $r = ''; my $iv = 0;
    for my $i (0..$#c) {
        if ($mask->[$i]) {
            if ($c[$i] eq '*') { if(!$iv){$r.='*';$iv=1;} }
            else { $iv=0; $r.=$c[$i]; }
        } else { if(!$iv){$r.='*';$iv=1;} }
    }
    return $r;
}

sub derive_regex {
    my ($ref,$mask) = @_;
    my @c = split //, $ref; my $p = '^'; my $lb = ''; my $iv = 0;
    for my $i (0..$#c) {
        if ($mask->[$i]) {
            if ($c[$i] eq '*') {
                if (length $lb) { $p .= quotemeta($lb); $lb=''; }
                if (!$iv) { $iv=1; }
            } else { if($iv){$p.='.+?';$iv=0;} $lb.=$c[$i]; }
        } else {
            if (length $lb) { $p .= quotemeta($lb); $lb=''; }
            if (!$iv) { $iv=1; }
        }
    }
    if ($iv) { $p .= '.+?'; }
    if (length $lb) { $p .= quotemeta($lb); }
    $p .= '$';
    return qr/$p/;
}

# --- Instrumented Phase 4 ---
print "=== Instrumented Phase 4 ===\n\n";

for my $cat (sort keys %log_messages) {
    my @unmatched = keys %{$log_messages{$cat}};
    my $original_count = scalar @unmatched;
    next if $original_count < 10;

    printf "--- %s: %d unique keys ---\n", $cat, $original_count;

    my $current_trigger = $trigger;
    my $pass_num = 0;
    my $max_passes = 10;

    while ($pass_num < $max_passes && scalar @unmatched >= min($current_trigger, 10)) {
        $pass_num++;
        my $pre_count = scalar @unmatched;

        # --- Index ---
        my @discovery;
        my @ceiling_keys;
        for my $key (@unmatched) {
            if (($log_messages{$cat}{$key}{occurrences}//1) >= $occurrence_ceiling) {
                push @ceiling_keys, $key;
            } else {
                push @discovery, $key;
            }
        }
        last if @discovery < 2;

        my $t1 = time();
        my $il = min($trigger, scalar @discovery);
        my @batch = @discovery[0..$il-1];
        delete $ngram_index{$cat};
        build_ngram_index($cat, \@batch);
        $t_index += time() - $t1;
        $n_index_calls++;

        # --- Discovery ---
        my %consumed;
        my $pass_patterns = 0;
        my $pass_absorbed = 0;
        my $keys_searched = 0;
        my $max_search = min(500, scalar @batch);
        my $current_pattern_count = exists $canonical_patterns{$cat} ? scalar @{$canonical_patterns{$cat}} : 0;

        for my $key (@batch) {
            last if $keys_searched >= $max_search;
            last if $current_pattern_count >= $max_patterns_cap;
            next if $consumed{$key};
            $keys_searched++;

            # --- find_candidates ---
            $t1 = time();
            my $src_tg = $key_trigrams{$key}; next unless $src_tg;
            my $src_size = scalar keys %$src_tg; next if $src_size == 0;
            my $min_hits = int($threshold * $src_size / 100);
            my $min_cs = int($src_size * $threshold / (200 - $threshold));
            my $max_cs = int($src_size * (200 - $threshold) / $threshold) + 1;
            my %ch;
            for my $g (keys %$src_tg) {
                next unless exists $ngram_index{$cat}{$g};
                for my $ck (keys %{$ngram_index{$cat}{$g}}) {
                    next if $ck eq $key; $ch{$ck}++;
                }
            }
            my @top = sort { $ch{$b}<=>$ch{$a} } grep { $ch{$_}>=$min_hits } keys %ch;
            splice(@top, 50) if @top > 50;
            $t_find_candidates += time() - $t1;
            $n_find_calls++;

            for my $cand_key (@top) {
                next if $consumed{$cand_key};
                my $cg = $key_trigrams{$cand_key}; next unless $cg;
                my $cs = scalar keys %$cg;
                next if $cs < $min_cs || $cs > $max_cs;
                my $score = dice_coefficient($src_tg, $cg);
                next unless $score >= $threshold;

                # --- compute_mask ---
                $t1 = time();
                my $msg_a = substr($key_message{$key}//'', 0, $message_length_cap);
                my $msg_b = substr($key_message{$cand_key}//'', 0, $message_length_cap);
                my $raw_mask = compute_mask($msg_a, $msg_b);
                $t_compute_mask += time() - $t1;
                $n_mask_calls++;

                # --- coalesce + derive ---
                $t1 = time();
                my $mask = coalesce_mask($raw_mask);
                my $canonical = derive_canonical($msg_a, $mask);
                my $regex = derive_regex($msg_a, $mask);
                next unless ($msg_a =~ $regex) && ($msg_b =~ $regex);
                $t_coalesce += time() - $t1;

                $consumed{$key} = 1;
                $consumed{$cand_key} = 1;

                my $cluster_occ = ($log_messages{$cat}{$key}{occurrences}//0)
                                + ($log_messages{$cat}{$cand_key}{occurrences}//0);
                my $cluster_matches = 2;
                $pass_absorbed += 2;

                # --- Interleaved re-scan ---
                $t1 = time();
                my $rescan_count = 0;
                for my $ukey (@unmatched) {
                    next if $consumed{$ukey};
                    my $umsg = $key_message{$ukey}; next unless defined $umsg;
                    my $capped = substr($umsg, 0, $message_length_cap);
                    $rescan_count++;
                    if ($capped =~ $regex) {
                        $consumed{$ukey} = 1;
                        $cluster_occ += ($log_messages{$cat}{$ukey}{occurrences}//0);
                        $cluster_matches++;
                        $pass_absorbed++;
                    }
                }
                $t_interleaved_rescan += time() - $t1;
                $n_rescan_evals += $rescan_count;

                # --- Merge check ---
                $t1 = time();
                my $merged = 0;
                if (exists $canonical_patterns{$cat}) {
                    my $new_tg = get_trigrams($canonical);
                    for my $entry (@{$canonical_patterns{$cat}}) {
                        my $ex = $clusters{$cat}{$entry->{canonical}}; next unless $ex;
                        my $ex_tg = get_trigrams($entry->{canonical});
                        my $sc = dice_coefficient($new_tg, $ex_tg);
                        if ($sc >= $threshold) {
                            my $rm = compute_mask($entry->{canonical}, $canonical);
                            my $mm = coalesce_mask($rm);
                            my $mc = derive_canonical($entry->{canonical}, $mm);
                            my $mr = derive_regex($entry->{canonical}, $mm);
                            if (($entry->{canonical} =~ $mr) && ($canonical =~ $mr)) {
                                $ex->{occurrences} += $cluster_occ;
                                $ex->{match_count} += $cluster_matches;
                                my $old_c = $entry->{canonical};
                                $entry->{canonical} = $mc;
                                $entry->{cluster_key} = $mc;
                                $entry->{pattern} = $mr;
                                $entry->{match_count} = $ex->{match_count};
                                $ex->{canonical} = $mc; $ex->{pattern} = $mr;
                                if ($old_c ne $mc) { $clusters{$cat}{$mc} = $ex; delete $clusters{$cat}{$old_c}; }
                                $merged = 1;
                                $t_merge_check += time() - $t1;

                                # --- Merge re-scan ---
                                $t1 = time();
                                my $mrescan = 0;
                                for my $ukey (@unmatched) {
                                    next if $consumed{$ukey};
                                    my $umsg = $key_message{$ukey}; next unless defined $umsg;
                                    my $capped = substr($umsg, 0, $message_length_cap);
                                    $mrescan++;
                                    if ($capped =~ $mr) {
                                        $consumed{$ukey} = 1;
                                        $ex->{occurrences} += ($log_messages{$cat}{$ukey}{occurrences}//0);
                                        $ex->{match_count}++;
                                        $entry->{match_count} = $ex->{match_count};
                                        $pass_absorbed++;
                                    }
                                }
                                $t_merge_rescan += time() - $t1;
                                $n_merge_rescan_evals += $mrescan;
                                last;
                            }
                        }
                    }
                }
                if (!$merged) { $t_merge_check += time() - $t1; }

                if (!$merged) {
                    $clusters{$cat}{$canonical} = {
                        canonical => $canonical, pattern => $regex,
                        occurrences => $cluster_occ, match_count => $cluster_matches,
                    };
                    push @{$canonical_patterns{$cat}}, {
                        pattern => $regex, canonical => $canonical,
                        cluster_key => $canonical, match_count => $cluster_matches,
                    };
                    $current_pattern_count++;
                }
                $pass_patterns++;
                $n_patterns_discovered++;
                last;
            }
        }

        @unmatched = grep { !$consumed{$_} } @unmatched;
        printf "  Pass %d: %d patterns, %d absorbed, %d remaining\n",
            $pass_num, $pass_patterns, $pass_absorbed, scalar @unmatched;

        last if $pass_patterns == 0 || $pass_absorbed == 0;
    }
    print "\n";
}

# --- Report ---
printf "=== Phase 4 Timing Breakdown ===\n\n";
my $total = $t_index + $t_find_candidates + $t_compute_mask + $t_coalesce +
            $t_interleaved_rescan + $t_merge_check + $t_merge_rescan;

printf "  %-28s %7.3fs  %5.1f%%  (%d calls)\n", "build_ngram_index", $t_index, $t_index/$total*100, $n_index_calls;
printf "  %-28s %7.3fs  %5.1f%%  (%d calls)\n", "find_candidates", $t_find_candidates, $t_find_candidates/$total*100, $n_find_calls;
printf "  %-28s %7.3fs  %5.1f%%  (%d calls)\n", "compute_mask (C)", $t_compute_mask, $t_compute_mask/$total*100, $n_mask_calls;
printf "  %-28s %7.3fs  %5.1f%%\n", "coalesce + derive + validate", $t_coalesce, $t_coalesce/$total*100;
printf "  %-28s %7.3fs  %5.1f%%  (%s evals)\n", "interleaved re-scan", $t_interleaved_rescan, $t_interleaved_rescan/$total*100, commify($n_rescan_evals);
printf "  %-28s %7.3fs  %5.1f%%\n", "merge check", $t_merge_check, $t_merge_check/$total*100;
printf "  %-28s %7.3fs  %5.1f%%  (%s evals)\n", "merge re-scan", $t_merge_rescan, $t_merge_rescan/$total*100, commify($n_merge_rescan_evals);
printf "  %-28s %7.3fs\n", "TOTAL", $total;
printf "\n  Patterns discovered: %d\n", $n_patterns_discovered;

# Also show: how many regex evals per pattern on average
if ($n_patterns_discovered > 0) {
    printf "  Avg re-scan evals/pattern: %d\n", ($n_rescan_evals + $n_merge_rescan_evals) / $n_patterns_discovered;
}

sub commify { my ($n) = @_; my $t = reverse $n; $t =~ s/(\d{3})(?=\d)/$1,/g; return scalar reverse $t; }
