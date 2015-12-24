# Monitoring-Hive-Service
This is a utility to test for the responsiveness of a service, in this case the service happens to be the hive metastore service.
This utility can be modified to monitor any linux process that has a command line interface and allows one to invoke the 
process using command in a file.

I have used the same utility to test for the responsiveness of HiveServer2 as well.

Hive metastore is known to be a bottleneck in Hadoop. This is 'cause there is only one (two in case of HA) instances of Hive Metastore HMS.
When a command is invoked the metastore is first consulted. In my case the only command being invoked is to change the database 
to be different than the 'default' by the command 'use warehouse;', where 'warehouse' is an existing database.

When multiple hive commands are invoked concurrently, there is a delay is accessing the metastore. If this delay is unacceptable
one may need to restart the service. If HMS is configured as HA you can safely do so without impacting client request.
