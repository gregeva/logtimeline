
# Slow API performance due to heavy GC

Situation is a very large call to GetLogEntries where large amount of logs saturate the memory as they are read and prepared to return to the user.
This should manifest in a number of different ways, but if I combine plot ApplicationLog OR ScriptLog, gc logs, and access logs together, I ought to be able to:

1) See the increased in GC events and duration (see messages for total GC time)
2) See the API latency increasing as possibly more and more calls are queued (GetLogEntries)
3) Get an idea of the number of Log messages per minute captured which is impacting this performance

# Explore application changes over time

ThingWorx ConfigurationLogs store entries where entities are changed.  These we can search for and filter 'in' between the ConfigurationLog and the access log.
Viewing the latency figures from the access log for the events matching our target pattern we'll get an idea of latency over time as well as any failures.
Combining in SyncLog messages from ApplicationLog searching for Entities would complete the picture in a HA environment about their ability to sync.

- include pattern would need to have various options to match patterns in each log type that we are targetting
- highlight pattern can then be applied on ConfigurationLog or SyncLog to visualize the number of entity changes across time

# Check for Mashup Websocket Reconnection Loop

Until a certain version, the Mashup JavaScript websocket client misbehaves in its reconnection attempts should the connection become severed.  Let's look in the logs for this scenario.

- include access logs targetting /Thingworx/WS URI
- include Security log targetting "Nonce key not found" indicating use of an unfound appKey
- include ScriptLog/Application log targetting the persistent session name with user associated

# Extremely Forward Looking - Event Performance Analysis

Inspired from a Confluence page I found using a Splunk search to get percentile measures for event processing performance.
https://thingworx.jira.com/wiki/spaces/IIoTP/pages/4400316501/Event+Performance+Analysis+Using+Splunk

| rex field=_raw "(?<event_type>Ordered|Unordered).*?\s(?<action_type>pushed|consumed)\s(?:to|from)\s(?<queue_type>durable queue|internal queue).*?eventBatchId:\s(?<eventBatchId>\S+),.*?timestamp: (?<timestamp>\S+)(?<!\,)" 
| where action_type="pushed" OR action_type="consumed" 
| transaction eventBatchId startswith="action_type=pushed" endswith="action_type=consumed"  
| stats min(timestamp) AS pushed_time max(timestamp) AS consumed_time BY eventBatchId
| eval duration=consumed_time - pushed_time | stats avg(duration) AS avg_time 
        min(duration) AS min_time 
        max(duration) AS max_time 
        p99(duration) AS p99_time 
        p90(duration) AS p90_time

I'll need to investigate the source of these logs, and if I could adapt ltl in order to process this as well as this could be quite handy.  Noting that this use case requires matching up various log entries and so would be quite challenging given the current software architecture and data model of ltl. 



# Comparison of Performance and Load across Multiple Files

A scenario that presented recently which the tool doesn't really have a way to surface is when you are dealing with a cluster and would have multiple access log files from the various pods/nodes.  You can process them all together which is really nice, but this is going to mush together their differences which would have otherwise been apparent if you had been looking at them seperately (ie; one node is much slower than the rest).

To accomplish this, you need to leverage time instead of file, where you'd pick a different days file from each node, so that they'd come one after the other in the output.  The overall minimums and maximums would give you the comparative range, and using the heatmap would show visually their load and performance compared to each other.  Using --omit-empty would ensure empty time windows are not printed to get things close together on the screen, and this would also allow chosing days far from each other.

The idea of chosing days from from each other also introduces a technique to compare load and performance from one period to another on a specific system.  Simply providing multiple files from the early time, and the later time, enabling omit-empty, activating heatmap should then do this for you.  If you want statistics calculated for external analysis or simply saving the results you'll have to turn off heatmap.
