#!/bin/bash

#displays parameter expected by the utility on screen 
usage()
{
cat << EOF
usage: $0 <threshold in seconds>
EOF
}

#function to invoke a shell command and wait for a specified time for it to complete
timeout() {
    #parameter 1 is timeout in seconds
    time=$1
    #parameter 2 is the the command to invoke 
    command="/bin/sh -c \"$2\""
    #spawn a shell using expect, set its environment before invoking the command, exit 1 if the command is still running
    expect -c "set echo \"-noecho\"; set timeout $time; spawn -noecho $command; expect timeout { exit 1 } eof { exit 0 }"    
    if [ $? = 1 ] ; then
	return 1;
    fi
    return 0;
}

#main takes one parameter, it can be modified to take additional parameters like the command to invoke and the password
main() {
    #print how to invoke the utility if not invoked with one parameter
    if [ $# != 1 ] ; then
        usage ; exit 1
    fi
    TIMEOUT_IN_SECONDS=$1
    PWD="password"
    echo "Timeout: $TIMEOUT_IN_SECONDS"

    #hive can be invoked from the command line to use a file containing commands 
    timeout $TIMEOUT_IN_SECONDS "hive -f /apps/scripts/file_containing_command.hive"
    if [ $? = 1 ] ; then
        #prepare to send an email alert to admin
        MAIL_FILE="/tmp/mail_hive_down.txt"
        SUBJECT="ALERT from `hostname` - Connection to Hive metastore timed out."
        EMAIL="administrators_email_address"
        FORMATTED_LINE="Hive metastore is unreachable. Waited $TIMEOUT_IN_SECONDS seconds. Please verify ASAP. "
        echo $FORMATTED_LINE > $MAIL_FILE

        #send email
        mail -E -c "$CC_EMAIL" -s "$SUBJECT" "$EMAIL" < "$MAIL_FILE"
    fi
}
main "$@"
