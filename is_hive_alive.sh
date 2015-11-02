#/bin/bash
usage()
{
cat << EOF
usage: $0 <threshold in seconds>
EOF
}
timeout() {

    time=$1
    command="/bin/sh -c \"$2\""
    expect -c "set echo \"-noecho\"; set timeout $time; spawn -noecho $command; expect timeout { exit 1 } eof { exit 0 }"    
    if [ $? = 1 ] ; then
        echo "Timeout after ${time} seconds"
	return 1;
    fi
    return 0;
}
main() {
    if [ $# != 1 ] ; then
        usage ; exit 1
    fi
    TIMEOUT_IN_SECONDS=$1
    PWD="cA?2KjOg01dS"
    echo "Timeout: $TIMEOUT_IN_SECONDS"
    timeout $TIMEOUT_IN_SECONDS "hive -f /apps/scripts/use_warehouse.hive"
    if [ $? = 1 ] ; then
        MAIL_FILE="/tmp/mail_hive_down.txt"
        SUBJECT="ALERT from `hostname` - Connection to Hive metastore timed out."
        CC_EMAIL="manprasa@adobe.com"
        #EMAIL="noc@adobe.com"
        EMAIL="IT-Hadoop-Support@adobe.com"
        #STATUS=`curl -u admin:$PWD 'http://sj1dra010.corp.adobe.com:7180/api/v1/clusters/SJ-HDP01/services/hive2' | python -mjson.tool | grep serviceState | sed 's/.*serviceState\"\: \"\(.*\)\"\,.*/\1/'`
        #FORMATTED_LINE="Current status of the service as per CM API:[${STATUS}]"
        #echo $FORMATTED_LINE
        #echo $FORMATTED_LINE > $MAIL_FILE
        #FORMATTED_LINE="Hive metastore is unreachable. Waited $TIMEOUT_IN_SECONDS seconds. The service should have been automtically restarted. Please verify ASAP. "
        FORMATTED_LINE="Hive metastore is unreachable. Waited $TIMEOUT_IN_SECONDS seconds. Please verify ASAP. "
        echo $FORMATTED_LINE
        echo $FORMATTED_LINE > $MAIL_FILE

        mail -E -c "$CC_EMAIL" -s "$SUBJECT" "$EMAIL" < "$MAIL_FILE"
    fi
}
main "$@"
