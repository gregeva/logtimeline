my $params = join(' ', @ARGV);
#system("perl ./ltl /Users/geva/Downloads/bspa003/11mar-14mar/access_logs/localhost_access_log-twx01-twx-thingworx-0.2025-03-11.txt");
system("perl ./ltl $params");
