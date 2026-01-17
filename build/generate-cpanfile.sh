#!/bin/bash
#
# generate-cpanfile.sh : scan a Perl script for package dependencies, and build a CPAN file with those packages for easier project dependency management
#
# take target script name from ENV_VAR otherwise assume it is ltl
SCRIPT_NAME=${1:-ltl}

# Generate CPAN file containing dependencies
perl -ne '
    if (/^\s*(?:use|require)\s+([A-Za-z0-9_:]+)(?:\s+([\d\._]+))?/) {
        my ($m,$ver) = ($1,$2);
        next if $m =~ /^(?:strict|warnings|feature|utf8|open|mro|base|parent|lib|constant|vars|attributes?|diagnostics|subs)$/;
        next if $m eq "perl";
        print "requires \x27$m\x27", ($ver ? ", \x27>= $ver\x27" : ""), ";\n";
    } 
' ${SCRIPT_NAME} | sort -u | tee cpanfile
