use POSIX qw(strftime);
my $ts = strftime('%Y-%m-%d %H:%M', localtime(0));
print "[$ts]\n";
print "Length: ", length($ts), "\n";
