# Tools

These scripts and other resources are built to speed and facilitate debugging, diagnostics, and likely other things.

## slt : Simple Log Timeline

Have you ever wished that you could quickly identify areas of interest or hotspots in very large log files so that you could navigate there directly?  That's what this timeline view is for!!

When dealing with logs which have a very large amount of lines/errors/whatever, it can be quite hard to get an overall view of the file while looking at a screen full of lines representing maybe less than a second.


## cleanlogs : removes unwanted lines and partial lines to faciliate analysis

Partial lines where one node or thread have written over another log appender make programmatic analysis of logs quite challenging.  Similarly useless things like when there is a multi-line output like a thread dump or nuissance aspects like 100's of thousands of health probes.

Clean logs takes care of some of these scenarios, outputting a "clean" version of one or many log files.


## twxsummarize : ThingWorx Log Summary tool

Similar to the above, this tool is not time-based, but instead groups and summarizes ThingWorx log lines using the common log pattern from Logback.  This helps to answer questions like if certain subsystems are starting to have errors all of a sudden, or if errors present where your diagnostic efforts should focus.



In a future release I'll add other capabilities like a message grouping view.

