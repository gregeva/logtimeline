#!/usr/bin/env perl
# The light-background evaluation of the framework: review.pl's light round,
# to be run from a terminal with a light profile. Takes review.pl's options
# (--list, --from, --only, --all).
#
#   perl light-review.pl

use strict;
use warnings;
use FindBin;
exec $^X, "$FindBin::Bin/review.pl", '--round', 'light', @ARGV or die "cannot run review.pl: $!\n";
