print "FILE=", __FILE__, "\nPAR_0=", ($ENV{PAR_0}//'undef'), "\n";
if (defined $ENV{PAR_0}) { open my $f, '<', $ENV{PAR_0} or die; for (1..4) { my $l = <$f>; print "  $_: $l" } }
