# Feature Requirements: Custom Metrics - Record Count Statistics

## Branch
`custom-metrics-record-count-stats`

## Overview
<!-- Provide a high-level description of the feature -->
The ltl tool already collects and tallies statistics for a variety of data dimensions such as request duration, total duration, bytes sent, log level sub-totals, distinct number of threads.  This feature adds support for the custom log field called 'count' which includes the number of records or workload contained within the overall request.  Statistics for this count will then allow calculating the sum of all records/work processed within the request, as well as statistics like min/max/average records processed per request/execution.  The features foundation should build upon the multiple graph column support recently implemented, and build a framework and data model which can be added to later to support user specified metrics using the same approach as the 'count' metric.

## Background / Problem Statement
<!-- Describe the problem this feature solves or the need it addresses -->
Each request in the logs allow statistical analysis on number of requests, total duration, and percentile statistics for the request latency.  This does not take into consideration the custom log metric 'count' which indicates the amount of work being done, which is very relevant to know in order to compare to latency.  Present analysis using ltl only looks at occurrences, latency, bytes sent, and does not analyze the records processed (count=X).

## Goals
<!-- List the main goals of this feature -->
- Analysis of logs containing a custom metrics field should be parsed, stored, and have basic statistics (minimum, average, maximum, and sum) calculated and stored in the data model
- When present in the data model, these statistics should be rendered in the additional graph columns if the --include-count or -ic command line option is specified
- When present in the data model, these statistics should be included in the output CSV file if the output to CSV option (-o) has been specified on the command line
- When included in the console output using -ic, these statistics should be printed in the time-bucket graph columns, as well as the overall message based statistics

## Requirements

### Functional Requirements
<!-- List what the feature must do -->
1. Log lines containing RegEx pattern matching / count\s*=\s*(\d+)/ should extract and store the metric in the relevant parts of the data model
2. The statistics calculated for the count metric should be the same ones calculated for the bytes metric
3. The statistics should be included in the output CSV file if they are present and the CSF output is activated
4. Message-based and time bucket based statistics should be calculated and stored in each of those hash data models
5. The value of the 'count' metric in the original message text should be replaced with ? so as to ensure proper message grouping

### Non-Functional Requirements
<!-- List performance, usability, compatibility, etc. requirements -->
- Implementation approach should resemble what is presently used for the metric 'bytes', and be adapted to other user specified metrics capable of being used in combination with 'bytes' and 'count'
- Data model should use legitmate and compatible Perl hash keys

## User Stories
<!-- Describe the feature from the user's perspective -->
- As a Software Developer, I want to be able to analyze processing logs to clearly identify which entities are processing excessive or abnormal amount of records or workload so that debugging efforts can dive into the root cause of expressed symptoms
- As a System Reliability Engineer, I want to be able to identify anomalies in system response and availability by correlating to the workload to gain a better udnerstanding of what the application is executing
- As a Systems Architect, I want to be able to identify load spikes and understand workload balance across time in order to provide targetted recommendations of where developers should focus optimization efforts

## Acceptance Criteria
<!-- Define what "done" looks like -->
- [ ] 'count' metric is read from log message lines and has its value replaced with a generic '?' character
- [ ] Read 'count' metric is integrated into the time-bucket data model with statistics calculated as it is being added (minimum, average, maximum, sum)
- [ ] Read 'count' metric is integrated into the per message data model with statistics calculated as it is being added (minimum, average, maximum, sum)
- [ ] Count statistics are output into the two CSV files if they are activated (time-bucket and messages)
- [ ] Additional graph columns to be printed are populated with the count statistics appropriately so that automatic scaling and column printing occurs within the multi-graph framework

## Technical Considerations
<!-- Any technical notes, dependencies, or implementation considerations -->
- Existing data model and user interface references to count will need to be revised to refer to occurrences more generically so as to not conflict with this features purpose and use

## Out of Scope
<!-- What is explicitly not included in this feature -->
- Initially, all of the statistics will be printed to the consol with no means to specifiy only certain statistics

## Testing Requirements
<!-- What testing is needed -->
- 
- 

## Documentation Requirements
<!-- What documentation needs to be updated -->
- 
- 

## Notes
<!-- Any additional notes or considerations -->

