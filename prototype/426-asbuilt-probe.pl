# 426-asbuilt-probe.pl — injected into a throwaway copy of ltl immediately
# before `calculate_all_statistics();` (see 426-asbuilt-run.sh), so it runs
# against %log_messages exactly as the production read loop laid it out on
# the heap. It answers Q1 of features/426-per-message-statistics-store.md:
# does a columnar store realise the L2 traversal gain on the real as-built
# data, or does L2 measure something (fresh contiguous hashes) that a
# struct-of-arrays layout does not reproduce?
#
# Levels, each measured with the three traversal shapes of the statistics
# phase (lookup = comparator-shaped keyed loop; walk = population walk;
# sort = two-stage fill-block selection with the key tiebreaker):
#   L0   the hash as built
#   L2   the same entries rebuilt into fresh memory (the #415 ladder level)
#   D    columnar: message->ordinal hash + occurrences column + ordinal->key
#        column, converted from L0 in place (conversion cost reported
#        separately — it is a migration cost, not the production write path)
#
# Emits `### 426 <level> <metric> <median> <min> <max>` lines on stderr,
# then lets ltl continue so its own -V benchmark-data rows land in the same
# capture for cross-validation.
{
    require Time::HiRes;
    require Devel::Size;
    require List::Util;
    my $RUNS = 5;
    my $tm = sub {                       # (coderef) -> (median, min, max) over $RUNS timed runs after one warmup
        my ($code) = @_;
        $code->();
        my @s;
        for (1 .. $RUNS) { my $t0 = Time::HiRes::time(); $code->(); push @s, Time::HiRes::time() - $t0 }
        @s = sort { $a <=> $b } @s;
        return ($s[$#s >> 1], $s[0], $s[-1]);
    };
    my $emit = sub { my ($level, $metric, @v) = @_; printf STDERR "### 426 %-4s %-22s %.6g %.6g %.6g\n", $level, $metric, @v };

    my ($cat) = sort { keys(%{$log_messages{$b}}) <=> keys(%{$log_messages{$a}}) } keys %log_messages;
    my $h  = $log_messages{$cat};
    my @ks = keys %$h;
    my $n  = scalar @ks;
    printf STDERR "### 426 category=%s keys=%d top_n=%d sort_ascending=%d\n", $cat, $n, $top_n_messages, $sort_ascending;

    # --- hash-shaped traversals (verbatim shapes from calculate_all_statistics) ---
    my $lookup_h = sub { my ($hh) = @_; my $s = 0; for my $k (@ks) { $s += $hh->{$k}{occurrences} // 0 } $s };
    my $walk_h = sub {
        my ($hh) = @_;
        my @fill_block;
        foreach my $log_key (keys %$hh) {
            my $entry = $hh->{$log_key};
            my $nn = $message_stats_capture_mode eq 'bin'
                ? ($entry->{duration_count} // 0)
                : scalar @{ $entry->{durations} // [] };
            if (!$message_duration_stats_demand || $nn < 1 || !defined $entry->{occurrences}) {
                push @fill_block, $log_key;
                next;
            }
        }
        return \@fill_block;
    };
    my $sort_h = sub {
        my ($hh, $fill_block) = @_;
        my @by_occ = sort {
            my $occurrences_a = $hh->{$a}{occurrences} // 0;
            my $occurrences_b = $hh->{$b}{occurrences} // 0;
            $sort_ascending
                ? ($occurrences_a <=> $occurrences_b)
                : ($occurrences_b <=> $occurrences_a);
        } @$fill_block;
        my $cut = List::Util::min($#by_occ, $top_n_messages - 1);
        my $cut_val = $hh->{$by_occ[$cut]}{occurrences} // 0;
        my $pool_end = $cut;
        $pool_end++ while $pool_end < $#by_occ
            && (($hh->{$by_occ[$pool_end + 1]}{occurrences} // 0) == $cut_val);
        my @occ_pool = @by_occ[0 .. $pool_end];
        my @fill_sorted = sort {
            my $occurrences_a = $hh->{$a}{occurrences} // 0;
            my $occurrences_b = $hh->{$b}{occurrences} // 0;
            ($sort_ascending
                ? ($occurrences_a <=> $occurrences_b)
                : ($occurrences_b <=> $occurrences_a))
            || ($a cmp $b);
        } @occ_pool;
        return [ @fill_sorted[0 .. List::Util::min($#fill_sorted, $top_n_messages - 1)] ];
    };

    # --- L0: as built ---
    my $fill0 = $walk_h->($h);
    $emit->('L0', 'lookup_s', $tm->(sub { $lookup_h->($h) }));
    $emit->('L0', 'walk_s',   $tm->(sub { $walk_h->($h) }));
    $emit->('L0', 'sort_s',   $tm->(sub { $sort_h->($h, $fill0) }));
    $emit->('L0', 'devel_size_bytes', (Devel::Size::total_size($h)) x 3);
    my $top0 = $sort_h->($h, $fill0);

    # --- L2: entries rebuilt into fresh memory ---
    my %f2 = map { $_ => { %{ $h->{$_} } } } @ks;
    my $fill2 = $walk_h->(\%f2);
    $emit->('L2', 'lookup_s', $tm->(sub { $lookup_h->(\%f2) }));
    $emit->('L2', 'walk_s',   $tm->(sub { $walk_h->(\%f2) }));
    $emit->('L2', 'sort_s',   $tm->(sub { $sort_h->(\%f2, $fill2) }));
    my $top2 = $sort_h->(\%f2, $fill2);
    undef %f2;

    # --- D: columnar, converted from the as-built hash ---
    my (%ord, @occ, @key);
    my ($conv_med, $conv_min, $conv_max) = $tm->(sub {
        %ord = (); @occ = (); @key = ();
        my $i = 0;
        while (my ($k, $e) = each %$h) { $ord{$k} = $i; $occ[$i] = $e->{occurrences}; $i++ }
        while (my ($k, $i2) = each %ord) { $key[$i2] = $k }
    });
    $emit->('D', 'convert_s', $conv_med, $conv_min, $conv_max);
    my $lookup_d = sub { my $s = 0; for my $k (@ks) { $s += $occ[ $ord{$k} ] // 0 } $s };
    my $walk_d = sub {
        my @fill_block;
        for my $i (0 .. $#occ) {
            my $o = $occ[$i];
            next unless defined $o;
            my $nn = 0;                                   # no durations column on this construct
            if (!$message_duration_stats_demand || $nn < 1) { push @fill_block, $i; next }
        }
        return \@fill_block;
    };
    my $sort_d = sub {
        my ($ids) = @_;
        my @by_metric = sort {
            $sort_ascending ? ($occ[$a] <=> $occ[$b]) : ($occ[$b] <=> $occ[$a])
        } @$ids;
        my $cut = List::Util::min($#by_metric, $top_n_messages - 1);
        my $cut_val = $occ[$by_metric[$cut]];
        my $pool_end = $cut;
        $pool_end++ while $pool_end < $#by_metric && $occ[$by_metric[$pool_end + 1]] == $cut_val;
        my @pool = @by_metric[0 .. $pool_end];
        my @sorted = sort {
            ($sort_ascending ? ($occ[$a] <=> $occ[$b]) : ($occ[$b] <=> $occ[$a]))
            || ($key[$a] cmp $key[$b]);
        } @pool;
        return [ map { $key[$_] } @sorted[0 .. List::Util::min($#sorted, $top_n_messages - 1)] ];
    };
    my $filld = $walk_d->();
    $emit->('D', 'lookup_s', $tm->($lookup_d));
    $emit->('D', 'walk_s',   $tm->($walk_d));
    $emit->('D', 'sort_s',   $tm->(sub { $sort_d->($filld) }));
    $emit->('D', 'devel_size_bytes', (Devel::Size::total_size(\%ord) + Devel::Size::total_size(\@occ) + Devel::Size::total_size(\@key)) x 3);
    $emit->('D', 'devel_size_key_col',  (Devel::Size::total_size(\@key)) x 3);
    my $topd = $sort_d->($filld);

    my $same = (join("\n", @$top0) eq join("\n", @$top2) && join("\n", @$top0) eq join("\n", @$topd)) ? 'OK' : 'DIVERGED';
    printf STDERR "### 426 parity top-%d L0/L2/D: %s (fill L0=%d L2=%d D=%d)\n", $top_n_messages, $same, scalar @$fill0, scalar @$fill2, scalar @$filld;
}
