# Monitoring-Hive-Service
This utility tests the responsiveness of a service-in this case, the Hive Metastore (HMS). It can be modified to monitor any Linux process that provides a command-line interface and supports batch command execution from a file. (I have also used it to test HiveServer2 responsiveness.)

The Hive Metastore is a well-known bottleneck in Hadoop ecosystems because environments typically rely on only one or two HMS instances for High Availability. Since nearly every Hive command consults the metastore first, concurrent requests can cause significant latency.

To measure this delay, the utility concurrently executes a lightweight command, such as USE warehouse;, to switch away from the default database. If the response latency exceeds an acceptable threshold, restarting HMS may be necessary. In an HA configuration, this restart can be performed safely without dropping client requests.
